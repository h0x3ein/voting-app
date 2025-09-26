package main

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"
	"net/http"
	"os"
	"os/signal"
	"strconv"
	"syscall"
	"time"

	"github.com/go-redis/redis/v8"
	_ "github.com/go-sql-driver/mysql"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promhttp"
	"github.com/sirupsen/logrus"
)

// Configuration from environment variables
type Config struct {
	RedisHost     string
	RedisPort     int
	RedisDB       int
	RedisPassword string
	VoteQueue     string
	MySQLHost     string
	MySQLPort     int
	MySQLUser     string
	MySQLPassword string
	MySQLDatabase string
	Port          int
	Host          string
}

// Vote represents a vote record
type Vote struct {
	Vote      string `json:"vote"`
	VoterID   string `json:"voter_id"`
	Timestamp string `json:"timestamp"`
}

// Prometheus metrics
var (
	votesProcessed = prometheus.NewCounterVec(
		prometheus.CounterOpts{
			Name: "votes_processed_total",
			Help: "Total number of votes processed",
		},
		[]string{"choice"},
	)

	redisErrors = prometheus.NewCounter(
		prometheus.CounterOpts{
			Name: "redis_errors_total",
			Help: "Total number of Redis errors",
		},
	)

	dbErrors = prometheus.NewCounter(
		prometheus.CounterOpts{
			Name: "database_errors_total",
			Help: "Total number of database errors",
		},
	)

	healthChecks = prometheus.NewCounterVec(
		prometheus.CounterOpts{
			Name: "health_checks_total",
			Help: "Total number of health checks",
		},
		[]string{"status"},
	)

	processTime = prometheus.NewHistogram(
		prometheus.HistogramOpts{
			Name: "vote_process_duration_seconds",
			Help: "Time taken to process a vote",
		},
	)
)

func init() {
	prometheus.MustRegister(votesProcessed)
	prometheus.MustRegister(redisErrors)
	prometheus.MustRegister(dbErrors)
	prometheus.MustRegister(healthChecks)
	prometheus.MustRegister(processTime)
}

// Worker handles vote processing
type Worker struct {
	config      *Config
	redisClient *redis.Client
	db          *sql.DB
	logger      *logrus.Logger
	ctx         context.Context
	cancel      context.CancelFunc
}

// NewWorker creates a new worker instance
func NewWorker(config *Config) *Worker {
	logger := logrus.New()
	logger.SetFormatter(&logrus.JSONFormatter{})
	logger.SetLevel(logrus.InfoLevel)

	ctx, cancel := context.WithCancel(context.Background())

	return &Worker{
		config: config,
		logger: logger,
		ctx:    ctx,
		cancel: cancel,
	}
}

// loadConfig loads configuration from environment variables
func loadConfig() *Config {
	redisPort, _ := strconv.Atoi(getEnv("REDIS_PORT", "6379"))
	redisDB, _ := strconv.Atoi(getEnv("REDIS_DB", "0"))
	mysqlPort, _ := strconv.Atoi(getEnv("MYSQL_PORT", "3306"))
	port, _ := strconv.Atoi(getEnv("PORT", "8080"))

	return &Config{
		RedisHost:     getEnv("REDIS_HOST", "localhost"),
		RedisPort:     redisPort,
		RedisDB:       redisDB,
		RedisPassword: getEnv("REDIS_PASSWORD", ""),
		VoteQueue:     getEnv("VOTE_QUEUE", "votes"),
		MySQLHost:     getEnv("MYSQL_HOST", "localhost"),
		MySQLPort:     mysqlPort,
		MySQLUser:     getEnv("MYSQL_USER", "root"),
		MySQLPassword: getEnv("MYSQL_PASSWORD", "rootpass"),
		MySQLDatabase: getEnv("MYSQL_DATABASE", "voting"),
		Port:          port,
		Host:          getEnv("HOST", "0.0.0.0"),
	}
}

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

