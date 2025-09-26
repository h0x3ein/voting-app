#!/bin/bash

# Comprehensive Load Testing Script for Voting Application
# This script runs various load tests against the voting system

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
VOTE_SERVICE_URL="http://localhost:5000"
WORKER_SERVICE_URL="http://localhost:8080"
RESULT_SERVICE_URL="http://localhost:3000"

# Default test parameters
DEFAULT_USERS=50
DEFAULT_SPAWN_RATE=5
DEFAULT_DURATION="2m"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if a service is running
check_service() {
    local url=$1
    local service_name=$2
    
    if curl -s -f "$url/health" > /dev/null; then
        print_success "$service_name is running"
        return 0
    else
        print_error "$service_name is not responding at $url"
        return 1
    fi
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if virtual environment exists
    if [ ! -d "venv" ]; then
        print_status "Creating Python virtual environment..."
        python3 -m venv venv
    fi
    
    # Activate virtual environment
    print_status "Activating virtual environment..."
    source venv/bin/activate
    
    # Check if Python dependencies are installed
    if ! python3 -c "import locust" 2>/dev/null; then
        print_warning "Locust not found. Installing dependencies..."
        
        # Try full requirements first, fallback to minimal
        if ! pip3 install -r requirements.txt; then
            print_warning "Full requirements failed. Trying minimal requirements..."
            pip3 install -r requirements-minimal.txt
        fi
    fi
    
    # Check if Go is available for worker load tests
    if ! command -v go &> /dev/null; then
        print_warning "Go not found. Worker load tests will be skipped."
        return 1
    fi
    
    # Check if services are running
    local services_ok=true
    
    if ! check_service "$VOTE_SERVICE_URL" "Vote Service"; then
        services_ok=false
    fi
    
    if ! check_service "$WORKER_SERVICE_URL" "Worker Service"; then
        services_ok=false
    fi
    
    if ! check_service "$RESULT_SERVICE_URL" "Result Service"; then
        services_ok=false
    fi
    
    if [ "$services_ok" = false ]; then
        print_error "Some services are not running. Please start them before running load tests."
        echo "Start services with:"
        echo "  cd vote && source venv/bin/activate && python3 app.py"
        echo "  cd worker && go run main.go"
        echo "  cd result && npm start"
        exit 1
    fi
    
    return 0
}

# Function to run vote service load test
run_vote_load_test() {
    local users=${1:-$DEFAULT_USERS}
    local spawn_rate=${2:-$DEFAULT_SPAWN_RATE}
    local duration=${3:-$DEFAULT_DURATION}
    local test_name=$4
    
    print_status "Running Vote Service load test: $test_name"
    print_status "Users: $users, Spawn Rate: $spawn_rate, Duration: $duration"
    
    # Create results directory
    mkdir -p results
    
    # Activate virtual environment and run locust test
    source venv/bin/activate
    locust -f vote_load_test.py \
           --host="$VOTE_SERVICE_URL" \
           --users="$users" \
           --spawn-rate="$spawn_rate" \
           --run-time="$duration" \
           --headless \
           --csv="results/vote_${test_name}_$(date +%Y%m%d_%H%M%S)" \
           --html="results/vote_${test_name}_$(date +%Y%m%d_%H%M%S).html"
    
    print_success "Vote Service load test completed"
}

# Function to run worker service load test
run_worker_load_test() {
    local votes=${1:-1000}
    local workers=${2:-10}
    local duration=${3:-$DEFAULT_DURATION}
    local test_name=$4
    
    print_status "Running Worker Service load test: $test_name"
    print_status "Votes: $votes, Workers: $workers, Duration: $duration"
    
    # Build and run Go load test
    cd load-tests
    go run worker_load_test.go \
        -votes="$votes" \
        -workers="$workers" \
        -duration="$duration" \
        | tee "../results/worker_${test_name}_$(date +%Y%m%d_%H%M%S).log"
    cd ..
    
    print_success "Worker Service load test completed"
}

