#!/bin/bash

#############################################
# E.A.S.E.M - Shared Utility Functions
# Common functions used by master and agent
#############################################

# Color codes for output
COLOR_RED='\033[0;31m'
COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[1;33m'
COLOR_BLUE='\033[0;34m'
COLOR_CYAN='\033[0;36m'
COLOR_RESET='\033[0m'

# Get current timestamp in readable format
get_timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

# Get timestamp for filenames (no spaces or special chars)
get_timestamp_filename() {
    date '+%Y%m%d_%H%M%S'
}

# Print colored message
print_color() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${COLOR_RESET}"
}

# Print success message
print_success() {
    print_color "$COLOR_GREEN" "[SUCCESS] $1"
}

# Print error message
print_error() {
    print_color "$COLOR_RED" "[ERROR] $1"
}

# Print warning message
print_warning() {
    print_color "$COLOR_YELLOW" "[WARNING] $1"
}

# Print info message
print_info() {
    print_color "$COLOR_BLUE" "[INFO] $1"
}

# Check if command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Check if file exists
file_exists() {
    [[ -f "$1" ]]
}

# Check if directory exists
dir_exists() {
    [[ -d "$1" ]]
}

# Create directory if it doesn't exist
ensure_dir() {
    local dir_path=$1
    if ! dir_exists "$dir_path"; then
        mkdir -p "$dir_path"
        print_success "Created directory: $dir_path"
    fi
}

# Validate IP address format
validate_ip() {
    local ip=$1
    local valid_ip_regex='^([0-9]{1,3}\.){3}[0-9]{1,3}$'
    
    if [[ $ip =~ $valid_ip_regex ]]; then
        return 0
    else
        return 1
    fi
}

# Test SSH connection to remote host
test_ssh_connection() {
    local user=$1
    local host=$2
    local timeout=${3:-5}  # Default 5 seconds
    
    if timeout "$timeout" ssh -o BatchMode=yes -o ConnectTimeout="$timeout" "$user@$host" "echo 'OK'" &>/dev/null; then
        return 0
    else
        return 1
    fi
}

# Get local IP address
get_local_ip() {
    # Get IP from WSL or native Linux
    if command_exists ip; then
        ip addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1' | head -n1
    elif command_exists hostname; then
        hostname -I | awk '{print $1}'
    else
        echo "127.0.0.1"
    fi
}

# Format bytes to human readable
format_bytes() {
    local bytes=$1
    if (( bytes < 1024 )); then
        echo "${bytes}B"
    elif (( bytes < 1048576 )); then
        echo "$(( bytes / 1024 ))KB"
    elif (( bytes < 1073741824 )); then
        echo "$(( bytes / 1048576 ))MB"
    else
        echo "$(( bytes / 1073741824 ))GB"
    fi
}

# Sanitize input (remove dangerous characters)
sanitize_input() {
    local input=$1
    # Remove potentially dangerous characters
    echo "$input" | sed 's/[;&|`$]//g'
}

# Check if running as root
is_root() {
    [[ $EUID -eq 0 ]]
}

# Parse JSON value (simple jq alternative if jq not available)
parse_json_simple() {
    local json=$1
    local key=$2
    echo "$json" | grep -o "\"$key\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" | sed 's/.*":\s*"\(.*\)"/\1/'
}

# Show progress spinner
show_spinner() {
    local pid=$1
    local message=${2:-"Working"}
    local spin='-\|/'
    local i=0
    
    while kill -0 "$pid" 2>/dev/null; do
        i=$(( (i+1) %4 ))
        printf "\r${message}... ${spin:$i:1}"
        sleep 0.1
    done
    printf "\r${message}... Done!     \n"
}

# Export functions so they can be used by other scripts
export -f get_timestamp
export -f get_timestamp_filename
export -f print_color
export -f print_success
export -f print_error
export -f print_warning
export -f print_info
export -f command_exists
export -f file_exists
export -f dir_exists
export -f ensure_dir
export -f validate_ip
export -f test_ssh_connection
export -f get_local_ip
export -f format_bytes
export -f sanitize_input
export -f is_root
export -f parse_json_simple
