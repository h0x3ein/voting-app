package main

/*
Load testing for the Worker Service

This program tests the worker service's ability to process votes under load by:
- Generating high-volume vote data in Redis
- Monitoring worker processing performance
- Measuring database insertion rates
- Testing error handling and recovery

Usage:
    go run worker_load_test.go [options]

Options:
    -redis-host string    Redis host (default "localhost")
    -redis-port int       Redis port (default 6379)
    -mysql-host string    MySQL host (default "localhost")
    -mysql-port int       MySQL port (default 3306)
    -mysql-user string    MySQL user (default "voting_user")
    -mysql-pass string    MySQL password (default "voting_pass")
    -mysql-db string      MySQL database (default "voting")
    -votes int            Number of votes to generate (default 1000)
    -workers int          Number of concurrent generators (default 10)
    -duration string      Test duration (default "2m")
    -queue string         Redis queue name (default "votes")
*/

import (
	"context"
	"database/sql"
	"encoding/json"
	"flag"
	"fmt"
	"log"
	"math/rand"
	"runtime"
	"sync"
	"sync/atomic"
	"time"

	"github.com/go-redis/redis/v8"
	_ "github.com/go-sql-driver/mysql"
)

// LoadTestConfig holds configuration for the load test
type LoadTestConfig struct {
	RedisHost   string
	RedisPort   int
	MySQLHost   string
	MySQLPort   int
	MySQLUser   string
	MySQLPass   string
	MySQLDB     string
	VoteCount   int
	WorkerCount int
	Duration    time.Duration
	QueueName   string
}

// Vote represents a vote record
type Vote struct {
	Vote      string `json:"vote"`
	VoterID   string `json:"voter_id"`
	Timestamp string `json:"timestamp"`
}

// LoadTestMetrics tracks performance metrics
type LoadTestMetrics struct {
	VotesGenerated    int64
	VotesProcessed    int64
	QueueDepth        int64
	DatabaseInserts   int64
	Errors            int64
	StartTime         time.Time
	EndTime           time.Time
	PeakQueueDepth    int64
	MinProcessingTime time.Duration
	MaxProcessingTime time.Duration
	AvgProcessingTime time.Duration
}

// LoadTester manages the load testing process
type LoadTester struct {
	config  *LoadTestConfig
	redis   *redis.Client
	db      *sql.DB
	metrics *LoadTestMetrics
	ctx     context.Context
	cancel  context.CancelFunc
	wg      sync.WaitGroup
}

func main() {
	config := parseFlags()

	tester, err := NewLoadTester(config)
	if err != nil {
		log.Fatalf("Failed to create load tester: %v", err)
	}
	defer tester.Close()

	fmt.Printf("Worker Service Load Test\n")
	fmt.Printf("========================\n")
	fmt.Printf("Redis: %s:%d\n", config.RedisHost, config.RedisPort)
	fmt.Printf("MySQL: %s:%d/%s\n", config.MySQLHost, config.MySQLPort, config.MySQLDB)
	fmt.Printf("Votes: %d\n", config.VoteCount)
	fmt.Printf("Workers: %d\n", config.WorkerCount)
	fmt.Printf("Duration: %v\n", config.Duration)
	fmt.Printf("Queue: %s\n", config.QueueName)
	fmt.Printf("\n")

	// Run the load test
	if err := tester.RunTest(); err != nil {
		log.Fatalf("Load test failed: %v", err)
	}

	// Print results
	tester.PrintResults()
}

func parseFlags() *LoadTestConfig {
	config := &LoadTestConfig{}

	flag.StringVar(&config.RedisHost, "redis-host", "localhost", "Redis host")
	flag.IntVar(&config.RedisPort, "redis-port", 6379, "Redis port")
	flag.StringVar(&config.MySQLHost, "mysql-host", "localhost", "MySQL host")
	flag.IntVar(&config.MySQLPort, "mysql-port", 3306, "MySQL port")
	flag.StringVar(&config.MySQLUser, "mysql-user", "voting_user", "MySQL user")
	flag.StringVar(&config.MySQLPass, "mysql-pass", "voting_pass", "MySQL password")
	flag.StringVar(&config.MySQLDB, "mysql-db", "voting", "MySQL database")
	flag.IntVar(&config.VoteCount, "votes", 1000, "Number of votes to generate")
	flag.IntVar(&config.WorkerCount, "workers", 10, "Number of concurrent generators")
	flag.StringVar(&config.QueueName, "queue", "votes", "Redis queue name")

	var durationStr string
	flag.StringVar(&durationStr, "duration", "2m", "Test duration")

	flag.Parse()

	duration, err := time.ParseDuration(durationStr)
	if err != nil {
		log.Fatalf("Invalid duration: %v", err)
	}
	config.Duration = duration

	return config
}

