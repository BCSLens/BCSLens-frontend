#!/bin/bash

# BCS Lens - Automated Test Runner Script
# This script runs all automated tests and generates a report

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Navigate to frontend directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Create logs directory
LOG_DIR="$SCRIPT_DIR/test_logs"
mkdir -p "$LOG_DIR"

# Generate log filename with timestamp
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="$LOG_DIR/test_run_$TIMESTAMP.log"
ERROR_LOG="$LOG_DIR/test_errors_$TIMESTAMP.log"

# Function to log with timestamp
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Function to log errors
log_error() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - ERROR: $1" | tee -a "$ERROR_LOG" | tee -a "$LOG_FILE"
}

echo "========================================="
echo "  BCS Lens - Automated Test Suite"
echo "========================================="
echo ""
log "Starting test run..."
echo -e "${BLUE}📝 Log file: $LOG_FILE${NC}"
echo -e "${BLUE}📝 Error log: $ERROR_LOG${NC}"
echo ""

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    log_error "Flutter is not installed or not in PATH"
    echo -e "${RED}❌ Flutter not found!${NC}"
    echo "Please install Flutter: https://flutter.dev/docs/get-started/install"
    exit 1
fi

log "Flutter version: $(flutter --version | head -n 1)"

# Check if we're in a Flutter project
if [ ! -f "pubspec.yaml" ]; then
    log_error "pubspec.yaml not found. Not a Flutter project?"
    echo -e "${RED}❌ Not a Flutter project directory!${NC}"
    exit 1
fi

echo "📦 Installing dependencies..."
log "Running: flutter pub get"
flutter pub get 2>&1 | tee -a "$LOG_FILE"

if [ ${PIPESTATUS[0]} -ne 0 ]; then
    log_error "Failed to install dependencies"
    echo -e "${RED}❌ Failed to install dependencies!${NC}"
    echo -e "${YELLOW}Check log file: $LOG_FILE${NC}"
    exit 1
fi

echo ""
echo "🧪 Running all tests..."
echo ""
log "Running: flutter test --coverage"

# Run tests with coverage and save output
TEST_OUTPUT=$(flutter test --coverage 2>&1)
TEST_EXIT_CODE=${PIPESTATUS[0]}

# Save full output to log
echo "$TEST_OUTPUT" >> "$LOG_FILE"

# Display output (last 50 lines to avoid terminal overflow)
echo "$TEST_OUTPUT" | tail -n 50

# Check if tests passed
if [ $TEST_EXIT_CODE -eq 0 ]; then
    echo ""
    log "All tests passed!"
    echo -e "${GREEN}✅ All tests passed!${NC}"
    echo ""
    
    # Generate coverage report if lcov is installed
    if command -v lcov &> /dev/null; then
        echo "📊 Generating coverage report..."
        log "Generating coverage report..."
        genhtml coverage/lcov.info -o coverage/html 2>&1 | tee -a "$LOG_FILE"
        
        if [ ${PIPESTATUS[0]} -eq 0 ]; then
            echo -e "${GREEN}✅ Coverage report generated at: coverage/html/index.html${NC}"
            log "Coverage report generated successfully"
            echo ""
            echo "To view coverage report, run:"
            echo "  open coverage/html/index.html"
        else
            log_error "Failed to generate coverage report"
            echo -e "${YELLOW}⚠️  Failed to generate coverage report${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  lcov not installed. Install with: brew install lcov${NC}"
        log "lcov not installed"
    fi
else
    echo ""
    log_error "Some tests failed! Exit code: $TEST_EXIT_CODE"
    echo -e "${RED}❌ Some tests failed!${NC}"
    echo ""
    echo -e "${YELLOW}📝 Full error details saved to:${NC}"
    echo -e "   - Log: $LOG_FILE"
    echo -e "   - Errors: $ERROR_LOG"
    echo ""
    echo -e "${BLUE}To view full log:${NC}"
    echo "   cat $LOG_FILE"
    echo ""
    echo -e "${BLUE}To view only errors:${NC}"
    echo "   cat $ERROR_LOG"
    exit 1
fi

echo ""
echo "========================================="
echo "  Test Summary"
echo "========================================="
echo "Total Test Files: 8"
echo "Total Test Cases: 54"
echo ""
echo "Test Categories:"
echo "  - Login Tests: 3"
echo "  - Records Tests: 9"
echo "  - Add Record Tests: 12"
echo "  - Review & Confirm Tests: 3"
echo "  - History Tests: 6"
echo "  - Special Care Tests: 6"
echo "  - Profile Tests: 5"
echo "  - General System Tests: 4"
echo "  - Widget Tests: 1"
echo "========================================="
echo ""
log "Test run completed"
echo -e "${BLUE}📝 Full log saved to: $LOG_FILE${NC}"
if [ -f "$ERROR_LOG" ] && [ -s "$ERROR_LOG" ]; then
    echo -e "${RED}⚠️  Errors saved to: $ERROR_LOG${NC}"
fi
echo ""

