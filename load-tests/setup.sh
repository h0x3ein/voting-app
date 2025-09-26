#!/bin/bash

# Setup script for Load Testing Environment
# This script creates a Python virtual environment and installs dependencies

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Setting up Load Testing Environment${NC}"
echo "==================================="

# Check if Python 3 is available
if ! command -v python3 &> /dev/null; then
    echo -e "${YELLOW}Error: Python 3 is not installed or not in PATH${NC}"
    echo "Please install Python 3.8 or later"
    exit 1
fi

echo -e "${BLUE}Python version:${NC} $(python3 --version)"

# Create virtual environment if it doesn't exist
if [ ! -d "venv" ]; then
    echo -e "${BLUE}Creating Python virtual environment...${NC}"
    python3 -m venv venv
    echo -e "${GREEN}✓ Virtual environment created${NC}"
else
    echo -e "${GREEN}✓ Virtual environment already exists${NC}"
fi

# Activate virtual environment
echo -e "${BLUE}Activating virtual environment...${NC}"
source venv/bin/activate

# Upgrade pip and core build tools
echo -e "${BLUE}Upgrading pip and build tools...${NC}"
pip3 install --upgrade pip setuptools wheel

# Install dependencies with retry mechanism
echo -e "${BLUE}Installing dependencies...${NC}"
if ! pip3 install -r requirements.txt; then
    echo -e "${YELLOW}First installation attempt failed. Trying with reduced dependencies...${NC}"
    # Try installing core dependencies only
    pip3 install locust requests redis pymysql
    echo -e "${YELLOW}Core dependencies installed. You may need to install numpy/matplotlib separately if needed.${NC}"
fi

echo -e "${GREEN}✓ Dependencies installed${NC}"

# Check if Go is available (for worker load tests)
if command -v go &> /dev/null; then
    echo -e "${BLUE}Go version:${NC} $(go version)"
    echo -e "${BLUE}Installing Go dependencies...${NC}"
    go mod download
    echo -e "${GREEN}✓ Go dependencies installed${NC}"
else
    echo -e "${YELLOW}Warning: Go not found. Worker load tests will not be available.${NC}"
fi

echo
echo -e "${GREEN}Setup completed successfully!${NC}"
echo
echo "To activate the virtual environment for future sessions:"
echo -e "${BLUE}source venv/bin/activate${NC}"
echo
echo "To run load tests:"
echo -e "${BLUE}./run_load_tests.sh${NC}"
echo
echo "To run manual tests:"
echo -e "${BLUE}source venv/bin/activate${NC}"
echo -e "${BLUE}locust -f vote_load_test.py --host=http://localhost:5000${NC}"
