#!/bin/bash

#############################################
# E.A.S.E.M - Agent Deployment Script
# Deploy agent to new client machines
#############################################

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SHARED_DIR="$SCRIPT_DIR/../shared"
AGENT_DIR="$SCRIPT_DIR/../agent"
CONFIG_FILE="$SCRIPT_DIR/config/easem-config.conf"

source "$SHARED_DIR/easem-utils.sh"
source "$SHARED_DIR/easem-logger.sh"
source "$SHARED_DIR/easem-security.sh"

# Load configuration
if file_exists "$CONFIG_FILE"; then
    source "$CONFIG_FILE"
fi

# Deploy agent to remote client
deploy_agent() {
    local client_name=$1
    local client_user=$2
    local client_host=$3
    local ssh_port=${4:-22}
    
    print_info "Deploying E.A.S.E.M Agent to $client_name ($client_host)"
    
    # Validate inputs
    if ! validate_client_name "$client_name"; then
        return 1
    fi
    
    if ! validate_ssh_params "$client_user" "$client_host"; then
        return 1
    fi
    
    # Test connection first
    print_info "Testing SSH connection..."
    if ! test_ssh_connection "$client_user" "$client_host" "$SSH_TIMEOUT"; then
        print_error "Cannot connect to $client_host. Please check:"
        echo "  1. SSH server is running on the client"
        echo "  2. Network connectivity is working"
        echo "  3. Username and hostname are correct"
        echo "  4. SSH keys are set up (run: ssh-copy-id $client_user@$client_host)"
        return 1
    fi
    print_success "Connection successful"
    
    # Create remote directory
    print_info "Creating remote directory structure..."
    ssh $SSH_OPTIONS -p "$ssh_port" "$client_user@$client_host" "mkdir -p ~/easem/agent ~/easem/shared ~/easem/chat-data ~/easem/logs" 2>/dev/null
    
    if [[ $? -ne 0 ]]; then
        print_error "Failed to create remote directories"
        return 1
    fi
    
    # Transfer shared utilities
    print_info "Transferring shared utilities..."
    scp -P "$ssh_port" $SSH_OPTIONS "$SHARED_DIR"/*.sh "$client_user@$client_host:~/easem/shared/" 2>/dev/null
    
    # Transfer agent scripts
    print_info "Transferring agent scripts..."
    scp -P "$ssh_port" $SSH_OPTIONS "$AGENT_DIR"/*.sh "$client_user@$client_host:~/easem/agent/" 2>/dev/null
    
    # Make scripts executable
    print_info "Setting executable permissions..."
    ssh $SSH_OPTIONS -p "$ssh_port" "$client_user@$client_host" "chmod +x ~/easem/agent/*.sh ~/easem/shared/*.sh" 2>/dev/null
    
    # Initialize agent
    print_info "Initializing agent..."
    ssh $SSH_OPTIONS -p "$ssh_port" "$client_user@$client_host" "cd ~/easem/agent && ./easem-agent.sh init" 2>/dev/null
    
    if [[ $? -eq 0 ]]; then
        print_success "Agent deployed successfully to $client_name"
        log_info "master" "Agent deployed to $client_name ($client_host)"
        
        # Add to client list if not already there
        add_to_client_list "$client_name" "$client_user" "$client_host" "$ssh_port"
        
        return 0
    else
        print_error "Agent deployment failed"
        log_error "master" "Agent deployment failed: $client_name ($client_host)"
        return 1
    fi
}

# Add client to the client list
add_to_client_list() {
    local name=$1
    local user=$2
    local host=$3
    local port=$4
    
    local client_list="$SCRIPT_DIR/config/clients.list"
    local entry="${name}:${user}:${host}:${port}"
    
    # Check if already exists
    if grep -q "^${name}:" "$client_list" 2>/dev/null; then
        print_warning "Client $name already in client list"
        return 0
    fi
    
    # Add entry
    echo "$entry" >> "$client_list"
    print_success "Added $name to client list"
}

# Setup SSH keys
setup_ssh_keys() {
    local client_user=$1
    local client_host=$2
    
    print_info "Setting up SSH key authentication..."
    
    # Check if SSH key exists
    if ! file_exists "$SSH_KEY_PATH"; then
        print_info "SSH key not found. Generating new key..."
        ssh-keygen -t rsa -b 4096 -f "$SSH_KEY_PATH" -N "" -C "easem-master"
        print_success "SSH key generated"
    fi
    
    # Copy key to client
    print_info "Copying SSH key to client (you may need to enter password)..."
    ssh-copy-id -i "${SSH_KEY_PATH}.pub" "$client_user@$client_host"
    
    if [[ $? -eq 0 ]]; then
        print_success "SSH key copied successfully"
        check_ssh_key_permissions "$SSH_KEY_PATH"
        return 0
    else
        print_error "Failed to copy SSH key"
        return 1
    fi
}

# Show deployment help
show_help() {
    cat <<EOF

E.A.S.E.M Agent Deployment Tool

USAGE:
    ./easem-deploy.sh <client_name> <user> <host> [port]
    ./easem-deploy.sh --setup-ssh <user> <host>

OPTIONS:
    --setup-ssh     Setup SSH key authentication only

EXAMPLES:
    # Deploy agent to a new client
    ./easem-deploy.sh laptop2 john 192.168.1.105 22

    # Setup SSH keys first (if needed)
    ./easem-deploy.sh --setup-ssh john 192.168.1.105

PREREQUISITES:
    1. SSH server running on client machine
    2. Network connectivity between master and client
    3. Valid username and password for client (for initial setup)

EOF
}

# Main execution
main() {
    if [[ "$1" == "--setup-ssh" ]]; then
        if [[ $# -lt 3 ]]; then
            print_error "Usage: $0 --setup-ssh <user> <host>"
            exit 1
        fi
        setup_ssh_keys "$2" "$3"
    elif [[ $# -ge 3 ]]; then
        deploy_agent "$1" "$2" "$3" "${4:-22}"
    else
        show_help
        exit 1
    fi
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
