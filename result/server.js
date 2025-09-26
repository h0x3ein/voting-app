const express = require('express');
const http = require('http');
const socketIo = require('socket.io');
const mysql = require('mysql2/promise');
const promClient = require('prom-client');
const winston = require('winston');
const path = require('path');

// Configure logging
const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.Console()
  ]
});

// Environment variables with defaults (Twelve-Factor App principle)
const config = {
  port: parseInt(process.env.PORT) || 3000,
  host: process.env.HOST || '0.0.0.0',
  mysql: {
    host: process.env.MYSQL_HOST || 'localhost',
    port: parseInt(process.env.MYSQL_PORT) || 3306,
    user: process.env.MYSQL_USER || 'root',
    password: process.env.MYSQL_PASSWORD || 'rootpass',
    database: process.env.MYSQL_DATABASE || 'voting'
  },
  pollInterval: parseInt(process.env.POLL_INTERVAL) || 5000
};

// Prometheus metrics
const register = new promClient.Registry();
promClient.collectDefaultMetrics({ register });

const httpRequests = new promClient.Counter({
  name: 'http_requests_total',
  help: 'Total number of HTTP requests',
  labelNames: ['method', 'route', 'status'],
  registers: [register]
});

const healthChecks = new promClient.Counter({
  name: 'health_checks_total',
  help: 'Total number of health checks',
  labelNames: ['status'],
  registers: [register]
});

const dbQueries = new promClient.Counter({
  name: 'database_queries_total',
  help: 'Total number of database queries',
  labelNames: ['status'],
  registers: [register]
});

const connectedClients = new promClient.Gauge({
  name: 'websocket_clients_connected',
  help: 'Number of connected WebSocket clients',
  registers: [register]
});

// Express app
const app = express();
const server = http.createServer(app);
const io = socketIo(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"]
  }
});

// Database connection pool
let pool;

// Initialize database connection
async function initDatabase() {
  try {
    pool = mysql.createPool({
      host: config.mysql.host,
      port: config.mysql.port,
      user: config.mysql.user,
      password: config.mysql.password,
      database: config.mysql.database,
      waitForConnections: true,
      connectionLimit: 10,
      queueLimit: 0
    });

    // Test connection
    const connection = await pool.getConnection();
    await connection.ping();
    connection.release();
    
    logger.info('Connected to MySQL database');
    return true;
  } catch (error) {
    logger.error('Database connection failed:', error);
    return false;
  }
}

// Get vote results from database
async function getVoteResults() {
  try {
    const [rows] = await pool.execute(`
      SELECT 
        vote,
        COUNT(*) as count
      FROM votes 
      GROUP BY vote
      ORDER BY count DESC
    `);
    
    dbQueries.labels('success').inc();
    
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
    
    return results;
  } catch (error) {
    dbQueries.labels('error').inc();
    logger.error('Failed to get vote results:', error);
    throw error;
  }
}

// Middleware for request logging
app.use((req, res, next) => {
  const start = Date.now();
  
  res.on('finish', () => {
    const duration = Date.now() - start;
    httpRequests.labels(req.method, req.route?.path || req.path, res.statusCode).inc();
    
    logger.info('HTTP Request', {
      method: req.method,
      url: req.url,
      status: res.statusCode,
      duration: `${duration}ms`,
      userAgent: req.get('User-Agent'),
      ip: req.ip
    });
  });
  
  next();
});

// Serve static files
app.use(express.static(path.join(__dirname, 'public')));

// Routes
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

app.get('/api/results', async (req, res) => {
  try {
    const results = await getVoteResults();
    res.json(results);
  } catch (error) {
    logger.error('Failed to get results:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Health check endpoint
app.get('/health', async (req, res) => {
  const health = {
    service: 'result',
    status: 'healthy',
    timestamp: new Date().toISOString()
  };

  try {
    // Test database connection
    const connection = await pool.getConnection();
    await connection.ping();
    connection.release();
    
    health.database = 'connected';
    healthChecks.labels('healthy').inc();
    res.status(200).json(health);
  } catch (error) {
    health.status = 'unhealthy';
    health.database = 'disconnected';
    health.error = error.message;
    healthChecks.labels('unhealthy').inc();
    
    logger.error('Health check failed:', error);
    res.status(503).json(health);
  }
});

// Metrics endpoint
app.get('/metrics', async (req, res) => {
  res.set('Content-Type', register.contentType);
  res.end(await register.metrics());
});

// 404 handler
app.use((req, res) => {
  httpRequests.labels(req.method, 'unknown', 404).inc();
  res.status(404).json({ error: 'Not found' });
});

// Error handler
app.use((error, req, res, next) => {
  logger.error('Unhandled error:', error);
  httpRequests.labels(req.method, req.route?.path || req.path, 500).inc();
  res.status(500).json({ error: 'Internal server error' });
});

// WebSocket handling
io.on('connection', (socket) => {
  connectedClients.inc();
  logger.info('Client connected', { socketId: socket.id });
  
  // Send current results immediately
  getVoteResults()
    .then(results => {
      socket.emit('results', results);
    })
    .catch(error => {
      logger.error('Failed to send initial results:', error);
    });
  
  socket.on('disconnect', () => {
    connectedClients.dec();
    logger.info('Client disconnected', { socketId: socket.id });
  });
});

// Poll for results and broadcast updates
let lastResults = null;

async function pollAndBroadcastResults() {
  try {
    const results = await getVoteResults();
    
    // Only broadcast if results changed
    if (!lastResults || JSON.stringify(results) !== JSON.stringify(lastResults)) {
      io.emit('results', results);
      lastResults = results;
      logger.info('Broadcasting updated results:', results);
    }
  } catch (error) {
    logger.error('Failed to poll results:', error);
  }
}

// Graceful shutdown
process.on('SIGTERM', () => {
  logger.info('SIGTERM received, shutting down gracefully');
  server.close(() => {
    logger.info('HTTP server closed');
    if (pool) {
      pool.end().then(() => {
        logger.info('Database pool closed');
        process.exit(0);
      });
    } else {
      process.exit(0);
    }
  });
});

process.on('SIGINT', () => {
  logger.info('SIGINT received, shutting down gracefully');
  server.close(() => {
    logger.info('HTTP server closed');
    if (pool) {
      pool.end().then(() => {
        logger.info('Database pool closed');
        process.exit(0);
      });
    } else {
      process.exit(0);
    }
  });
});

// Start server
async function start() {
  try {
    // Initialize database
    const dbConnected = await initDatabase();
    if (!dbConnected) {
      logger.error('Failed to connect to database, exiting');
      process.exit(1);
    }
    
    // Start HTTP server
    server.listen(config.port, config.host, () => {
      logger.info(`Result service listening on ${config.host}:${config.port}`);
      logger.info('Database:', config.mysql);
    });
    
    // Start polling for results
    setInterval(pollAndBroadcastResults, config.pollInterval);
    
  } catch (error) {
    logger.error('Failed to start server:', error);
    process.exit(1);
  }
}

start();
