# Result Service

Node.js web application that displays real-time voting results using WebSockets and MySQL database.

## Features

- Real-time results display
- WebSocket communication for live updates
- MySQL database integration
- Health check endpoint
- Prometheus metrics
- Modern responsive UI
- Comprehensive test suite

## Running the Service

### Development Mode
```bash
# Install dependencies
npm install

# Run the service
npm run dev
```

### Production Mode
```bash
# Install dependencies
npm install --production

# Run the service
npm start
```

## Configuration

Configure via environment variables:

- `MYSQL_HOST` - MySQL hostname (default: localhost)
- `MYSQL_PORT` - MySQL port (default: 3306)
- `MYSQL_USER` - MySQL username (default: root)
- `MYSQL_PASSWORD` - MySQL password
- `MYSQL_DATABASE` - MySQL database name (default: voting)
- `PORT` - Service port (default: 3000)
- `HOST` - Service host (default: 0.0.0.0)
- `POLL_INTERVAL` - Database polling interval in ms (default: 5000)

## API Endpoints

- `GET /` - Real-time results web interface
- `GET /api/results` - Results API endpoint (JSON)
- `GET /health` - Health check endpoint
- `GET /metrics` - Prometheus metrics

## WebSocket Events

- `connection` - Client connects to server
- `results` - Server sends updated results to clients
- `disconnect` - Client disconnects from server

## Testing

The service includes comprehensive tests using Jest and Testcontainers.

### Test Dependencies
```bash
npm install  # Includes dev dependencies
```

### Running Tests
```bash
# Run all tests
npm test

# Run with coverage
npm run test:coverage

# Watch mode for development
npm run test:watch

# Verbose output
npm test -- --verbose

# Run specific tests
npm test -- --testNamePattern="health check"
```

### Test Structure

The test suite includes:

#### Integration Tests
- MySQL container integration using Testcontainers
- Real database operations
- WebSocket functionality testing
- API endpoint validation

#### API Tests
- HTTP endpoint testing
- JSON response validation
- Error handling scenarios
- Health check validation

#### WebSocket Tests
- Client connection handling
- Real-time data broadcasting
- Multiple client scenarios
- Disconnection handling

#### Performance Tests
- Concurrent database queries
- Multiple WebSocket connections
- Resource usage validation

### Test Features

- **Testcontainers**: Uses real MySQL containers for integration testing
- **Isolation**: Fresh containers for each test suite
- **Real-time Testing**: WebSocket communication validation
- **Coverage**: Comprehensive code coverage reporting
- **CI/CD Ready**: Designed for automated testing pipelines

### CI/CD Integration

Example GitHub Actions workflow:

```yaml
test-result:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    - uses: actions/setup-node@v4
      with:
        node-version: '18'
    - name: Install dependencies
      run: cd result && npm install
    - name: Run tests
      run: cd result && npm test -- --coverage --watchAll=false
    - name: Upload coverage
      uses: codecov/codecov-action@v3
      with:
        file: ./result/coverage/lcov.info
```

## Database Schema

The service reads from the votes table:

```sql
SELECT 
  vote,
  COUNT(*) as count
FROM votes 
GROUP BY vote
ORDER BY count DESC
```

## Real-time Updates

The service implements real-time updates through:

1. **Database Polling**: Regularly queries the database for new results
2. **Change Detection**: Compares current results with previous results
3. **WebSocket Broadcasting**: Sends updates to all connected clients
4. **Client Updates**: Browser updates the UI in real-time

## Metrics

The service exposes Prometheus metrics:

- `http_requests_total` - HTTP requests by method, route, and status
- `health_checks_total` - Health check count by status
- `database_queries_total` - Database queries by status
- `websocket_clients_connected` - Connected WebSocket clients

## Health Checks

The `/health` endpoint returns:
- MySQL connection status
- Service health status
- Timestamp

Example response:
```json
{
  "status": "healthy",
  "service": "result",
  "database": "connected",
  "timestamp": "2023-01-01T12:00:00Z"
}
```

## API Response Format

The `/api/results` endpoint returns:

```json
{
  "cats": 150,
  "dogs": 120,
  "total": 270
}
```

## WebSocket Integration

Client-side WebSocket usage:

```javascript
const socket = io();

socket.on('connect', () => {
  console.log('Connected to server');
});

socket.on('results', (data) => {
  updateUI(data);
});

socket.on('disconnect', () => {
  console.log('Disconnected from server');
});
```

## Architecture

The result service follows this architecture:

1. **HTTP Server**: Serves static files and API endpoints
2. **WebSocket Server**: Handles real-time client connections
3. **Database Polling**: Regularly queries for updated results
4. **Change Detection**: Identifies when results have changed
5. **Broadcasting**: Sends updates to all connected clients
6. **UI Updates**: Browser dynamically updates the display
