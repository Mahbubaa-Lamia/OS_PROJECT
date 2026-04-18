#!/bin/bash

#############################################
# E.A.S.E.M - Remote Command Executor
# Execute commands on remote clients
#############################################

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SHARED_DIR="$SCRIPT_DIR/../shared"
CONFIG_FILE="$SCRIPT_DIR/config/easem-config.conf"

source "$SHARED_DIR/easem-utils.sh"
source "$SHARED_DIR/easem-logger.sh"
source "$SHARED_DIR/easem-security.sh"

# Load configuration
if file_exists "$CONFIG_FILE"; then
    source "$CONFIG_FILE"
fi

# Execute command on remote client
execute_remote_command() {
    local client_user=$1
    local client_host=$2
    local command=$3
    local ssh_port=${4:-22}
    
    # Validate inputs
    if ! validate_ssh_params "$client_user" "$client_host"; then
        return 1
    fi
    
    if ! validate_command "$command"; then
        print_error "Command validation failed"
        return 1
    fi
    
    print_info "Executing on $client_host: $command"
    log_command "master" "$MASTER_USER" "$client_host:$command" "attempting"
    
    # Execute via SSH
    local output
    local exit_code
    output=$(ssh $SSH_OPTIONS -p "$ssh_port" "$client_user@$client_host" "$command" 2>&1)
    exit_code=$?
    
    if [[ $exit_code -eq 0 ]]; then
        print_success "Command executed successfully"
        log_command "master" "$MASTER_USER" "$client_host:$command" "success"
        echo "$output"
    else
        print_error "Command failed with exit code: $exit_code"
        log_command "master" "$MASTER_USER" "$client_host:$command" "failed:$exit_code"
        echo "$output"
    fi
    
    return $exit_code
}

# Execute command on multiple clients
execute_on_multiple() {
    local command=$1
    shift
    local clients=("$@")
    
    print_info "Executing command on ${#clients[@]} client(s)"
    
    for client_spec in "${clients[@]}"; do
        IFS=':' read -r name user host port <<< "$client_spec"
        echo ""
        print_color "$COLOR_CYAN" "=== Client: $name ($host) ==="
        execute_remote_command "$user" "$host" "$command" "$port"
    done
}

# Get metrics from remote client
get_remote_metrics() {
    local client_user=$1
    local client_host=$2
    local ssh_port=${3:-22}
    local format=${4:-"simple"}
    
    local remote_script="~/easem/agent/easem-collector.sh"
    local flag=""
    
    if [[ "$format" == "json" ]]; then
        flag="--json"
    fi
    
    # Execute collector script on remote
    ssh $SSH_OPTIONS -p "$ssh_port" "$client_user@$client_host" "cd ~/easem/agent && ./easem-collector.sh $flag" 2>/dev/null
}

# Install package on remote client
install_package() {
    local client_user=$1
    local client_host=$2
    local package=$3
    local ssh_port=${4:-22}
    
    print_info "Installing package '$package' on $client_host"
    
    # Check if apt is available
    local has_apt
    has_apt=$(ssh $SSH_OPTIONS -p "$ssh_port" "$client_user@$client_host" "command -v apt" 2>/dev/null)
    
    if [[ -z "$has_apt" ]]; then
        print_error "Package manager 'apt' not found on remote system"
        return 1
    fi
    
    # Update package list
    print_info "Updating package list..."
    execute_remote_command "$client_user" "$client_host" "sudo apt update" "$ssh_port"
    
    # Install package
    print_info "Installing $package..."
    execute_remote_command "$client_user" "$client_host" "sudo apt install -y $package" "$ssh_port"
}

# Transfer file to remote client
transfer_file() {
    local local_file=$1
    local client_user=$2
    local client_host=$3
    local remote_path=$4
    local ssh_port=${5:-22}
    
    if ! file_exists "$local_file"; then
        print_error "Local file not found: $local_file"
        return 1
    fi
    
    print_info "Transferring $local_file to $client_host:$remote_path"
    
    scp -P "$ssh_port" $SSH_OPTIONS "$local_file" "$client_user@$client_host:$remote_path" 2>/dev/null
    
    if [[ $? -eq 0 ]]; then
        print_success "File transferred successfully"
        log_info "master" "File transferred: $local_file -> $client_host:$remote_path"
        return 0
    else
        print_error "File transfer failed"
        log_error "master" "File transfer failed: $local_file -> $client_host:$remote_path"
        return 1
    fi
}

# Main execution when run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [[ $# -lt 3 ]]; then
        echo "Usage: $0 <user> <host> <command> [port]"
        exit 1
    fi
    
    execute_remote_command "$1" "$2" "$3" "${4:-22}"
fi
