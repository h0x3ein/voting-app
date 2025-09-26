# Vote Service

Python Flask web application for collecting votes between cats and dogs.

## Features

- Web interface for voting
- Redis queue integration
- Health check endpoint
- Prometheus metrics
- Comprehensive test suite

## Running the Service

### Development Mode
```bash
# Create and activate virtual environment
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip3 install -r requirements.txt

# Run the service
python3 app.py
```

### Production Mode
```bash
# Create and activate virtual environment
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies including production server
pip3 install -r requirements.txt

# Run with gunicorn
gunicorn --bind 0.0.0.0:5000 --workers 2 app:app
```

## Configuration

Configure via environment variables:

- `REDIS_HOST` - Redis hostname (default: localhost)
- `REDIS_PORT` - Redis port (default: 6379)
- `REDIS_DB` - Redis database number (default: 0)
- `REDIS_PASSWORD` - Redis password (optional)
- `VOTE_QUEUE` - Redis queue name (default: votes)
- `PORT` - Service port (default: 5000)
- `HOST` - Service host (default: 0.0.0.0)

## API Endpoints

- `GET /` - Voting web interface
- `POST /vote` - Submit a vote (JSON: `{"vote": "cats|dogs"}`)
- `GET /health` - Health check endpoint
- `GET /metrics` - Prometheus metrics

## Testing

The service includes comprehensive tests using pytest and Testcontainers.

### Test Dependencies
```bash
# Ensure virtual environment is activated
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install test dependencies
pip3 install -r test_requirements.txt
```

### Running Tests
```bash
# Run all tests
pytest tests/ -v

# Run with coverage
pytest tests/ --cov=app --cov-report=html

# Run specific test categories
pytest tests/ -k "test_health"
pytest tests/ -m "not slow"

# Debug mode
pytest tests/ -s --log-cli-level=DEBUG
```

### Test Structure

The test suite includes:

#### Integration Tests
- Redis container integration using Testcontainers
- Real Redis queue operations
- Health endpoint validation
- Application startup and configuration

#### API Tests
- Vote submission validation
- Invalid input handling
- Case-insensitive vote processing
- Multiple vote handling
- Error response validation

#### Unit Tests
- Configuration loading
- Redis connection handling
- Error scenarios

### Test Features

- **Testcontainers**: Uses real Redis containers for integration testing
- **Isolation**: Each test gets a fresh Redis instance
- **Coverage**: Comprehensive code coverage reporting
- **CI/CD Ready**: Designed for automated testing pipelines

### CI/CD Integration

Example GitHub Actions workflow:

```yaml
test-vote:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    - uses: actions/setup-python@v4
      with:
        python-version: '3.11'
    - name: Install dependencies
      run: |
        cd vote
        python3 -m venv venv
        source venv/bin/activate
        pip3 install -r requirements.txt
        pip3 install -r test_requirements.txt
    - name: Run tests
      run: |
        cd vote
        source venv/bin/activate
        pytest tests/ -v --cov=app --cov-report=xml
    - name: Upload coverage
      uses: codecov/codecov-action@v3
      with:
        file: ./vote/coverage.xml
```

## Metrics

The service exposes Prometheus metrics:

- `votes_total` - Total votes by choice
- `request_duration_seconds` - HTTP request duration
- `health_checks_total` - Health check count by status

## Health Checks

The `/health` endpoint returns:
- Redis connection status
- Service health status
- Timestamp

Example response:
```json
{
  "status": "healthy",
  "service": "vote",
  "redis": "connected",
  "timestamp": "2023-01-01T12:00:00Z"
}
```