// connectRedis establishes Redis connection
func (w *Worker) connectRedis() error {
	w.redisClient = redis.NewClient(&redis.Options{
		Addr:     fmt.Sprintf("%s:%d", w.config.RedisHost, w.config.RedisPort),
		Password: w.config.RedisPassword,
		DB:       w.config.RedisDB,
	})

	_, err := w.redisClient.Ping(w.ctx).Result()
	if err != nil {
		return fmt.Errorf("redis connection failed: %w", err)
	}

	w.logger.Info("Connected to Redis")
	return nil
}

// connectDB establishes database connection
func (w *Worker) connectDB() error {
	dsn := fmt.Sprintf("%s:%s@tcp(%s:%d)/%s?parseTime=true",
		w.config.MySQLUser, w.config.MySQLPassword,
		w.config.MySQLHost, w.config.MySQLPort,
		w.config.MySQLDatabase)

	var err error
	w.db, err = sql.Open("mysql", dsn)
	if err != nil {
		return fmt.Errorf("database connection failed: %w", err)
	}

	w.db.SetMaxOpenConns(10)
	w.db.SetMaxIdleConns(5)
	w.db.SetConnMaxLifetime(time.Hour)

	if err := w.db.Ping(); err != nil {
		return fmt.Errorf("database ping failed: %w", err)
	}

	w.logger.Info("Connected to MySQL")
	return nil
}

// initDB initializes database schema
func (w *Worker) initDB() error {
	createTableSQL := `
		CREATE TABLE IF NOT EXISTS votes (
			id INT AUTO_INCREMENT PRIMARY KEY,
			vote VARCHAR(10) NOT NULL,
			voter_id VARCHAR(255) NOT NULL,
			timestamp DATETIME NOT NULL,
			created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
		)
	`

	_, err := w.db.Exec(createTableSQL)
	if err != nil {
		return fmt.Errorf("failed to create table: %w", err)
	}

	w.logger.Info("Database schema initialized")
	return nil
}

// processVotes processes votes from Redis queue
func (w *Worker) processVotes() {
	w.logger.Info("Starting vote processing")

	for {
		select {
		case <-w.ctx.Done():
			w.logger.Info("Stopping vote processing")
			return
		default:
			timer := prometheus.NewTimer(processTime)

			result, err := w.redisClient.BRPop(w.ctx, 1*time.Second, w.config.VoteQueue).Result()
			if err == redis.Nil {
				// No data available, continue
				continue
			} else if err != nil {
				redisErrors.Inc()
				w.logger.WithError(err).Error("Failed to pop from Redis")
				time.Sleep(5 * time.Second)
				continue
			}

			if len(result) < 2 {
				w.logger.Error("Invalid Redis result")
				continue
			}

			voteData := result[1]
			var vote Vote

			if err := json.Unmarshal([]byte(voteData), &vote); err != nil {
				w.logger.WithError(err).Error("Failed to unmarshal vote data")
				continue
			}

			// Parse timestamp with multiple format attempts
			timestamp, err := parseTimestamp(vote.Timestamp)
			if err != nil {
				w.logger.WithError(err).Error("Failed to parse timestamp")
				timestamp = time.Now()
			}

			// Insert into database
			_, err = w.db.Exec(
				"INSERT INTO votes (vote, voter_id, timestamp) VALUES (?, ?, ?)",
				vote.Vote, vote.VoterID, timestamp,
			)

			if err != nil {
				dbErrors.Inc()
				w.logger.WithError(err).Error("Failed to insert vote into database")
				// Put the vote back to the queue for retry
				w.redisClient.LPush(w.ctx, w.config.VoteQueue, voteData)
			} else {
				votesProcessed.WithLabelValues(vote.Vote).Inc()
				w.logger.WithFields(logrus.Fields{
					"vote":      vote.Vote,
					"voter_id":  vote.VoterID,
					"timestamp": vote.Timestamp,
				}).Info("Vote processed successfully")
			}

			timer.ObserveDuration()
		}
	}
}

