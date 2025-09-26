package tests

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"
	"testing"
	"time"

	"github.com/go-redis/redis/v8"
	_ "github.com/go-sql-driver/mysql"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"github.com/testcontainers/testcontainers-go"
	"github.com/testcontainers/testcontainers-go/modules/mysql"
	redistc "github.com/testcontainers/testcontainers-go/modules/redis"
	"github.com/testcontainers/testcontainers-go/wait"
)

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

// Vote represents a vote record for testing
type Vote struct {
	Vote      string `json:"vote"`
	VoterID   string `json:"voter_id"`
	Timestamp string `json:"timestamp"`
}

// TestingT represents the common interface between *testing.T and *testing.B
type TestingT interface {
	Helper()
	Errorf(format string, args ...interface{})
	FailNow()
}

// requireNoError is a helper function that works with both *testing.T and *testing.B
func requireNoError(t TestingT, err error) {
	t.Helper()
	if err != nil {
		t.Errorf("unexpected error: %v", err)
		t.FailNow()
	}
}

// WorkerTestSuite contains test utilities
type WorkerTestSuite struct {
	redisContainer testcontainers.Container
	mysqlContainer testcontainers.Container
	redisClient    *redis.Client
	db             *sql.DB
	ctx            context.Context
}

func setupTestSuite(t TestingT) *WorkerTestSuite {
	ctx := context.Background()

	// Start Redis container
	redisContainer, err := redistc.RunContainer(ctx,
		testcontainers.WithImage("redis:7-alpine"),
		redistc.WithLogLevel(redistc.LogLevelVerbose),
	)
	requireNoError(t, err)

	// Get Redis connection details
	redisHost, err := redisContainer.Host(ctx)
	requireNoError(t, err)
	redisPort, err := redisContainer.MappedPort(ctx, "6379/tcp")
	requireNoError(t, err)

	// Start MySQL container
	mysqlContainer, err := mysql.RunContainer(ctx,
		testcontainers.WithImage("mysql:8.0"),
		mysql.WithDatabase("voting"),
		mysql.WithUsername("root"),
		mysql.WithPassword("testpass"),
		testcontainers.WithWaitStrategy(
			wait.ForLog("port: 3306  MySQL Community Server").
				WithOccurrence(1).
				WithStartupTimeout(60*time.Second)),
	)
	requireNoError(t, err)

	// Get MySQL connection details
	mysqlHost, err := mysqlContainer.Host(ctx)
	requireNoError(t, err)
	mysqlPort, err := mysqlContainer.MappedPort(ctx, "3306/tcp")
	requireNoError(t, err)

	// Connect to Redis
	redisClient := redis.NewClient(&redis.Options{
		Addr: fmt.Sprintf("%s:%s", redisHost, redisPort.Port()),
	})

	// Connect to MySQL
	dsn := fmt.Sprintf("root:testpass@tcp(%s:%s)/voting?parseTime=true",
		mysqlHost, mysqlPort.Port())
	db, err := sql.Open("mysql", dsn)
	requireNoError(t, err)

	// Wait for MySQL to be ready
	for i := 0; i < 30; i++ {
		if err := db.Ping(); err == nil {
			break
		}
		time.Sleep(1 * time.Second)
	}
	requireNoError(t, db.Ping())

	// Initialize database schema
	createTableSQL := `
		CREATE TABLE IF NOT EXISTS votes (
			id INT AUTO_INCREMENT PRIMARY KEY,
			vote VARCHAR(10) NOT NULL,
			voter_id VARCHAR(255) NOT NULL,
			timestamp DATETIME NOT NULL,
			created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
		)
	`
	_, err = db.Exec(createTableSQL)
	requireNoError(t, err)

	return &WorkerTestSuite{
		redisContainer: redisContainer,
		mysqlContainer: mysqlContainer,
		redisClient:    redisClient,
		db:             db,
		ctx:            ctx,
	}
}

func (suite *WorkerTestSuite) tearDown() {
	if suite.redisClient != nil {
		suite.redisClient.Close()
	}
	if suite.db != nil {
		suite.db.Close()
	}
	if suite.redisContainer != nil {
		suite.redisContainer.Terminate(suite.ctx)
	}
	if suite.mysqlContainer != nil {
		suite.mysqlContainer.Terminate(suite.ctx)
	}
}

