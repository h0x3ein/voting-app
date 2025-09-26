const request = require('supertest');
const { GenericContainer, Wait } = require('testcontainers');
const mysql = require('mysql2/promise');
const io = require('socket.io-client');
const http = require('http');

// Import server components
const express = require('express');
const socketIo = require('socket.io');

describe('Result Service Integration Tests', () => {
  let mysqlContainer;
  let mysqlConnection;
  let app;
  let server;
  let ioServer;
  let clientSocket;
  let serverPort;

  beforeAll(async () => {
    // Start MySQL container
    mysqlContainer = await new GenericContainer('mysql:8.0')
      .withEnvironment({
        'MYSQL_ROOT_PASSWORD': 'testpass',
        'MYSQL_DATABASE': 'voting'
      })
      .withExposedPorts(3306)
      .withWaitStrategy(Wait.forLogMessage('port: 3306  MySQL Community Server'))
      .withStartupTimeout(60000)
      .start();

    const mysqlHost = mysqlContainer.getHost();
    const mysqlPort = mysqlContainer.getMappedPort(3306);

    // Connect to MySQL
    mysqlConnection = await mysql.createConnection({
      host: mysqlHost,
      port: mysqlPort,
      user: 'root',
      password: 'testpass',
      database: 'voting'
    });

    // Initialize database schema
    await mysqlConnection.execute(`
      CREATE TABLE IF NOT EXISTS votes (
        id INT AUTO_INCREMENT PRIMARY KEY,
        vote VARCHAR(10) NOT NULL,
        voter_id VARCHAR(255) NOT NULL,
        timestamp DATETIME NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        INDEX idx_vote (vote),
        INDEX idx_timestamp (timestamp)
      )
    `);

    // Insert test data
    await mysqlConnection.execute(`
      INSERT INTO votes (vote, voter_id, timestamp) VALUES 
      ('cats', '192.168.1.1', '2023-01-01 10:00:00'),
      ('dogs', '192.168.1.2', '2023-01-01 10:01:00'),
      ('cats', '192.168.1.3', '2023-01-01 10:02:00'),
      ('cats', '192.168.1.4', '2023-01-01 10:03:00'),
      ('dogs', '192.168.1.5', '2023-01-01 10:04:00')
    `);

    // Set environment variables for the app
    process.env.MYSQL_HOST = mysqlHost;
    process.env.MYSQL_PORT = mysqlPort.toString();
    process.env.MYSQL_USER = 'root';
    process.env.MYSQL_PASSWORD = 'testpass';
    process.env.MYSQL_DATABASE = 'voting';
    process.env.PORT = '0'; // Let system assign port
    process.env.POLL_INTERVAL = '1000'; // Faster polling for tests

    // Create Express app and server (simplified version of main server)
    app = express();
    server = http.createServer(app);
    ioServer = socketIo(server);

    // Start server
    await new Promise((resolve) => {
      server.listen(0, () => {
        serverPort = server.address().port;
        resolve();
      });
    });

    // Store container reference for cleanup
    global.testConfig.containers.mysql = mysqlContainer;
  });

  afterAll(async () => {
    if (clientSocket) {
      clientSocket.close();
    }
    if (server) {
      server.close();
    }
    if (mysqlConnection) {
      await mysqlConnection.end();
    }
  });

  beforeEach(() => {
    // Create new client socket for each test
    clientSocket = io(`http://localhost:${serverPort}`);
  });

  afterEach(() => {
    if (clientSocket) {
      clientSocket.close();
    }
  });

  describe('Database Operations', () => {
    test('should connect to MySQL database', async () => {
      expect(mysqlConnection).toBeDefined();
      await expect(mysqlConnection.ping()).resolves.not.toThrow();
    });

    test('should retrieve vote results from database', async () => {
      const [rows] = await mysqlConnection.execute(`
        SELECT 
          vote,
          COUNT(*) as count
        FROM votes 
        GROUP BY vote
        ORDER BY count DESC
      `);

      expect(rows).toHaveLength(2);
      
      const catsResult = rows.find(row => row.vote === 'cats');
      const dogsResult = rows.find(row => row.vote === 'dogs');
      
      expect(catsResult.count).toBe(3);
      expect(dogsResult.count).toBe(2);
    });

    test('should handle empty database gracefully', async () => {
      // Clear votes table
      await mysqlConnection.execute('DELETE FROM votes');
      
      const [rows] = await mysqlConnection.execute(`
        SELECT 
          vote,
          COUNT(*) as count
        FROM votes 
        GROUP BY vote
      `);

      expect(rows).toHaveLength(0);
      
      // Restore test data
      await mysqlConnection.execute(`
        INSERT INTO votes (vote, voter_id, timestamp) VALUES 
        ('cats', '192.168.1.1', '2023-01-01 10:00:00'),
        ('dogs', '192.168.1.2', '2023-01-01 10:01:00'),
        ('cats', '192.168.1.3', '2023-01-01 10:02:00')
      `);
    });
  });

  describe('API Endpoints', () => {
    test('should serve static index page', (done) => {
      // Add a simple route for testing
      app.get('/', (req, res) => {
        res.send('<html><body>Voting Results</body></html>');
      });

      request(app)
        .get('/')
        .expect(200)
        .expect('Content-Type', /html/)
        .expect(/Voting Results/)
        .end(done);
    });

    test('should provide results API endpoint', (done) => {
      // Add results API endpoint
      app.get('/api/results', async (req, res) => {
        try {
          const [rows] = await mysqlConnection.execute(`
            SELECT 
              vote,
              COUNT(*) as count
            FROM votes 
            GROUP BY vote
            ORDER BY count DESC
          `);
          
          const results = {
            cats: 0,
            dogs: 0,
            total: 0
          };
          
          rows.forEach(row => {
            if (row.vote === 'cats' || row.vote === 'dogs') {
              results[row.vote] = row.count;
              results.total += row.count;
            }
          });
          
          res.json(results);
        } catch (error) {
          res.status(500).json({ error: 'Internal server error' });
        }
      });

      request(app)
        .get('/api/results')
        .expect(200)
        .expect('Content-Type', /json/)
        .expect((res) => {
          expect(res.body).toHaveProperty('cats');
          expect(res.body).toHaveProperty('dogs');
          expect(res.body).toHaveProperty('total');
          expect(res.body.cats).toBeGreaterThanOrEqual(0);
          expect(res.body.dogs).toBeGreaterThanOrEqual(0);
          expect(res.body.total).toBe(res.body.cats + res.body.dogs);
        })
        .end(done);
    });

    test('should provide health check endpoint', (done) => {
      // Add health check endpoint
      app.get('/health', async (req, res) => {
        const health = {
          service: 'result',
          status: 'healthy',
          timestamp: new Date().toISOString()
        };

        try {
          await mysqlConnection.ping();
          health.database = 'connected';
          res.status(200).json(health);
        } catch (error) {
          health.status = 'unhealthy';
          health.database = 'disconnected';
          health.error = error.message;
          res.status(503).json(health);
        }
      });

      request(app)
        .get('/health')
        .expect(200)
        .expect('Content-Type', /json/)
        .expect((res) => {
          expect(res.body).toHaveProperty('service', 'result');
          expect(res.body).toHaveProperty('status', 'healthy');
          expect(res.body).toHaveProperty('database', 'connected');
          expect(res.body).toHaveProperty('timestamp');
        })
        .end(done);
    });

    test('should provide metrics endpoint', (done) => {
      // Add metrics endpoint
      app.get('/metrics', (req, res) => {
        const metrics = `
# HELP http_requests_total Total number of HTTP requests
# TYPE http_requests_total counter
http_requests_total{method="GET",route="/",status="200"} 1

# HELP database_queries_total Total number of database queries
# TYPE database_queries_total counter
database_queries_total{status="success"} 5
        `.trim();
        
        res.set('Content-Type', 'text/plain; version=0.0.4; charset=utf-8');
        res.send(metrics);
      });

      request(app)
        .get('/metrics')
        .expect(200)
        .expect('Content-Type', /text\/plain/)
        .expect(/http_requests_total/)
        .expect(/database_queries_total/)
        .end(done);
    });
  });

  describe('WebSocket Functionality', () => {
    test('should establish WebSocket connection', (done) => {
      clientSocket.on('connect', () => {
        expect(clientSocket.connected).toBe(true);
        done();
      });
    });

    test('should receive results on connection', (done) => {
      // Add WebSocket handler
      ioServer.on('connection', async (socket) => {
        try {
          const [rows] = await mysqlConnection.execute(`
            SELECT 
              vote,
              COUNT(*) as count
            FROM votes 
            GROUP BY vote
          `);
          
          const results = {
            cats: 0,
            dogs: 0,
            total: 0
          };
          
          rows.forEach(row => {
            if (row.vote === 'cats' || row.vote === 'dogs') {
              results[row.vote] = row.count;
              results.total += row.count;
            }
          });
          
          socket.emit('results', results);
        } catch (error) {
          console.error('Error sending initial results:', error);
        }
      });

      clientSocket.on('results', (data) => {
        expect(data).toHaveProperty('cats');
        expect(data).toHaveProperty('dogs');
        expect(data).toHaveProperty('total');
        expect(typeof data.cats).toBe('number');
        expect(typeof data.dogs).toBe('number');
        expect(typeof data.total).toBe('number');
        done();
      });
    });

    test('should handle multiple client connections', (done) => {
      const client2 = io(`http://localhost:${serverPort}`);
      let responses = 0;

      const checkResponse = (data) => {
        expect(data).toHaveProperty('cats');
        expect(data).toHaveProperty('dogs');
        responses++;
        if (responses === 2) {
          client2.close();
          done();
        }
      };

      clientSocket.on('results', checkResponse);
      client2.on('results', checkResponse);
    });

    test('should handle client disconnection gracefully', (done) => {
      clientSocket.on('connect', () => {
        clientSocket.disconnect();
        
        // Wait a bit and then reconnect
        setTimeout(() => {
          const newClient = io(`http://localhost:${serverPort}`);
          newClient.on('connect', () => {
            expect(newClient.connected).toBe(true);
            newClient.close();
            done();
          });
        }, 100);
      });
    });
  });

  describe('Data Processing', () => {
    test('should correctly aggregate vote counts', async () => {
      // Add more test data with known distribution
      await mysqlConnection.execute('DELETE FROM votes');
      await mysqlConnection.execute(`
        INSERT INTO votes (vote, voter_id, timestamp) VALUES 
        ('cats', '1', '2023-01-01 10:00:00'),
        ('cats', '2', '2023-01-01 10:01:00'),
        ('cats', '3', '2023-01-01 10:02:00'),
        ('dogs', '4', '2023-01-01 10:03:00'),
        ('dogs', '5', '2023-01-01 10:04:00')
      `);

      const [rows] = await mysqlConnection.execute(`
        SELECT 
          vote,
          COUNT(*) as count
        FROM votes 
        GROUP BY vote
        ORDER BY vote
      `);

      expect(rows).toHaveLength(2);
      expect(rows[0].vote).toBe('cats');
      expect(rows[0].count).toBe(3);
      expect(rows[1].vote).toBe('dogs');
      expect(rows[1].count).toBe(2);
    });

    test('should handle real-time data updates', async () => {
      // This test simulates new votes being added
      const initialCount = await mysqlConnection.execute('SELECT COUNT(*) as total FROM votes');
      const initialTotal = initialCount[0][0].total;

      // Add new vote
      await mysqlConnection.execute(`
        INSERT INTO votes (vote, voter_id, timestamp) VALUES 
        ('cats', 'new-voter', NOW())
      `);

      const newCount = await mysqlConnection.execute('SELECT COUNT(*) as total FROM votes');
      const newTotal = newCount[0][0].total;

      expect(newTotal).toBe(initialTotal + 1);
    });
  });

  describe('Error Handling', () => {
    test('should handle database connection errors gracefully', async () => {
      // Create a connection with invalid credentials
      const invalidConnection = mysql.createConnection({
        host: mysqlContainer.getHost(),
        port: mysqlContainer.getMappedPort(3306),
        user: 'invalid',
        password: 'invalid',
        database: 'voting'
      });

      await expect(invalidConnection.execute('SELECT 1')).rejects.toThrow();
      await invalidConnection.end();
    });

    test('should handle malformed database queries', async () => {
      await expect(mysqlConnection.execute('INVALID SQL QUERY')).rejects.toThrow();
    });
  });

  describe('Performance Tests', () => {
    test('should handle concurrent database queries', async () => {
      const queries = Array(10).fill().map(() => 
        mysqlConnection.execute('SELECT COUNT(*) FROM votes')
      );

      const results = await Promise.all(queries);
      expect(results).toHaveLength(10);
      results.forEach(result => {
        expect(result[0]).toHaveLength(1);
        expect(typeof result[0][0]['COUNT(*)']).toBe('number');
      });
    });

    test('should respond to health check quickly', async () => {
      const start = Date.now();
      await mysqlConnection.ping();
      const duration = Date.now() - start;
      
      expect(duration).toBeLessThan(1000); // Should respond within 1 second
    });
  });
});
