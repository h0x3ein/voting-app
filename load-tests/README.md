# Load Testing Suite for Voting Application

This directory contains comprehensive load testing tools for the distributed voting application, designed to help students understand performance testing, identify bottlenecks, and validate system scalability.

## 🎯 Overview

The load testing suite includes:
- **Vote Service Load Tests**: HTTP load testing using Locust
- **Worker Service Load Tests**: Queue processing performance testing
- **End-to-End Tests**: Complete system load testing
- **Error Handling Tests**: Fault tolerance validation
- **Performance Monitoring**: Real-time metrics collection

## 📋 Prerequisites

### Required Software
```bash
# Python 3.8+ with pip (Python 3.13+ supported)
python3 --version

# Go 1.21+ (for worker load tests)
go version

# Running voting services
# Vote service on http://localhost:5000
# Worker service on http://localhost:8080  
# Result service on http://localhost:3000
```

### Python 3.13+ Compatibility
This load testing suite is fully compatible with Python 3.13+. The setup process automatically handles version-specific dependency requirements and build tools.

### Install Dependencies

#### Option 1: Automated Setup (Recommended)
```bash
# Run the setup script
./setup.sh
```

#### Option 2: Manual Setup
```bash
# Create and activate Python virtual environment
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install Python dependencies for Locust
pip3 install -r requirements.txt

# Go dependencies (automatically downloaded)
go mod download
```

## 🚀 Quick Start

### 1. Automated Load Testing
```bash
# Ensure virtual environment is activated
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Run the interactive load testing suite
./run_load_tests.sh
```

### 2. Manual Load Testing

#### Vote Service Load Test
```bash
# Ensure virtual environment is activated
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Basic load test
locust -f vote_load_test.py --host=http://localhost:5000

# Headless load test
locust -f vote_load_test.py \
       --host=http://localhost:5000 \
       --users=50 \
       --spawn-rate=5 \
       --run-time=2m \
       --headless
```

#### Worker Service Load Test
```bash
# Basic worker load test
go run worker_load_test.go

# Custom parameters
go run worker_load_test.go \
    -votes=1000 \
    -workers=10 \
    -duration=2m
```

## 📊 Test Scenarios

### Light Load Test
- **Purpose**: Normal usage simulation
- **Parameters**: 10 users, 2-minute duration
- **Expected**: Baseline performance metrics

### Medium Load Test
- **Purpose**: Moderate traffic simulation
- **Parameters**: 25 users, 3-minute duration
- **Expected**: Stable performance under normal load

### Heavy Load Test
- **Purpose**: Peak traffic simulation
- **Parameters**: 50 users, 5-minute duration
- **Expected**: Performance degradation analysis

### Stress Test
- **Purpose**: System limit identification
- **Parameters**: 100 users, 5-minute duration
- **Expected**: Breaking point identification

### Endurance Test
- **Purpose**: Long-term stability validation
- **Parameters**: 30 users, 15-minute duration
- **Expected**: Memory leak and stability issues

## 🔧 Configuration

### Test Configuration (`config.yaml`)
```yaml
scenarios:
  heavy_load:
    vote_service:
      users: 50
      spawn_rate: 10
      duration: "5m"
    worker_service:
      votes: 3000
      workers: 15
      duration: "5m"
```

### Performance Thresholds
```yaml
thresholds:
  vote_service:
    response_time_p95: 500  # milliseconds
    error_rate: 1.0         # percent
  worker_service:
    processing_rate_min: 100 # votes per second
    queue_depth_max: 1000    # maximum queue length
```

## 📈 Metrics and Monitoring

### Vote Service Metrics
- **Response Time**: P50, P95, P99 percentiles
- **Throughput**: Requests per second
- **Error Rate**: Failed requests percentage
- **Resource Usage**: CPU, memory, network

### Worker Service Metrics
- **Processing Rate**: Votes processed per second
- **Queue Depth**: Redis queue length over time
- **Database Performance**: Insert rate and latency
- **Resource Usage**: CPU, memory, Go runtime stats

### System Metrics
- **Redis Performance**: Queue operations, memory usage
- **MySQL Performance**: Connection pool, query times
- **Network**: Latency, packet loss, throughput

## 📊 Test Types

### 1. Functional Load Tests
```python
# vote_load_test.py
class VoteUser(HttpUser):
    @task(10)
    def vote_cats(self):
        self._cast_vote("cats")
    
    @task(8) 
    def vote_dogs(self):
        self._cast_vote("dogs")
```

### 2. Error Handling Tests
```python
class InvalidDataUser(HttpUser):
    @task
    def invalid_vote_choice(self):
        # Test with invalid vote options
        invalid_choices = ["fish", "birds", ""]
        choice = random.choice(invalid_choices)
        self._cast_vote(choice)
```

### 3. High-Volume Tests
```python
class HighVolumeVoteUser(HttpUser):
    wait_time = between(0.1, 0.5)  # Rapid voting
    
    @task
    def rapid_vote(self):
        choice = random.choice(["cats", "dogs"])
        self._cast_vote(choice)
```

### 4. Worker Performance Tests
```go
// worker_load_test.go
func (lt *LoadTester) generateVotes(workerID int) {
    for {
        vote := Vote{
            Vote:      choices[rand.Intn(len(choices))],
            VoterID:   fmt.Sprintf("load-test-%d", workerID),
            Timestamp: time.Now().Format("2006-01-02T15:04:05.999999"),
        }
        // Push to Redis queue
        lt.redis.LPush(lt.ctx, lt.config.QueueName, voteJSON)
    }
}
```

## 📋 Test Results

