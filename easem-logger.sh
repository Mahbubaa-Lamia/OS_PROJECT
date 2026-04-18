#!/bin/bash

#############################################
# E.A.S.E.M - Logging Functions
# Centralized logging for all components
#############################################

# Source utilities
_LOGGER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_LOGGER_DIR/easem-utils.sh"

# Default log directory
LOG_DIR="${EASEM_LOG_DIR:-$_LOGGER_DIR/../logs}"
ensure_dir "$LOG_DIR"

# Get log file path for a component
get_log_file() {
    local component=$1
    echo "$LOG_DIR/${component}_$(date '+%Y%m%d').log"
}

# Write log entry
write_log() {
    local level=$1
    local component=$2
    local message=$3
    local log_file
    
    log_file=$(get_log_file "$component")
    echo "[$(get_timestamp)] [$level] $message" >> "$log_file"
}

# Log info message
log_info() {
    local component=$1
    local message=$2
    write_log "INFO" "$component" "$message"
}

# Log error message
log_error() {
    local component=$1
    local message=$2
    write_log "ERROR" "$component" "$message"
}

# Log warning message
log_warning() {
    local component=$1
    local message=$2
    write_log "WARNING" "$component" "$message"
}

# Log debug message
log_debug() {
    local component=$1
    local message=$2
    if [[ "${EASEM_DEBUG:-0}" == "1" ]]; then
        write_log "DEBUG" "$component" "$message"
    fi
}

# Log command execution
log_command() {
    local component=$1
    local user=$2
    local command=$3
    local result=$4
    write_log "COMMAND" "$component" "User: $user | Command: $command | Result: $result"
}

# View logs for a component
view_logs() {
    local component=$1
    local lines=${2:-50}
    local log_file
    
    log_file=$(get_log_file "$component")
    if file_exists "$log_file"; then
        tail -n "$lines" "$log_file"
    else
        print_warning "No log file found for component: $component"
    fi
}

# Clean old logs (older than X days)
clean_old_logs() {
    local days=${1:-7}
    print_info "Cleaning logs older than $days days..."
    find "$LOG_DIR" -name "*.log" -type f -mtime +"$days" -delete
    print_success "Old logs cleaned"
}

# Export functions
export -f get_log_file
export -f write_log
export -f log_info
export -f log_error
export -f log_warning
export -f log_debug
export -f log_command
export -f view_logs
export -f clean_old_logs
