#!/usr/bin/env python3
"""
Load testing for the Vote Service using Locust

This script simulates multiple users voting concurrently to test:
- Vote service performance under load
- Redis queue handling capacity
- Error rates and response times
- System behavior under stress

Usage:
    # Install dependencies
    pip install -r requirements.txt
    
    # Run with Locust web UI
    locust -f vote_load_test.py --host=http://localhost:5000
    
    # Run headless (CLI)
    locust -f vote_load_test.py --host=http://localhost:5000 \
           --users 50 --spawn-rate 5 --run-time 2m --headless
"""

import random
import time
from locust import HttpUser, task, between
import json


class VoteUser(HttpUser):
    """Simulates a user voting on the system"""
    
    # Wait between 1-3 seconds between requests
    wait_time = between(1, 3)
    
    def on_start(self):
        """Called when a user starts"""
        # Check if the service is healthy before starting
        with self.client.get("/health", catch_response=True) as response:
            if response.status_code == 200:
                response.success()
            else:
                response.failure(f"Health check failed: {response.status_code}")
    
    @task(10)
    def vote_cats(self):
        """Vote for cats (weighted to occur more frequently)"""
        self._cast_vote("cats")
    
    @task(8)
    def vote_dogs(self):
        """Vote for dogs"""
        self._cast_vote("dogs")
    
    @task(1)
    def check_health(self):
        """Occasionally check service health"""
        with self.client.get("/health", catch_response=True) as response:
            if response.status_code == 200:
                data = response.json()
                if data.get("status") == "healthy":
                    response.success()
                else:
                    response.failure(f"Service unhealthy: {data}")
            else:
                response.failure(f"Health check failed: {response.status_code}")
    
    @task(1)
    def check_metrics(self):
        """Occasionally check metrics endpoint"""
        with self.client.get("/metrics", catch_response=True) as response:
            if response.status_code == 200:
                # Just check that we get some content
                if len(response.text) > 0:
                    response.success()
                else:
                    response.failure("Empty metrics response")
            else:
                response.failure(f"Metrics check failed: {response.status_code}")
    
    @task(2)
    def visit_homepage(self):
        """Visit the voting homepage"""
        with self.client.get("/", catch_response=True) as response:
            if response.status_code == 200:
                if "Voting App" in response.text:
                    response.success()
                else:
                    response.failure("Homepage content invalid")
            else:
                response.failure(f"Homepage failed: {response.status_code}")
    
    def _cast_vote(self, choice):
        """Helper method to cast a vote"""
        vote_data = {"vote": choice}
        
        with self.client.post(
            "/vote",
            json=vote_data,
            headers={"Content-Type": "application/json"},
            catch_response=True
        ) as response:
            if response.status_code == 200:
                try:
                    data = response.json()
                    if data.get("status") == "success" and data.get("vote") == choice:
                        response.success()
                    else:
                        response.failure(f"Vote response invalid: {data}")
                except json.JSONDecodeError:
                    response.failure("Invalid JSON response")
            elif response.status_code == 400:
                # Log bad request but don't fail the test (might be expected)
                response.failure(f"Bad request: {response.text}")
            elif response.status_code == 503:
                # Service unavailable (Redis down)
                response.failure("Service unavailable - Redis connection issue")
            else:
                response.failure(f"Unexpected status: {response.status_code}")


class HighVolumeVoteUser(HttpUser):
    """Simulates a high-volume user with faster voting"""
    
    wait_time = between(0.1, 0.5)  # Much faster voting
    
    def on_start(self):
        """Called when a user starts"""
        # Check if the service is healthy before starting
        response = self.client.get("/health")
        if response.status_code != 200:
            print(f"Warning: Service health check failed: {response.status_code}")
    
    @task
    def rapid_vote(self):
        """Rapidly cast votes"""
        choice = random.choice(["cats", "dogs"])
        vote_data = {"vote": choice}
        
        self.client.post(
            "/vote",
            json=vote_data,
            headers={"Content-Type": "application/json"}
        )


