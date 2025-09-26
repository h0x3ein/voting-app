# Worker Service

Go background worker that processes votes from Redis queue and stores them in MySQL database.

## Features

- Vote processing from Redis queue
- MySQL database integration
- Health check endpoint
- Prometheus metrics
- Graceful shutdown
- Comprehensive test suite with benchmarks

## Running the Service

### Development Mode
```bash
# Download dependencies
go mod download

# Run the service
go run main.go
```

### Production Mode
```bash
# Build the binary
go build -o worker main.go

# Run the binary
./worker
```

## Configuration

Configure via environment variables:

- `REDIS_HOST` - Redis hostname (default: localhost)
- `REDIS_PORT` - Redis port (default: 6379)
- `REDIS_DB` - Redis database number (default: 0)
- `REDIS_PASSWORD` - Redis password (optional)
- `VOTE_QUEUE` - Redis queue name (default: votes)
- `MYSQL_HOST` - MySQL hostname (default: localhost)
- `MYSQL_PORT` - MySQL port (default: 3306)
- `MYSQL_USER` - MySQL username (default: root)
- `MYSQL_PASSWORD` - MySQL password
- `MYSQL_DATABASE` - MySQL database name (default: voting)
- `PORT` - Service port (default: 8080)
- `HOST` - Service host (default: 0.0.0.0)

## API Endpoints

- `GET /health` - Health check endpoint
- `GET /metrics` - Prometheus metrics

## Database Schema

The worker initializes and uses the following table:

```sql
CREATE TABLE votes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    vote VARCHAR(10) NOT NULL,
    voter_id VARCHAR(255) NOT NULL,
    timestamp DATETIME NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_vote (vote),
    INDEX idx_timestamp (timestamp)
);
```

## Testing

The service includes comprehensive tests using Go's testing package and Testcontainers.

### Running Tests
```bash
# Run all tests
go test ./tests -v

# Run with coverage
go test ./tests -cover

# Run benchmarks
go test ./tests -bench=.

# Run with race detection
go test ./tests -race

# Run short tests only
go test ./tests -short
```

### Test Structure

The test suite includes:

#### Integration Tests
- Redis and MySQL container integration using Testcontainers
- Real database operations
- Vote processing pipeline testing
- Queue operations validation

#### Unit Tests
- Database connection handling
- Redis connection handling
- Vote data validation
- Error scenarios

#### Performance Tests
- Benchmark tests for vote processing
- Load testing scenarios
- Resource usage validation

### Test Features

- **Testcontainers**: Uses real Redis and MySQL containers
- **Isolation**: Fresh containers for each test suite
- **Benchmarks**: Performance testing included
- **Coverage**: Code coverage reporting
- **Race Detection**: Concurrent operation testing

### CI/CD Integration

Example GitHub Actions workflow:

```yaml
test-worker:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    - uses: actions/setup-go@v4
      with:
        go-version: '1.21'
    - name: Run tests
      run: cd worker && go test ./tests -v -cover -race
    - name: Run benchmarks
      run: cd worker && go test ./tests -bench=. -benchmem
```

## Metrics

The service exposes Prometheus metrics:

- `votes_processed_total` - Total votes processed by choice
- `redis_errors_total` - Redis connection errors
- `database_errors_total` - Database errors
- `health_checks_total` - Health check count by status
- `vote_process_duration_seconds` - Vote processing time

## Health Checks

The `/health` endpoint returns:
- Redis connection status
- MySQL connection status
- Service health status
- Timestamp

Example response:
```json
{
  "status": "healthy",
  "service": "worker",
  "redis": "connected",
  "database": "connected",
  "timestamp": "2023-01-01T12:00:00Z"
}
```

## Architecture

The worker follows this processing flow:

1. **Queue Polling**: Continuously polls Redis queue for new votes
2. **Data Validation**: Validates vote data structure and content
3. **Database Storage**: Stores processed votes in MySQL
4. **Error Handling**: Retries failed operations and logs errors
5. **Metrics Update**: Updates Prometheus metrics for monitoring

## Graceful Shutdown

The worker handles shutdown signals gracefully:
- Stops processing new votes
- Completes current vote processing
- Closes database connections
- Shuts down HTTP server
- Exits cleanly
