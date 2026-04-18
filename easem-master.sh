#!/bin/bash

#############################################
# E.A.S.E.M - Master Control Script
# Main interface for system administration
#############################################

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SHARED_DIR="$SCRIPT_DIR/../shared"
CONFIG_FILE="$SCRIPT_DIR/config/easem-config.conf"
CLIENTS_FILE="$SCRIPT_DIR/config/clients.list"

source "$SHARED_DIR/easem-utils.sh"
source "$SHARED_DIR/easem-logger.sh"
source "$SHARED_DIR/easem-security.sh"
source "$SCRIPT_DIR/easem-commands.sh"

# Load configuration
if file_exists "$CONFIG_FILE"; then
    source "$CONFIG_FILE"
fi

VERSION="1.0.0"

# Initialize master
init_master() {
    print_info "Initializing E.A.S.E.M Master Control v$VERSION"
    
    # Create necessary directories
    ensure_dir "$SCRIPT_DIR/config"
    ensure_dir "$SCRIPT_DIR/../chat-data"
    ensure_dir "$SCRIPT_DIR/../logs"
    
    # Check SSH setup
    if ! file_exists "${SSH_KEY_PATH:-$HOME/.ssh/id_rsa}"; then
        print_warning "SSH key not found. You may need to generate one."
        echo "Run: ssh-keygen -t rsa -b 4096"
    else
        print_success "SSH key found"
    fi
    
    # Check configuration
    if ! file_exists "$CONFIG_FILE"; then
        print_error "Configuration file not found: $CONFIG_FILE"
        return 1
    fi
    
    if ! file_exists "$CLIENTS_FILE"; then
        print_warning "No clients configured yet"
        echo "Add clients to: $CLIENTS_FILE"
    fi
    
    log_info "master" "Master initialized"
    print_success "Master initialized successfully"
    
    echo ""
    print_info "Next steps:"
    echo "  1. Generate SSH key if needed: ssh-keygen -t rsa -b 4096"
    echo "  2. Deploy agent to clients: ./easem-deploy.sh <client_name> <user> <host>"
    echo "  3. Start monitoring: ./easem-dashboard.sh live"
    echo ""
}

# Show status
show_status() {
    echo ""
    print_color "$COLOR_CYAN" "╔════════════════════════════════════════════════════════╗"
    print_color "$COLOR_CYAN" "║           E.A.S.E.M Master Control Status              ║"
    print_color "$COLOR_CYAN" "╚════════════════════════════════════════════════════════╝"
    echo ""
    echo "Version       : $VERSION"
    echo "Master Name   : ${MASTER_NAME:-master-control}"
    echo "Local IP      : $(get_local_ip)"
    echo "SSH Key       : ${SSH_KEY_PATH:-$HOME/.ssh/id_rsa}"
    
    # Count clients
    local client_count=0
    if file_exists "$CLIENTS_FILE"; then
        client_count=$(grep -v '^#' "$CLIENTS_FILE" | grep -v '^$' | wc -l)
    fi
    echo "Clients       : $client_count configured"
    echo ""
}

# Execute command on client
exec_on_client() {
    local client_name=$1
    shift
    local command="$*"
    
    if [[ -z "$client_name" ]] || [[ -z "$command" ]]; then
        print_error "Usage: exec <client_name> <command>"
        return 1
    fi
    
    # Find client
    local client_info
    if file_exists "$CLIENTS_FILE"; then
        client_info=$(grep "^$client_name:" "$CLIENTS_FILE")
    fi
    
    if [[ -z "$client_info" ]]; then
        print_error "Client not found: $client_name"
        return 1
    fi
    
    IFS=':' read -r name user host port <<< "$client_info"
    
    print_info "Executing on $name: $command"
    execute_remote_command "$user" "$host" "$command" "$port"
}

# Install package on client
install_on_client() {
    local client_name=$1
    local package=$2
    
    if [[ -z "$client_name" ]] || [[ -z "$package" ]]; then
        print_error "Usage: install <client_name> <package_name>"
        return 1
    fi
    
    # Find client
    local client_info
    if file_exists "$CLIENTS_FILE"; then
        client_info=$(grep "^$client_name:" "$CLIENTS_FILE")
    fi
    
    if [[ -z "$client_info" ]]; then
        print_error "Client not found: $client_name"
        return 1
    fi
    
    IFS=':' read -r name user host port <<< "$client_info"
    
    install_package "$user" "$host" "$package" "$port"
}

# Remove client from list
remove_client() {
    local client_name=$1
    
    if [[ -z "$client_name" ]]; then
        print_error "Usage: remove <client_name>"
        return 1
    fi
    
    if ! file_exists "$CLIENTS_FILE"; then
        print_error "Client list not found: $CLIENTS_FILE"
        return 1
    fi
    
    # Check if client exists
    if ! grep -q "^$client_name:" "$CLIENTS_FILE"; then
        print_error "Client not found: $client_name"
        return 1
    fi
    
    # Get client info for display
    local client_info=$(grep "^$client_name:" "$CLIENTS_FILE")
    IFS=':' read -r name user host port <<< "$client_info"
    
    # Confirm removal
    echo ""
    print_warning "About to remove client:"
    echo "  Name: $name"
    echo "  User: $user"
    echo "  Host: $host"
    echo "  Port: $port"
    echo ""
    read -p "Are you sure? (y/N): " confirm
    
    if [[ "$confirm" != "y" ]] && [[ "$confirm" != "Y" ]]; then
        print_info "Removal cancelled"
        return 0
    fi
    
    # Remove from clients.list
    sed -i "/^$client_name:/d" "$CLIENTS_FILE"
    
    if [[ $? -eq 0 ]]; then
        print_success "Client '$client_name' removed from list"
        log_info "master" "Client removed: $client_name ($host)"
        echo ""
        print_info "Note: This only removes the client from the monitoring list."
        print_info "The agent software is still installed on the remote system."
        echo ""
    else
        print_error "Failed to remove client"
        return 1
    fi
}