func NewLoadTester(config *LoadTestConfig) (*LoadTester, error) {
	ctx, cancel := context.WithCancel(context.Background())

	// Connect to Redis
	redisClient := redis.NewClient(&redis.Options{
		Addr: fmt.Sprintf("%s:%d", config.RedisHost, config.RedisPort),
	})

	if err := redisClient.Ping(ctx).Err(); err != nil {
		cancel()
		return nil, fmt.Errorf("failed to connect to Redis: %w", err)
	}

	// Connect to MySQL
	dsn := fmt.Sprintf("%s:%s@tcp(%s:%d)/%s?parseTime=true",
		config.MySQLUser, config.MySQLPass,
		config.MySQLHost, config.MySQLPort, config.MySQLDB)

	db, err := sql.Open("mysql", dsn)
	if err != nil {
		cancel()
		return nil, fmt.Errorf("failed to connect to MySQL: %w", err)
	}

	if err := db.Ping(); err != nil {
		cancel()
		return nil, fmt.Errorf("failed to ping MySQL: %w", err)
	}

	return &LoadTester{
		config: config,
		redis:  redisClient,
		db:     db,
		metrics: &LoadTestMetrics{
			StartTime:         time.Now(),
			MinProcessingTime: time.Hour, // Will be reduced
		},
		ctx:    ctx,
		cancel: cancel,
	}, nil
}

func (lt *LoadTester) Close() {
	lt.cancel()
	lt.wg.Wait()
	if lt.redis != nil {
		lt.redis.Close()
	}
	if lt.db != nil {
		lt.db.Close()
	}
}

func (lt *LoadTester) RunTest() error {
	fmt.Println("Starting load test...")

	// Clear existing queue
	lt.redis.Del(lt.ctx, lt.config.QueueName)

	// Get initial database count
	initialCount, err := lt.getDatabaseVoteCount()
	if err != nil {
		return fmt.Errorf("failed to get initial vote count: %w", err)
	}

	// Start monitoring
	lt.wg.Add(1)
	go lt.monitor()

	// Start vote generators
	for i := 0; i < lt.config.WorkerCount; i++ {
		lt.wg.Add(1)
		go lt.generateVotes(i)
	}

	// Wait for test duration
	time.Sleep(lt.config.Duration)

	// Stop generators
	lt.cancel()

	// Wait for all generators to finish
	lt.wg.Wait()

	// Wait a bit for worker to process remaining votes
	fmt.Println("Waiting for worker to process remaining votes...")
	time.Sleep(10 * time.Second)

	// Get final metrics
	finalCount, err := lt.getDatabaseVoteCount()
	if err != nil {
		return fmt.Errorf("failed to get final vote count: %w", err)
	}

	lt.metrics.DatabaseInserts = finalCount - initialCount
	lt.metrics.EndTime = time.Now()

	return nil
}

func (lt *LoadTester) generateVotes(workerID int) {
	defer lt.wg.Done()

	choices := []string{"cats", "dogs"}

	for {
		select {
		case <-lt.ctx.Done():
			return
		default:
			// Generate a vote
			vote := Vote{
				Vote:      choices[rand.Intn(len(choices))],
				VoterID:   fmt.Sprintf("load-test-worker-%d-%d", workerID, rand.Intn(1000)),
				Timestamp: time.Now().Format("2006-01-02T15:04:05.999999"),
			}

			voteJSON, err := json.Marshal(vote)
			if err != nil {
				atomic.AddInt64(&lt.metrics.Errors, 1)
				continue
			}

			// Push to Redis queue
			err = lt.redis.LPush(lt.ctx, lt.config.QueueName, string(voteJSON)).Err()
			if err != nil {
				atomic.AddInt64(&lt.metrics.Errors, 1)
				continue
			}

			atomic.AddInt64(&lt.metrics.VotesGenerated, 1)

			// Small delay to prevent overwhelming
			time.Sleep(time.Millisecond * time.Duration(rand.Intn(100)))
		}
	}
}

