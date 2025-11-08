#!/bin/bash

# Script to view test logs easily

LOG_DIR="test_logs"

if [ ! -d "$LOG_DIR" ]; then
    echo "❌ No test logs directory found!"
    echo "Run ./test_runner.sh first to generate logs."
    exit 1
fi

echo "========================================="
echo "  BCS Lens - Test Log Viewer"
echo "========================================="
echo ""

# List all log files
echo "Available log files:"
echo ""
ls -lt "$LOG_DIR"/*.log 2>/dev/null | head -10 | awk '{print NR". "$9" ("$6" "$7" "$8")"}'

echo ""
read -p "Enter log file number (or 'latest' for most recent): " choice

if [ "$choice" == "latest" ] || [ -z "$choice" ]; then
    LATEST_LOG=$(ls -t "$LOG_DIR"/test_run_*.log 2>/dev/null | head -1)
    if [ -z "$LATEST_LOG" ]; then
        echo "❌ No log files found!"
        exit 1
    fi
    SELECTED_LOG="$LATEST_LOG"
else
    LOG_FILES=($(ls -t "$LOG_DIR"/test_run_*.log 2>/dev/null))
    if [ -z "${LOG_FILES[$((choice-1))]}" ]; then
        echo "❌ Invalid selection!"
        exit 1
    fi
    SELECTED_LOG="${LOG_FILES[$((choice-1))]}"
fi

echo ""
echo "========================================="
echo "  Viewing: $(basename $SELECTED_LOG)"
echo "========================================="
echo ""

# Show options
echo "Options:"
echo "  1. View full log"
echo "  2. View last 100 lines"
echo "  3. View errors only"
echo "  4. View summary"
echo ""
read -p "Choose option (1-4): " view_option

case $view_option in
    1)
        cat "$SELECTED_LOG"
        ;;
    2)
        tail -n 100 "$SELECTED_LOG"
        ;;
    3)
        ERROR_LOG="${SELECTED_LOG/test_run_/test_errors_}"
        if [ -f "$ERROR_LOG" ]; then
            cat "$ERROR_LOG"
        else
            echo "No error log found. Showing errors from main log:"
            grep -i "error\|failed\|exception" "$SELECTED_LOG" || echo "No errors found in log."
        fi
        ;;
    4)
        echo "=== Test Summary ==="
        grep -E "(test|Test|passed|failed|All tests)" "$SELECTED_LOG" | tail -20
        ;;
    *)
        echo "Invalid option. Showing last 50 lines:"
        tail -n 50 "$SELECTED_LOG"
        ;;
esac

echo ""
echo "========================================="
echo "Log file location: $SELECTED_LOG"
echo "========================================="