class InvalidDataUser(HttpUser):
    """Simulates users sending invalid data to test error handling"""
    
    wait_time = between(2, 5)
    
    @task(1)
    def invalid_vote_choice(self):
        """Send invalid vote choices"""
        invalid_choices = ["fish", "birds", "hamsters", "", None, 123]
        choice = random.choice(invalid_choices)
        vote_data = {"vote": choice}
        
        with self.client.post(
            "/vote",
            json=vote_data,
            headers={"Content-Type": "application/json"},
            catch_response=True
        ) as response:
            # We expect these to fail with 400 status
            if response.status_code == 400:
                response.success()
            else:
                response.failure(f"Expected 400, got {response.status_code}")
    
    @task(1)
    def malformed_request(self):
        """Send malformed JSON"""
        malformed_data = [
            '{"vote": "cats"',  # Missing closing brace
            '{"invalid": "data"}',  # Missing vote key
            '',  # Empty body
            'not json at all',  # Invalid JSON
        ]
        
        data = random.choice(malformed_data)
        
        with self.client.post(
            "/vote",
            data=data,
            headers={"Content-Type": "application/json"},
            catch_response=True
        ) as response:
            # We expect these to fail with 400 status
            if response.status_code == 400:
                response.success()
            else:
                response.failure(f"Expected 400, got {response.status_code}")
    
    @task(1)
    def wrong_content_type(self):
        """Send request with wrong content type"""
        vote_data = {"vote": "cats"}
        
        with self.client.post(
            "/vote",
            json=vote_data,
            headers={"Content-Type": "text/plain"},  # Wrong content type
            catch_response=True
        ) as response:
            # This might work or fail depending on implementation
            if response.status_code in [200, 400, 415]:
                response.success()
            else:
                response.failure(f"Unexpected status: {response.status_code}")


# Load test configurations for different scenarios
class LightLoadTest(VoteUser):
    """Light load test - simulates normal usage"""
    weight = 10
    wait_time = between(2, 5)


class MediumLoadTest(VoteUser):
    """Medium load test - simulates moderate traffic"""
    weight = 5
    wait_time = between(1, 3)


class HeavyLoadTest(HighVolumeVoteUser):
    """Heavy load test - simulates peak traffic"""
    weight = 2
    wait_time = between(0.1, 1)


class StressTest(HighVolumeVoteUser):
    """Stress test - pushes the system to its limits"""
    weight = 1
    wait_time = between(0.05, 0.2)


if __name__ == "__main__":
    # This allows running the script directly for testing
    import subprocess
    import sys
    
    print("Vote Service Load Test")
    print("=====================")
    print()
    print("Available test modes:")
    print("1. Light load (normal usage)")
    print("2. Medium load (moderate traffic)")
    print("3. Heavy load (peak traffic)")
    print("4. Stress test (system limits)")
    print("5. Error handling test")
    print()
    
    mode = input("Select test mode (1-5): ").strip()
    
    base_cmd = [
        "locust",
        "-f", __file__,
        "--host", "http://localhost:5000",
        "--headless",
        "--csv", "load_test_results"
    ]
    
    if mode == "1":
        cmd = base_cmd + ["--users", "10", "--spawn-rate", "2", "--run-time", "2m"]
    elif mode == "2":
        cmd = base_cmd + ["--users", "25", "--spawn-rate", "5", "--run-time", "3m"]
    elif mode == "3":
        cmd = base_cmd + ["--users", "50", "--spawn-rate", "10", "--run-time", "5m"]
    elif mode == "4":
        cmd = base_cmd + ["--users", "100", "--spawn-rate", "20", "--run-time", "5m"]
    elif mode == "5":
        # Focus on error handling
        cmd = [
            "locust",
            "-f", __file__,
            "--host", "http://localhost:5000",
            "--headless",
            "--users", "20",
            "--spawn-rate", "5",
            "--run-time", "2m",
            "--csv", "error_test_results"
        ]
        # Override user class to focus on InvalidDataUser
        print("Running error handling tests...")
    else:
        print("Invalid selection. Exiting.")
        sys.exit(1)
    
    print(f"Running: {' '.join(cmd)}")
    subprocess.run(cmd)