func (lt *LoadTester) monitor() {
	defer lt.wg.Done()

	ticker := time.NewTicker(1 * time.Second)
	defer ticker.Stop()

	for {
		select {
		case <-lt.ctx.Done():
			return
		case <-ticker.C:
			// Check queue depth
			queueLen, err := lt.redis.LLen(lt.ctx, lt.config.QueueName).Result()
			if err != nil {
				atomic.AddInt64(&lt.metrics.Errors, 1)
				continue
			}

			atomic.StoreInt64(&lt.metrics.QueueDepth, queueLen)

			// Track peak queue depth
			if queueLen > atomic.LoadInt64(&lt.metrics.PeakQueueDepth) {
				atomic.StoreInt64(&lt.metrics.PeakQueueDepth, queueLen)
			}

			// Print progress
			generated := atomic.LoadInt64(&lt.metrics.VotesGenerated)
			if generated%100 == 0 && generated > 0 {
				fmt.Printf("Generated: %d votes, Queue depth: %d\n", generated, queueLen)
			}
		}
	}
}

func (lt *LoadTester) getDatabaseVoteCount() (int64, error) {
	var count int64
	err := lt.db.QueryRow("SELECT COUNT(*) FROM votes").Scan(&count)
	return count, err
}

func (lt *LoadTester) PrintResults() {
	fmt.Printf("\nLoad Test Results\n")
	fmt.Printf("=================\n")

	duration := lt.metrics.EndTime.Sub(lt.metrics.StartTime)

	fmt.Printf("Test Duration: %v\n", duration)
	fmt.Printf("Votes Generated: %d\n", atomic.LoadInt64(&lt.metrics.VotesGenerated))
	fmt.Printf("Database Inserts: %d\n", lt.metrics.DatabaseInserts)
	fmt.Printf("Peak Queue Depth: %d\n", atomic.LoadInt64(&lt.metrics.PeakQueueDepth))
	fmt.Printf("Final Queue Depth: %d\n", atomic.LoadInt64(&lt.metrics.QueueDepth))
	fmt.Printf("Errors: %d\n", atomic.LoadInt64(&lt.metrics.Errors))

	if duration.Seconds() > 0 {
		voteRate := float64(atomic.LoadInt64(&lt.metrics.VotesGenerated)) / duration.Seconds()
		processRate := float64(lt.metrics.DatabaseInserts) / duration.Seconds()

		fmt.Printf("\nPerformance Metrics:\n")
		fmt.Printf("Vote Generation Rate: %.2f votes/sec\n", voteRate)
		fmt.Printf("Processing Rate: %.2f votes/sec\n", processRate)

		if atomic.LoadInt64(&lt.metrics.VotesGenerated) > 0 {
			processedPercent := float64(lt.metrics.DatabaseInserts) / float64(atomic.LoadInt64(&lt.metrics.VotesGenerated)) * 100
			fmt.Printf("Processing Efficiency: %.2f%%\n", processedPercent)
		}
	}

	// System info
	fmt.Printf("\nSystem Info:\n")
	fmt.Printf("Go Version: %s\n", runtime.Version())
	fmt.Printf("GOMAXPROCS: %d\n", runtime.GOMAXPROCS(0))
	fmt.Printf("NumCPU: %d\n", runtime.NumCPU())
	fmt.Printf("NumGoroutine: %d\n", runtime.NumGoroutine())

	// Memory stats
	var m runtime.MemStats
	runtime.ReadMemStats(&m)
	fmt.Printf("Memory Alloc: %d KB\n", m.Alloc/1024)
	fmt.Printf("Memory TotalAlloc: %d KB\n", m.TotalAlloc/1024)
	fmt.Printf("Memory Sys: %d KB\n", m.Sys/1024)
	fmt.Printf("Memory NumGC: %d\n", m.NumGC)
}