func TestWorkerVoteProcessing(t *testing.T) {
	suite := setupTestSuite(t)
	defer suite.tearDown()

	// Create test vote
	vote := Vote{
		Vote:      "cats",
		VoterID:   "192.168.1.1",
		Timestamp: time.Now().Format(time.RFC3339),
	}

	voteJSON, err := json.Marshal(vote)
	require.NoError(t, err)

	// Push vote to Redis queue
	err = suite.redisClient.LPush(suite.ctx, "votes", string(voteJSON)).Err()
	require.NoError(t, err)

	// Simulate worker processing by manually processing the vote
	result, err := suite.redisClient.BRPop(suite.ctx, 1*time.Second, "votes").Result()
	require.NoError(t, err)
	require.Len(t, result, 2)

	var processedVote Vote
	err = json.Unmarshal([]byte(result[1]), &processedVote)
	require.NoError(t, err)

	// Verify vote data
	assert.Equal(t, "cats", processedVote.Vote)
	assert.Equal(t, "192.168.1.1", processedVote.VoterID)

	// Parse timestamp
	timestamp, err := parseTimestamp(processedVote.Timestamp)
	require.NoError(t, err)

	// Insert into database (simulating worker behavior)
	_, err = suite.db.Exec(
		"INSERT INTO votes (vote, voter_id, timestamp) VALUES (?, ?, ?)",
		processedVote.Vote, processedVote.VoterID, timestamp,
	)
	require.NoError(t, err)

	// Verify data was inserted
	var count int
	err = suite.db.QueryRow("SELECT COUNT(*) FROM votes WHERE vote = ?", "cats").Scan(&count)
	require.NoError(t, err)
	assert.Equal(t, 1, count)
}

func TestMultipleVoteProcessing(t *testing.T) {
	suite := setupTestSuite(t)
	defer suite.tearDown()

	// Create multiple test votes
	votes := []Vote{
		{
			Vote:      "cats",
			VoterID:   "192.168.1.1",
			Timestamp: time.Now().Format(time.RFC3339),
		},
		{
			Vote:      "dogs",
			VoterID:   "192.168.1.2",
			Timestamp: time.Now().Format(time.RFC3339),
		},
		{
			Vote:      "cats",
			VoterID:   "192.168.1.3",
			Timestamp: time.Now().Format(time.RFC3339),
		},
	}

	// Push all votes to Redis
	for _, vote := range votes {
		voteJSON, err := json.Marshal(vote)
		require.NoError(t, err)
		err = suite.redisClient.LPush(suite.ctx, "votes", string(voteJSON)).Err()
		require.NoError(t, err)
	}

	// Process all votes
	for i := 0; i < len(votes); i++ {
		result, err := suite.redisClient.BRPop(suite.ctx, 1*time.Second, "votes").Result()
		require.NoError(t, err)

		var vote Vote
		err = json.Unmarshal([]byte(result[1]), &vote)
		require.NoError(t, err)

		timestamp, err := parseTimestamp(vote.Timestamp)
		require.NoError(t, err)

		_, err = suite.db.Exec(
			"INSERT INTO votes (vote, voter_id, timestamp) VALUES (?, ?, ?)",
			vote.Vote, vote.VoterID, timestamp,
		)
		require.NoError(t, err)
	}

	// Verify all votes were processed
	var totalCount int
	err := suite.db.QueryRow("SELECT COUNT(*) FROM votes").Scan(&totalCount)
	require.NoError(t, err)
	assert.Equal(t, 3, totalCount)

	// Verify vote distribution
	var catsCount, dogsCount int
	err = suite.db.QueryRow("SELECT COUNT(*) FROM votes WHERE vote = ?", "cats").Scan(&catsCount)
	require.NoError(t, err)
	err = suite.db.QueryRow("SELECT COUNT(*) FROM votes WHERE vote = ?", "dogs").Scan(&dogsCount)
	require.NoError(t, err)

	assert.Equal(t, 2, catsCount)
	assert.Equal(t, 1, dogsCount)
}

func TestRedisConnectionHandling(t *testing.T) {
	suite := setupTestSuite(t)
	defer suite.tearDown()

	// Test Redis ping
	pong, err := suite.redisClient.Ping(suite.ctx).Result()
	require.NoError(t, err)
	assert.Equal(t, "PONG", pong)

	// Test Redis operations
	err = suite.redisClient.Set(suite.ctx, "test_key", "test_value", 0).Err()
	require.NoError(t, err)

	val, err := suite.redisClient.Get(suite.ctx, "test_key").Result()
	require.NoError(t, err)
	assert.Equal(t, "test_value", val)
}