### HTML Reports
- Generated automatically by Locust
- Include response time distributions
- Show request/failure statistics
- Display performance charts

### CSV Data
- Raw performance metrics
- Suitable for further analysis
- Can be imported into Excel/BI tools

### Log Files
- Detailed execution logs
- Error messages and stack traces
- System resource usage

## 🎯 Performance Targets

### Vote Service Targets
| Metric | Light Load | Medium Load | Heavy Load |
|--------|------------|-------------|------------|
| Response Time (P95) | < 200ms | < 500ms | < 1000ms |
| Throughput | > 20 RPS | > 50 RPS | > 100 RPS |
| Error Rate | < 0.1% | < 1% | < 5% |

### Worker Service Targets
| Metric | Light Load | Medium Load | Heavy Load |
|--------|------------|-------------|------------|
| Processing Rate | > 50 VPS | > 100 VPS | > 200 VPS |
| Queue Depth | < 100 | < 500 | < 1000 |
| Database Latency | < 50ms | < 100ms | < 200ms |

## 🔍 Troubleshooting

### Common Issues

#### Python Environment Issues
```bash
# If locust command not found
source venv/bin/activate  # Make sure virtual environment is activated

# If import errors occur
pip3 install -r requirements.txt  # Reinstall dependencies in venv

# If setuptools/build errors occur (Python 3.13+)
pip3 install --upgrade pip setuptools wheel
pip3 install -r requirements-minimal.txt  # Use minimal requirements

# Check which Python interpreter is being used
which python3
which pip3

# Check Python version compatibility
python3 --version
```

#### Package Installation Issues
```bash
# For Python 3.13 compatibility issues
pip3 install -r requirements-minimal.txt  # Essential packages only

# Alternative: Install packages individually
pip3 install locust requests redis pymysql

# Skip optional visualization packages if they fail
# numpy and matplotlib are optional for basic load testing
```

#### High Response Times
```bash
# Check system resources
top
htop

# Check service logs
docker-compose logs vote
docker-compose logs worker
```

#### Queue Buildup
```bash
# Check Redis queue length
redis-cli -h localhost -p 6379 llen votes

# Check worker processing
curl http://localhost:8080/metrics
```

#### Database Performance
```bash
# Check MySQL connections
docker exec voting-mysql mysql -u voting_user -pvoting_pass \
  -e "SHOW PROCESSLIST;"

# Check slow queries
docker exec voting-mysql mysql -u voting_user -pvoting_pass \
  -e "SHOW VARIABLES LIKE 'slow_query_log';"
```

### Performance Tuning

#### Vote Service Optimization
```python
# Increase worker processes
gunicorn --workers=4 --bind=0.0.0.0:5000 app:app

# Tune Redis connection pool
redis_client = redis.ConnectionPool(
    host=REDIS_HOST,
    port=REDIS_PORT,
    max_connections=20
)
```

#### Worker Service Optimization
```go
// Increase database connection pool
w.db.SetMaxOpenConns(25)
w.db.SetMaxIdleConns(10)
w.db.SetConnMaxLifetime(time.Hour)

// Batch processing
for len(batch) < batchSize {
    // Collect votes in batch
}
// Insert batch to database
```

## 📚 Educational Value

### Learning Objectives
1. **Performance Testing Fundamentals**
   - Load vs. stress vs. endurance testing
   - Metrics collection and analysis
   - Bottleneck identification

2. **System Scalability**
   - Horizontal vs. vertical scaling
   - Database connection pooling
   - Queue-based architectures

3. **Monitoring and Observability**
   - Real-time metrics collection
   - Performance threshold setting
   - Alert configuration

4. **DevOps Practices**
   - Continuous performance testing
   - CI/CD integration
   - Performance regression detection

### Best Practices Demonstrated
- Realistic user behavior simulation
- Gradual load increase (spawn rate)
- Comprehensive metric collection
- Error scenario testing
- Resource monitoring
- Result analysis and reporting

## 🚀 Advanced Usage

### CI/CD Integration
```yaml
# .github/workflows/load-test.yml
- name: Setup Load Testing Environment
  run: |
    cd load-tests
    python3 -m venv venv
    source venv/bin/activate
    pip3 install -r requirements.txt

- name: Run Load Tests
  run: |
    cd load-tests
    source venv/bin/activate
    ./run_load_tests.sh --headless --duration=1m
    
- name: Analyze Results
  run: |
    cd load-tests
    source venv/bin/activate
    python3 analyze_results.py results/
```

### Custom Test Scenarios
```python
# Create custom user behaviors
class CustomVoteUser(HttpUser):
    def on_start(self):
        # Setup user session
        self.login()
    
    @task
    def complex_voting_pattern(self):
        # Implement specific user journey
        self.browse_homepage()
        self.cast_multiple_votes()
        self.check_results()
```

### Performance Benchmarking
```bash
# Baseline performance
./run_load_tests.sh --baseline

# Compare with previous results
./run_load_tests.sh --compare-baseline
```

## 📊 Sample Reports

### Performance Summary
```
Load Test Results
=================
Test Duration: 2m0s
Votes Generated: 2,450
Database Inserts: 2,445
Peak Queue Depth: 125
Final Queue Depth: 5
Errors: 0

Performance Metrics:
Vote Generation Rate: 20.42 votes/sec
Processing Rate: 20.38 votes/sec
Processing Efficiency: 99.80%
```

### Response Time Distribution
```
Response Time Percentiles:
P50: 45ms
P75: 78ms
P90: 125ms
P95: 180ms
P99: 350ms
```

This load testing suite provides comprehensive tools for understanding and validating the performance characteristics of the distributed voting application, making it an excellent learning resource for DevOps students.
