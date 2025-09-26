import pytest
import requests
import json
import time
import os
import tempfile
import threading
from testcontainers.redis import RedisContainer
from testcontainers.compose import DockerCompose
import redis

# Import the Flask app
import sys
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from app import app, get_redis_client


class TestVoteService:
    """Test suite for the vote service using testcontainers"""
    
    @pytest.fixture(scope="class")
    def redis_container(self):
        """Start Redis container for testing"""
        with RedisContainer() as redis:
            redis_host = redis.get_container_host_ip()
            redis_port = redis.get_exposed_port(6379)
            
            # Set environment variables for the app
            os.environ['REDIS_HOST'] = redis_host
            os.environ['REDIS_PORT'] = str(redis_port)
            os.environ['REDIS_DB'] = '0'
            
            yield redis_host, redis_port
    
    @pytest.fixture(scope="class")
    def vote_app(self, redis_container):
        """Start the vote application for testing"""
        app.config['TESTING'] = True
        app.config['WTF_CSRF_ENABLED'] = False
        
        # Start the app in a separate thread
        server_thread = threading.Thread(
            target=lambda: app.run(host='0.0.0.0', port=5001, debug=False)
        )
        server_thread.daemon = True
        server_thread.start()
        
        # Wait for the server to start
        time.sleep(2)
        
        yield "http://localhost:5001"
    
    @pytest.fixture
    def redis_client(self, redis_container):
        """Redis client for direct testing"""
        redis_host, redis_port = redis_container
        client = redis.Redis(host=redis_host, port=redis_port, db=0)
        yield client
        # Clean up after each test
        client.flushdb()
    
    def test_health_endpoint_healthy(self, vote_app, redis_client):
        """Test health endpoint when Redis is available"""
        response = requests.get(f"{vote_app}/health")
        
        assert response.status_code == 200
        data = response.json()
        assert data['status'] == 'healthy'
        assert data['service'] == 'vote'
        assert data['redis'] == 'connected'
        assert 'timestamp' in data
    
    def test_health_endpoint_unhealthy(self):
        """Test health endpoint when Redis is unavailable"""
        # Set invalid Redis configuration
        os.environ['REDIS_HOST'] = 'invalid-host'
        os.environ['REDIS_PORT'] = '9999'
        
        app.config['TESTING'] = True
        with app.test_client() as client:
            response = client.get('/health')
            
            assert response.status_code == 503
            data = response.json()
            assert data['status'] == 'unhealthy'
            assert data['service'] == 'vote'
    
    def test_index_page(self, vote_app):
        """Test that the index page loads"""
        response = requests.get(vote_app)
        
        assert response.status_code == 200
        assert 'text/html' in response.headers['Content-Type']
        assert 'Voting App' in response.text
    
    def test_vote_cats_valid(self, vote_app, redis_client):
        """Test valid vote submission for cats"""
        vote_data = {'vote': 'cats'}
        
        response = requests.post(
            f"{vote_app}/vote",
            json=vote_data,
            headers={'Content-Type': 'application/json'}
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data['status'] == 'success'
        assert data['vote'] == 'cats'
        assert 'Thank you for voting for cats!' in data['message']
        
        # Verify vote was stored in Redis
        votes_in_redis = redis_client.llen('votes')
        assert votes_in_redis > 0
        
        # Check the vote data
        vote_data_str = redis_client.rpop('votes')
        stored_vote = json.loads(vote_data_str)
        assert stored_vote['vote'] == 'cats'
        assert 'timestamp' in stored_vote
        assert 'voter_id' in stored_vote
    
    def test_vote_dogs_valid(self, vote_app, redis_client):
        """Test valid vote submission for dogs"""
        vote_data = {'vote': 'dogs'}
        
        response = requests.post(
            f"{vote_app}/vote",
            json=vote_data,
            headers={'Content-Type': 'application/json'}
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data['status'] == 'success'
        assert data['vote'] == 'dogs'
        assert 'Thank you for voting for dogs!' in data['message']
        
        # Verify vote was stored in Redis
        votes_in_redis = redis_client.llen('votes')
        assert votes_in_redis > 0
    
    def test_vote_invalid_choice(self, vote_app):
        """Test vote submission with invalid choice"""
        vote_data = {'vote': 'fish'}
        
        response = requests.post(
            f"{vote_app}/vote",
            json=vote_data,
            headers={'Content-Type': 'application/json'}
        )
        
        assert response.status_code == 400
        data = response.json()
        assert 'error' in data
        assert 'Invalid choice' in data['error']
    
    def test_vote_missing_data(self, vote_app):
        """Test vote submission with missing data"""
        response = requests.post(
            f"{vote_app}/vote",
            json={},
            headers={'Content-Type': 'application/json'}
        )
        
        assert response.status_code == 400
        data = response.json()
        assert 'error' in data
        assert 'Invalid vote data' in data['error']
    
    def test_vote_case_insensitive(self, vote_app, redis_client):
        """Test that vote choices are case insensitive"""
        vote_data = {'vote': 'CATS'}
        
        response = requests.post(
            f"{vote_app}/vote",
            json=vote_data,
            headers={'Content-Type': 'application/json'}
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data['vote'] == 'cats'  # Should be normalized to lowercase
    
    def test_multiple_votes(self, vote_app, redis_client):
        """Test multiple vote submissions"""
        votes = [
            {'vote': 'cats'},
            {'vote': 'dogs'},
            {'vote': 'cats'},
        ]
        
        for vote_data in votes:
            response = requests.post(
                f"{vote_app}/vote",
                json=vote_data,
                headers={'Content-Type': 'application/json'}
            )
            assert response.status_code == 200
        
        # Verify all votes were stored
        votes_in_redis = redis_client.llen('votes')
        assert votes_in_redis == 3
    
    def test_metrics_endpoint(self, vote_app):
        """Test that metrics endpoint is accessible"""
        response = requests.get(f"{vote_app}/metrics")
        
        assert response.status_code == 200
        assert 'text/plain' in response.headers['Content-Type']
        assert 'votes_total' in response.text
        assert 'request_duration_seconds' in response.text
    
    def test_404_endpoint(self, vote_app):
        """Test 404 handling"""
        response = requests.get(f"{vote_app}/nonexistent")
        
        assert response.status_code == 404
        data = response.json()
        assert 'error' in data
        assert data['error'] == 'Not found'


class TestVoteServiceUnit:
    """Unit tests for vote service components"""
    
    def test_app_configuration(self):
        """Test app configuration"""
        app.config['TESTING'] = True
        assert app.config['TESTING'] is True
    
    def test_redis_connection_failure_handling(self):
        """Test Redis connection failure handling"""
        # Set invalid Redis configuration
        original_host = os.environ.get('REDIS_HOST', 'localhost')
        original_port = os.environ.get('REDIS_PORT', '6379')
        
        os.environ['REDIS_HOST'] = 'invalid-host'
        os.environ['REDIS_PORT'] = '9999'
        
        try:
            client = get_redis_client()
            assert client is None
        finally:
            # Restore original configuration
            os.environ['REDIS_HOST'] = original_host
            os.environ['REDIS_PORT'] = original_port


if __name__ == '__main__':
    pytest.main([__file__, '-v'])