# Function to run end-to-end load test
run_e2e_load_test() {
    local users=${1:-$DEFAULT_USERS}
    local duration=${2:-$DEFAULT_DURATION}
    
    print_status "Running End-to-End load test"
    print_status "Users: $users, Duration: $duration"
    
    # Start worker load test in background
    (run_worker_load_test $((users * 20)) $((users / 5)) "$duration" "e2e" &)
    
    # Start vote load test
    run_vote_load_test "$users" $((users / 10)) "$duration" "e2e"
    
    # Wait for background processes
    wait
    
    print_success "End-to-End load test completed"
}

# Function to generate load test report
generate_report() {
    print_status "Generating load test report..."
    
    cat > results/load_test_report.md << EOF
# Load Test Report

Generated on: $(date)

## Test Environment
- Vote Service: $VOTE_SERVICE_URL
- Worker Service: $WORKER_SERVICE_URL  
- Result Service: $RESULT_SERVICE_URL

## Test Results

### Vote Service Tests
$(ls results/vote_*.html 2>/dev/null | while read file; do echo "- [$(basename "$file" .html)]($file)"; done || echo "No vote service test results found")

### Worker Service Tests
$(ls results/worker_*.log 2>/dev/null | while read file; do echo "- [$(basename "$file" .log)]($file)"; done || echo "No worker service test results found")

## Performance Summary

### Vote Service Metrics
- Response Time: Check HTML reports
- Throughput: Check HTML reports
- Error Rate: Check HTML reports

### Worker Service Metrics
- Processing Rate: Check log files
- Queue Processing: Check log files
- Database Performance: Check log files

## Recommendations

1. Monitor CPU and memory usage during tests
2. Check Redis queue depth during high load
3. Monitor MySQL connection pool usage
4. Consider horizontal scaling if limits are reached

EOF

    print_success "Report generated: results/load_test_report.md"
}

# Function to clean up old results
cleanup_results() {
    print_status "Cleaning up old test results..."
    rm -rf results/*
    print_success "Old results cleaned up"
}

# Main menu
show_menu() {
    echo
    echo "==================================="
    echo "   Voting App Load Testing Suite"
    echo "==================================="
    echo
    echo "Available tests:"
    echo "1. Light Load Test (10 users, 2m)"
    echo "2. Medium Load Test (25 users, 3m)"
    echo "3. Heavy Load Test (50 users, 5m)"
    echo "4. Stress Test (100 users, 5m)"
    echo "5. Worker Performance Test"
    echo "6. End-to-End Load Test"
    echo "7. Custom Load Test"
    echo "8. Error Handling Test"
    echo "9. Generate Report"
    echo "10. Cleanup Results"
    echo "11. Exit"
    echo
}

# Main script logic
main() {
    # Create results directory
    mkdir -p results
    
    # Check prerequisites
    if ! check_prerequisites; then
        exit 1
    fi
    
    while true; do
        show_menu
        read -p "Select an option (1-11): " choice
        
        case $choice in
            1)
                run_vote_load_test 10 2 "2m" "light"
                ;;
            2)
                run_vote_load_test 25 5 "3m" "medium"
                ;;
            3)
                run_vote_load_test 50 10 "5m" "heavy"
                ;;
            4)
                run_vote_load_test 100 20 "5m" "stress"
                ;;
            5)
                run_worker_load_test 2000 20 "3m" "performance"
                ;;
            6)
                run_e2e_load_test 30 "3m"
                ;;
            7)
                echo
                read -p "Enter number of users: " custom_users
                read -p "Enter spawn rate: " custom_spawn_rate
                read -p "Enter duration (e.g., 2m, 30s): " custom_duration
                run_vote_load_test "$custom_users" "$custom_spawn_rate" "$custom_duration" "custom"
                ;;
            8)
                print_status "Running error handling tests..."
                source venv/bin/activate
                locust -f vote_load_test.py \
                       --host="$VOTE_SERVICE_URL" \
                       --users=20 \
                       --spawn-rate=5 \
                       --run-time="2m" \
                       --headless \
                       --csv="results/error_test_$(date +%Y%m%d_%H%M%S)"
                ;;
            9)
                generate_report
                ;;
            10)
                cleanup_results
                ;;
            11)
                print_status "Exiting..."
                exit 0
                ;;
            *)
                print_error "Invalid option. Please select 1-11."
                ;;
        esac
        
        echo
        read -p "Press Enter to continue..."
    done
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
