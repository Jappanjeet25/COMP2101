#!/bin/bash

# Function library file
FUNCTION_LIBRARY="reportfunctions.sh"

# Log file
LOG_FILE="/var/log/systeminfo.log"

# Check if the script is run as root
if [[ $EUID -ne 0 ]]; then
  echo "Error: This script must be run as root."
  exit 1
fi

# Source the function library file
source "$FUNCTION_LIBRARY"

# Function: print_help
# Description: Displays the help message for the script
function print_help {
  echo "Usage: systeminfo.sh [OPTIONS]"
  echo
  echo "Options:"
  echo "  -h  Display help for the script and exit"
  echo "  -v  Run the script verbosely, showing errors to the user instead of sending them to the logfile"
  echo "  -system  Run only the computerreport, osreport, cpureport, ramreport, and videoreport"
  echo "  -disk  Run only the diskreport"
  echo "  -network  Run only the networkreport"
  echo
}

# Function: log_error
# Description: Logs the error message with a timestamp to the logfile
function log_error {
  local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  local error_message="$1"
  echo "[$timestamp] $error_message" >> "$LOG_FILE"
}

# Function: run_report
# Description: Runs the full system report using all function library functions
function run_report {
  computerreport
  osreport
  cpureport
  ramreport
  videoreport
  diskreport
  networkreport
}

# Process command line options
while getopts ":hvsystemdisknetwork" opt; do
  case $opt in
    h)
      print_help
      exit 0
      ;;
    v)
      VERBOSE=true
      ;;
    system)
      run_report
      exit 0
      ;;
    disk)
      diskreport
      exit 0
      ;;
    network)
      networkreport
      exit 0
      ;;
    \?)
      echo "Error: Invalid option -$OPTARG" >&2
      print_help
      exit 1
      ;;
  esac
done

# Default behavior: Run the full system report
run_report

# Check if there were any errors and handle verbosity
if [[ -s "$LOG_FILE" ]]; then
  if [[ -n "$VERBOSE" ]]; then
    echo "Errors occurred during the system report. Please check the logfile: $LOG_FILE"
  else
    echo "Errors occurred during the system report. Please contact the system administrator for more details."
  fi
fi