// healthCheck handles health check endpoint
func (w *Worker) healthCheck(writer http.ResponseWriter, request *http.Request) {
	writer.Header().Set("Content-Type", "application/json")

	health := map[string]interface{}{
		"service":   "worker",
		"timestamp": time.Now().Format(time.RFC3339),
	}

	// Check Redis connection
	_, redisErr := w.redisClient.Ping(w.ctx).Result()
	if redisErr != nil {
		health["redis"] = "disconnected"
		health["redis_error"] = redisErr.Error()
	} else {
		health["redis"] = "connected"
	}

	// Check database connection
	dbErr := w.db.Ping()
	if dbErr != nil {
		health["database"] = "disconnected"
		health["database_error"] = dbErr.Error()
	} else {
		health["database"] = "connected"
	}

	// Determine overall health status
	if redisErr != nil || dbErr != nil {
		health["status"] = "unhealthy"
		healthChecks.WithLabelValues("unhealthy").Inc()
		writer.WriteHeader(http.StatusServiceUnavailable)
	} else {
		health["status"] = "healthy"
		healthChecks.WithLabelValues("healthy").Inc()
		writer.WriteHeader(http.StatusOK)
	}

	json.NewEncoder(writer).Encode(health)
}

// startHTTPServer starts the HTTP server for health checks and metrics
func (w *Worker) startHTTPServer() {
	http.HandleFunc("/health", w.healthCheck)
	http.Handle("/metrics", promhttp.Handler())

	server := &http.Server{
		Addr:    fmt.Sprintf("%s:%d", w.config.Host, w.config.Port),
		Handler: nil,
	}

	go func() {
		w.logger.Infof("Starting HTTP server on %s:%d", w.config.Host, w.config.Port)
		if err := server.ListenAndServe(); err != http.ErrServerClosed {
			w.logger.WithError(err).Fatal("HTTP server failed")
		}
	}()

	// Graceful shutdown
	go func() {
		<-w.ctx.Done()
		shutdownCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
		defer cancel()
		server.Shutdown(shutdownCtx)
	}()
}

// Start starts the worker
func (w *Worker) Start() error {
	// Connect to Redis
	if err := w.connectRedis(); err != nil {
		return err
	}
	defer w.redisClient.Close()

	// Connect to database
	if err := w.connectDB(); err != nil {
		return err
	}
	defer w.db.Close()

	// Initialize database
	if err := w.initDB(); err != nil {
		return err
	}

	// Start HTTP server
	w.startHTTPServer()

	// Start processing votes
	go w.processVotes()

	w.logger.Info("Worker started successfully")

	// Wait for interrupt signal
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, syscall.SIGINT, syscall.SIGTERM)
	<-sigChan

	w.logger.Info("Shutdown signal received")
	w.cancel()

	// Give some time for graceful shutdown
	time.Sleep(2 * time.Second)
	w.logger.Info("Worker stopped")

	return nil
}

// parseTimestamp attempts to parse timestamp in multiple formats
func parseTimestamp(timestampStr string) (time.Time, error) {
	// List of formats to try, in order of preference
	formats := []string{
		time.RFC3339,                 // "2006-01-02T15:04:05Z07:00"
		time.RFC3339Nano,             // "2006-01-02T15:04:05.999999999Z07:00"
		"2006-01-02T15:04:05.999999", // Python isoformat() without timezone
		"2006-01-02T15:04:05",        // Without microseconds and timezone
		time.DateTime,                // "2006-01-02 15:04:05"
	}

	for _, format := range formats {
		if t, err := time.Parse(format, timestampStr); err == nil {
			// If parsing succeeds but no timezone info, assume UTC
			if t.Location() == time.UTC && format != time.RFC3339 && format != time.RFC3339Nano {
				return t.UTC(), nil
			}
			return t, nil
		}
	}

	return time.Time{}, fmt.Errorf("unable to parse timestamp: %s", timestampStr)
}

func main() {
	config := loadConfig()
	worker := NewWorker(config)

	if err := worker.Start(); err != nil {
		worker.logger.WithError(err).Fatal("Worker failed to start")
	}
}