func TestDatabaseConnectionHandling(t *testing.T) {
	suite := setupTestSuite(t)
	defer suite.tearDown()

	// Test database ping
	err := suite.db.Ping()
	require.NoError(t, err)

	// Test database operations
	_, err = suite.db.Exec("CREATE TABLE IF NOT EXISTS test_table (id INT PRIMARY KEY, name VARCHAR(50))")
	require.NoError(t, err)

	_, err = suite.db.Exec("INSERT INTO test_table (id, name) VALUES (1, 'test')")
	require.NoError(t, err)

	var name string
	err = suite.db.QueryRow("SELECT name FROM test_table WHERE id = 1").Scan(&name)
	require.NoError(t, err)
	assert.Equal(t, "test", name)

	_, err = suite.db.Exec("DROP TABLE test_table")
	require.NoError(t, err)
}

func TestInvalidVoteDataHandling(t *testing.T) {
	suite := setupTestSuite(t)
	defer suite.tearDown()

	// Push invalid JSON to Redis
	err := suite.redisClient.LPush(suite.ctx, "votes", "invalid json").Err()
	require.NoError(t, err)

	// Try to process invalid vote
	result, err := suite.redisClient.BRPop(suite.ctx, 1*time.Second, "votes").Result()
	require.NoError(t, err)

	var vote Vote
	err = json.Unmarshal([]byte(result[1]), &vote)
	assert.Error(t, err) // Should fail to unmarshal
}

func TestEmptyQueueHandling(t *testing.T) {
	suite := setupTestSuite(t)
	defer suite.tearDown()

	// Try to pop from empty queue with timeout
	_, err := suite.redisClient.BRPop(suite.ctx, 100*time.Millisecond, "votes").Result()
	assert.Equal(t, redis.Nil, err) // Should timeout
}

func TestDatabaseSchemaValidation(t *testing.T) {
	suite := setupTestSuite(t)
	defer suite.tearDown()

	// Check that votes table exists and has correct structure
	rows, err := suite.db.Query(`
		SELECT COLUMN_NAME, DATA_TYPE 
		FROM INFORMATION_SCHEMA.COLUMNS 
		WHERE TABLE_SCHEMA = 'voting' AND TABLE_NAME = 'votes'
		ORDER BY ORDINAL_POSITION
	`)
	require.NoError(t, err)
	defer rows.Close()

	expectedColumns := map[string]string{
		"id":         "int",
		"vote":       "varchar",
		"voter_id":   "varchar",
		"timestamp":  "datetime",
		"created_at": "timestamp",
	}

	actualColumns := make(map[string]string)
	for rows.Next() {
		var columnName, dataType string
		err := rows.Scan(&columnName, &dataType)
		require.NoError(t, err)
		actualColumns[columnName] = dataType
	}

	for expectedCol, expectedType := range expectedColumns {
		actualType, exists := actualColumns[expectedCol]
		assert.True(t, exists, "Column %s should exist", expectedCol)
		assert.Contains(t, actualType, expectedType, "Column %s should be of type %s", expectedCol, expectedType)
	}
}

func BenchmarkVoteProcessing(b *testing.B) {
	suite := setupTestSuite(b)
	defer suite.tearDown()

	vote := Vote{
		Vote:      "cats",
		VoterID:   "192.168.1.1",
		Timestamp: time.Now().Format(time.RFC3339),
	}

	voteJSON, err := json.Marshal(vote)
	require.NoError(b, err)

	b.ResetTimer()

	for i := 0; i < b.N; i++ {
		// Push vote to Redis
		err := suite.redisClient.LPush(suite.ctx, "votes", string(voteJSON)).Err()
		require.NoError(b, err)

		// Process vote
		result, err := suite.redisClient.BRPop(suite.ctx, 1*time.Second, "votes").Result()
		require.NoError(b, err)

		var processedVote Vote
		err = json.Unmarshal([]byte(result[1]), &processedVote)
		require.NoError(b, err)

		timestamp, err := parseTimestamp(processedVote.Timestamp)
		require.NoError(b, err)

		_, err = suite.db.Exec(
			"INSERT INTO votes (vote, voter_id, timestamp) VALUES (?, ?, ?)",
			processedVote.Vote, processedVote.VoterID, timestamp,
		)
		require.NoError(b, err)
	}
}