# View logs
view_logs() {
    local component=${1:-"master"}
    local lines=${2:-50}
    
    local log_file="$SCRIPT_DIR/../logs/${component}_$(date '+%Y%m%d').log"
    
    if ! file_exists "$log_file"; then
        print_warning "Log file not found: $log_file"
        return 1
    fi
    
    print_info "Showing last $lines lines of $component log:"
    echo ""
    tail -n "$lines" "$log_file"
}

# Interactive menu
interactive_menu() {
    while true; do
        clear
        print_color "$COLOR_CYAN" "╔════════════════════════════════════════════════════════╗"
        print_color "$COLOR_CYAN" "║              E.A.S.E.M Master Control                  ║"
        print_color "$COLOR_CYAN" "╚════════════════════════════════════════════════════════╝"
        echo ""
        echo "  1) List Clients"
        echo "  2) Monitor Dashboard (Live)"
        echo "  3) Execute Command"
        echo "  4) Install Package"
        echo "  5) Chat with Client"
        echo "  6) Remove Client"
        echo "  7) Status"
        echo "  8) Exit"
        echo ""
        read -p "Select option [1-8]: " choice
        
        case $choice in
            1)
                "$SCRIPT_DIR/easem-dashboard.sh" list
                read -p "Press Enter to continue..."
                ;;
            2)
                "$SCRIPT_DIR/easem-dashboard.sh" live
                ;;
            3)
                echo ""
                read -p "Client name: " client
                read -p "Command: " cmd
                exec_on_client "$client" "$cmd"
                read -p "Press Enter to continue..."
                ;;
            4)
                echo ""
                read -p "Client name: " client
                read -p "Package name: " pkg
                install_on_client "$client" "$pkg"
                read -p "Press Enter to continue..."
                ;;
            5)
                "$SCRIPT_DIR/easem-dashboard.sh" list
                echo ""
                read -p "Client name: " client
                "$SCRIPT_DIR/easem-chat.sh" start "$client"
                ;;
            6)
                "$SCRIPT_DIR/easem-dashboard.sh" list
                echo ""
                read -p "Client name to remove: " client
                remove_client "$client"
                read -p "Press Enter to continue..."
                ;;
            7)
                show_status
                read -p "Press Enter to continue..."
                ;;
            8)
                print_info "Goodbye!"
                exit 0
                ;;
            *)
                print_error "Invalid option"
                sleep 1
                ;;
        esac
    done
}

# Show help
show_help() {
    cat <<EOF

E.A.S.E.M - Enhanced Administration and System Environment Manager
Version: $VERSION

USAGE:
    ./easem-master.sh [COMMAND] [OPTIONS]

COMMANDS:
    init                            Initialize master control
    status                          Show master status
    menu                            Interactive menu interface
    
    dashboard [live|list|all]       Monitoring dashboard
    chat <client> [start|history]   Chat with client
    deploy <name> <user> <host>     Deploy agent to client
    remove <client>                 Remove client from list
    
    exec <client> <command>         Execute command on client
    install <client> <package>      Install package on client
    
    logs [component]                View logs
    help                            Show this help

EXAMPLES:
    # Initialize and check status
    ./easem-master.sh init
    ./easem-master.sh status
    
    # Interactive menu
    ./easem-master.sh menu
    
    # Deploy agent to new client
    ./easem-master.sh deploy laptop2 john 192.168.1.105
    
    # Remove client from monitoring
    ./easem-master.sh remove laptop2
    
    # Monitor clients
    ./easem-master.sh dashboard live
    ./easem-master.sh dashboard list
    
    # Execute command
    ./easem-master.sh exec laptop2 "df -h"
    
    # Install package
    ./easem-master.sh install laptop2 htop
    
    # Chat with client
    ./easem-master.sh chat laptop2 start

QUICK START:
    1. Initialize: ./easem-master.sh init
    2. Deploy agent: ./easem-master.sh deploy <client_name> <user> <host>
    3. Monitor: ./easem-master.sh dashboard live
    4. Chat: ./easem-master.sh chat <client_name> start

EOF
}

# Main execution
main() {
    local command=${1:-"help"}
    
    case "$command" in
        init)
            init_master
            ;;
        status)
            show_status
            ;;
        menu)
            interactive_menu
            ;;
        dashboard)
            shift
            "$SCRIPT_DIR/easem-dashboard.sh" "$@"
            ;;
        chat)
            shift
            "$SCRIPT_DIR/easem-chat.sh" "$@"
            ;;
        deploy)
            shift
            "$SCRIPT_DIR/easem-deploy.sh" "$@"
            ;;
        remove)
            remove_client "$2"
            ;;
        exec)
            shift
            exec_on_client "$@"
            ;;
        install)
            install_on_client "$2" "$3"
            ;;
        logs)
            view_logs "${2:-master}" "${3:-50}"
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            print_error "Unknown command: $command"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
