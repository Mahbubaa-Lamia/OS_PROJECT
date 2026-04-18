#!/bin/bash

#############################################
# E.A.S.E.M - Security Functions
# Input validation and security checks
#############################################

# Source utilities
_SECURITY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_SECURITY_DIR/easem-utils.sh"

# Whitelist of allowed commands (can be customized)
ALLOWED_COMMANDS=(
    "ls"
    "pwd"
    "whoami"
    "hostname"
    "uptime"
    "df"
    "free"
    "top"
    "ps"
    "netstat"
    "ss"
    "date"
    "cat"
    "grep"
    "systemctl status"
    "apt list --installed"
    "apt update"
    "apt install"
    "apt remove"
    "sudo systemctl"
)

# Check if command is in whitelist
is_command_allowed() {
    local command=$1
    local cmd_base
    cmd_base=$(echo "$command" | awk '{print $1}')
    
    # Check if it's a whitelisted command
    for allowed in "${ALLOWED_COMMANDS[@]}"; do
        if [[ "$command" == "$allowed"* ]] || [[ "$cmd_base" == "$allowed" ]]; then
            return 0
        fi
    done
    
    return 1
}

# Validate and sanitize command input
validate_command() {
    local command=$1
    
    # Check for empty command
    if [[ -z "$command" ]]; then
        print_error "Empty command not allowed"
        return 1
    fi
    
    # Check for dangerous patterns
    if [[ "$command" =~ (rm\s+-rf|mkfs|dd|:(){|fork|bomb) ]]; then
        print_error "Dangerous command pattern detected"
        return 1
    fi
    
    # Check if command contains pipe to shell
    if [[ "$command" =~ (\||bash|sh|exec) ]]; then
        print_warning "Command contains potentially dangerous operators"
        # Allow but log it
    fi
    
    return 0
}

# Sanitize filename (for chat logs, etc)
sanitize_filename() {
    local filename=$1
    # Remove path traversal attempts and special characters
    echo "$filename" | sed 's/[^a-zA-Z0-9._-]/_/g'
}

# Validate client name
validate_client_name() {
    local name=$1
    # Only allow alphanumeric, dash, underscore
    if [[ "$name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        return 0
    else
        print_error "Invalid client name. Only letters, numbers, dash and underscore allowed."
        return 1
    fi
}

# Check SSH key permissions (should be 600)
check_ssh_key_permissions() {
    local key_file=$1
    
    if ! file_exists "$key_file"; then
        print_error "SSH key not found: $key_file"
        return 1
    fi
    
    local perms
    perms=$(stat -c "%a" "$key_file" 2>/dev/null || stat -f "%A" "$key_file" 2>/dev/null)
    
    if [[ "$perms" != "600" ]]; then
        print_warning "SSH key has incorrect permissions: $perms (should be 600)"
        chmod 600 "$key_file"
        print_success "Fixed SSH key permissions to 600"
    fi
    
    return 0
}

# Validate SSH connection parameters
validate_ssh_params() {
    local user=$1
    local host=$2
    
    # Validate username
    if [[ ! "$user" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
        print_error "Invalid username format"
        return 1
    fi
    
    # Validate hostname/IP
    if ! validate_ip "$host" && [[ ! "$host" =~ ^[a-zA-Z0-9.-]+$ ]]; then
        print_error "Invalid hostname or IP address"
        return 1
    fi
    
    return 0
}

# Create secure temporary file
create_secure_temp() {
    local prefix=${1:-"easem"}
    mktemp -t "${prefix}.XXXXXXXXXX"
}

# Secure delete file (overwrite before delete)
secure_delete() {
    local file=$1
    if file_exists "$file"; then
        # Overwrite with random data
        dd if=/dev/urandom of="$file" bs=1k count=1 2>/dev/null
        rm -f "$file"
    fi
}

# Export functions
export -f is_command_allowed
export -f validate_command
export -f sanitize_filename
export -f validate_client_name
export -f check_ssh_key_permissions
export -f validate_ssh_params
export -f create_secure_temp
export -f secure_delete
