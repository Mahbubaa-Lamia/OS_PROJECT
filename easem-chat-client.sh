#!/bin/bash

#############################################
# E.A.S.E.M - Agent Main Script
# Runs on client machines being monitored
#############################################

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SHARED_DIR="$SCRIPT_DIR/../shared"
source "$SHARED_DIR/easem-utils.sh"
source "$SHARED_DIR/easem-logger.sh"
source "$SHARED_DIR/easem-security.sh"

# Agent configuration
AGENT_NAME=$(hostname)
AGENT_VERSION="1.0.0"
CHAT_DIR="$SCRIPT_DIR/../chat-data"

# Initialize agent
init_agent() {
    print_info "Initializing E.A.S.E.M Agent v$AGENT_VERSION"
    print_info "Agent Name: $AGENT_NAME"
    
    # Create necessary directories
    ensure_dir "$CHAT_DIR"
    ensure_dir "$SCRIPT_DIR/../logs"
    
    # Log initialization
    log_info "agent" "Agent initialized on $AGENT_NAME"
    
    print_success "Agent initialized successfully"
}

# Show agent status
show_status() {
    echo ""
    print_color "$COLOR_CYAN" "╔════════════════════════════════════════╗"
    print_color "$COLOR_CYAN" "║      E.A.S.E.M Agent Status            ║"
    print_color "$COLOR_CYAN" "╚════════════════════════════════════════╝"
    echo ""
    echo "Agent Name    : $AGENT_NAME"
    echo "Version       : $AGENT_VERSION"
    echo "Local IP      : $(get_local_ip)"
    echo "Status        : Running"
    echo "Uptime        : $(uptime -p | sed 's/up //')"
    echo ""
}

# Collect and display metrics
show_metrics() {
    source "$SCRIPT_DIR/easem-collector.sh"
    collect_metrics_simple
}

# Execute command safely
execute_command() {
    local command=$1
    local executor=${2:-"remote"}
    
    # Validate command
    if ! validate_command "$command"; then
        print_error "Command validation failed"
        log_error "agent" "Command validation failed: $command"
        return 1
    fi
    
    print_info "Executing command: $command"
    log_command "agent" "$executor" "$command" "attempting"
    
    # Execute and capture output
    local output
    local exit_code
    output=$(eval "$command" 2>&1)
    exit_code=$?
    
    if [[ $exit_code -eq 0 ]]; then
        print_success "Command executed successfully"
        log_command "agent" "$executor" "$command" "success"
        echo "$output"
    else
        print_error "Command failed with exit code: $exit_code"
        log_command "agent" "$executor" "$command" "failed:$exit_code"
        echo "$output"
    fi
    
    return $exit_code
}

# Test connection to master
test_master_connection() {
    local master_user=$1
    local master_host=$2
    
    if [[ -z "$master_user" ]] || [[ -z "$master_host" ]]; then
        print_error "Usage: test_master_connection <user> <host>"
        return 1
    fi
    
    print_info "Testing connection to master: $master_user@$master_host"
    
    if test_ssh_connection "$master_user" "$master_host"; then
        print_success "Connection to master successful"
        return 0
    else
        print_error "Cannot connect to master"
        return 1
    fi
}

# Show help
show_help() {
    cat <<EOF

E.A.S.E.M Agent - Enhanced Administration and System Environment Manager
Version: $AGENT_VERSION

USAGE:
    ./easem-agent.sh [COMMAND] [OPTIONS]

COMMANDS:
    init                    Initialize agent
    status                  Show agent status
    metrics                 Display system metrics
    execute <command>       Execute a command
    test <user> <host>      Test connection to master
    help                    Show this help message

EXAMPLES:
    ./easem-agent.sh init
    ./easem-agent.sh status
    ./easem-agent.sh metrics
    ./easem-agent.sh execute "df -h"
    ./easem-agent.sh test admin 192.168.1.100

EOF
}

# Main execution
main() {
    local command=${1:-"help"}
    
    case "$command" in
        init)
            init_agent
            ;;
        status)
            show_status
            ;;
        metrics)
            show_metrics
            ;;
        execute)
            shift
            execute_command "$*"
            ;;
        test)
            test_master_connection "$2" "$3"
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            print_error "Unknown command: $command"
            show_help
            exit 1
            ;;
    esac
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
