#!/bin/bash

#############################################
# E.A.S.E.M - Monitoring Dashboard
# Display real-time metrics from clients
#############################################

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SHARED_DIR="$SCRIPT_DIR/../shared"
CONFIG_FILE="$SCRIPT_DIR/config/easem-config.conf"
CLIENTS_FILE="$SCRIPT_DIR/config/clients.list"

source "$SHARED_DIR/easem-utils.sh"
source "$SHARED_DIR/easem-logger.sh"
source "$SCRIPT_DIR/easem-commands.sh"

# Load configuration
if file_exists "$CONFIG_FILE"; then
    source "$CONFIG_FILE"
fi

# Read client list
read_clients() {
    local clients=()
    
    if ! file_exists "$CLIENTS_FILE"; then
        return 1
    fi
    
    while IFS=':' read -r name user host port; do
        # Skip comments and empty lines
        [[ "$name" =~ ^#.*$ ]] && continue
        [[ -z "$name" ]] && continue
        
        clients+=("$name:$user:$host:$port")
    done < "$CLIENTS_FILE"
    
    echo "${clients[@]}"
}

# Check client online status
check_client_status() {
    local client_user=$1
    local client_host=$2
    local ssh_port=${3:-22}
    
    if test_ssh_connection "$client_user" "$client_host" 3; then
        echo "ONLINE"
    else
        echo "OFFLINE"
    fi
}

# Display single client metrics
display_client_metrics() {
    local client_name=$1
    local client_user=$2
    local client_host=$3
    local ssh_port=${4:-22}
    
    print_color "$COLOR_CYAN" "╔══════════════════════════════════════════════════╗"
    print_color "$COLOR_CYAN" "║  Client: $client_name @ $client_host"
    print_color "$COLOR_CYAN" "╚══════════════════════════════════════════════════╝"
    
    # Check status
    local status
    status=$(check_client_status "$client_user" "$client_host" "$ssh_port")
    
    if [[ "$status" == "ONLINE" ]]; then
        print_success "Status: ONLINE"
        echo ""
        
        # Get metrics
        get_remote_metrics "$client_user" "$client_host" "$ssh_port" "simple"
    else
        print_error "Status: OFFLINE"
        echo "Cannot retrieve metrics - client is not reachable"
    fi
    
    echo ""
}

# Display all clients overview
display_all_clients() {
    local clients
    IFS=' ' read -ra clients <<< "$(read_clients)"
    
    if [[ ${#clients[@]} -eq 0 ]]; then
        print_warning "No clients configured"
        echo "Add clients to: $CLIENTS_FILE"
        echo "Format: client_name:username:hostname:port"
        return 1
    fi
    
    clear
    print_color "$COLOR_CYAN" "╔════════════════════════════════════════════════════════╗"
    print_color "$COLOR_CYAN" "║        E.A.S.E.M - System Monitoring Dashboard         ║"
    print_color "$COLOR_CYAN" "╚════════════════════════════════════════════════════════╝"
    echo ""
    print_info "Total Clients: ${#clients[@]}"
    print_info "Last Update: $(get_timestamp)"
    echo ""
    
    # Display each client
    for client_spec in "${clients[@]}"; do
        IFS=':' read -r name user host port <<< "$client_spec"
        display_client_metrics "$name" "$user" "$host" "$port"
    done
    
    echo ""
    print_color "$COLOR_YELLOW" "Press Ctrl+C to exit | Refresh in ${DASHBOARD_REFRESH_INTERVAL}s"
}

# Live dashboard with auto-refresh
live_dashboard() {
    print_info "Starting live dashboard (refresh every ${DASHBOARD_REFRESH_INTERVAL}s)"
    echo "Press Ctrl+C to exit"
    sleep 2
    
    while true; do
        display_all_clients
        sleep "$DASHBOARD_REFRESH_INTERVAL"
    done
}

# Get quick metrics summary from client
get_quick_metrics() {
    local client_user=$1
    local client_host=$2
    local ssh_port=${3:-22}
    
    # Get metrics and parse key values
    local metrics
    metrics=$(ssh $SSH_OPTIONS -p "$ssh_port" "$client_user@$client_host" "cd ~/easem/agent && ./easem-collector.sh" 2>/dev/null)
    
    if [[ -z "$metrics" ]]; then
        echo "N/A|N/A|N/A|N/A"
        return 1
    fi
    
    # Extract CPU, Memory, Disk, and Uptime
    local cpu=$(echo "$metrics" | grep "CPU Usage:" | awk '{print $3}')
    local mem=$(echo "$metrics" | grep "Memory:" | awk -F'PERCENT:' '{print $2}' | cut -d'%' -f1)
    local disk=$(echo "$metrics" | grep "Disk:" | awk -F'PERCENT:' '{print $2}' | cut -d'%' -f1)
    local uptime=$(echo "$metrics" | grep "Uptime:" | cut -d':' -f2- | xargs)
    
    # Format output
    echo "${cpu:-N/A}|${mem:-N/A}%|${disk:-N/A}%|${uptime:-N/A}"
}

# Show client list with metrics summary
list_clients() {
    local clients
    IFS=' ' read -ra clients <<< "$(read_clients)"
    
    if [[ ${#clients[@]} -eq 0 ]]; then
        print_warning "No clients configured"
        return 1
    fi
    
    echo ""
    print_color "$COLOR_CYAN" "╔════════════════════════════════════════════════════════════════════════════════════════════╗"
    print_color "$COLOR_CYAN" "║                           E.A.S.E.M Client List & Status                                   ║"
    print_color "$COLOR_CYAN" "╚════════════════════════════════════════════════════════════════════════════════════════════╝"
    echo ""
    
    printf "%-12s %-10s %-18s %-8s %-10s %-10s %-18s\n" \
        "CLIENT" "STATUS" "HOST" "CPU" "MEMORY" "DISK" "UPTIME"
    printf "%-12s %-10s %-18s %-8s %-10s %-10s %-18s\n" \
        "------" "------" "----" "---" "------" "----" "------"
    
    for client_spec in "${clients[@]}"; do
        IFS=':' read -r name user host port <<< "$client_spec"
        
        # Check status
        local status=$(check_client_status "$user" "$host" "$port")
        
        if [[ "$status" == "ONLINE" ]]; then
            # Get quick metrics (silent - no progress messages)
            local metrics=$(get_quick_metrics "$user" "$host" "$port")
            IFS='|' read -r cpu mem disk uptime <<< "$metrics"
            
            # Prepare status text (we'll color it in the echo)
            local status_text="ONLINE"
            
            # Determine memory color
            local mem_color=""
            if [[ "$mem" != "N/A"* ]] && [[ "$mem" =~ ^[0-9.]+% ]]; then
                local mem_num=${mem%\%}
                if (( $(echo "$mem_num > 90" | bc -l 2>/dev/null || echo 0) )); then
                    mem_color="$COLOR_RED"
                elif (( $(echo "$mem_num > 70" | bc -l 2>/dev/null || echo 0) )); then
                    mem_color="$COLOR_YELLOW"
                fi
            fi
            
            # Determine disk color
            local disk_color=""
            if [[ "$disk" != "N/A"* ]] && [[ "$disk" =~ ^[0-9.]+% ]]; then
                local disk_num=${disk%\%}
                if (( $(echo "$disk_num > 90" | bc -l 2>/dev/null || echo 0) )); then
                    disk_color="$COLOR_RED"
                elif (( $(echo "$disk_num > 70" | bc -l 2>/dev/null || echo 0) )); then
                    disk_color="$COLOR_YELLOW"
                fi
            fi
            
            # Truncate long uptime
            if [[ ${#uptime} -gt 16 ]]; then
                uptime="${uptime:0:16}.."
            fi
            
            # Print with colors using echo for proper interpretation
            printf "%-12s " "$name"
            echo -ne "${COLOR_GREEN}${status_text}${COLOR_RESET}    "
            printf "%-18s %-8s " "$host" "$cpu"
            echo -ne "${mem_color}${mem}${COLOR_RESET}      "
            echo -ne "${disk_color}${disk}${COLOR_RESET}        "
            echo "$uptime"
        else
            # Offline client
            printf "%-12s " "$name"
            echo -ne "${COLOR_RED}OFFLINE${COLOR_RESET}   "
            printf "%-18s %-8s %-10s %-10s %-18s\n" "$host" "-" "-" "-" "-"
        fi
    done
    
    echo ""
}

# Show metrics for specific client
show_client() {
    local target_name=$1
    local clients
    IFS=' ' read -ra clients <<< "$(read_clients)"
    
    for client_spec in "${clients[@]}"; do
        IFS=':' read -r name user host port <<< "$client_spec"
        
        if [[ "$name" == "$target_name" ]]; then
            display_client_metrics "$name" "$user" "$host" "$port"
            return 0
        fi
    done
    
    print_error "Client not found: $target_name"
    return 1
}

# Show help
show_help() {
    cat <<EOF

E.A.S.E.M Monitoring Dashboard

USAGE:
    ./easem-dashboard.sh [COMMAND] [OPTIONS]

COMMANDS:
    live                    Start live dashboard (auto-refresh)
    list                    List all clients with quick metrics summary
    show <client_name>      Show detailed metrics for specific client
    all                     Show all clients once (no refresh)
    help                    Show this help message

EXAMPLES:
    ./easem-dashboard.sh live              # Live auto-refreshing dashboard
    ./easem-dashboard.sh list              # Quick overview of all clients
    ./easem-dashboard.sh show laptop2      # Detailed view of laptop2
    ./easem-dashboard.sh all               # All clients detailed (one-time)

NOTES:
    - 'list' command shows quick metrics: CPU, Memory, Disk usage, and Uptime
    - Color coding: Green=Normal, Yellow=>70%, Red=>90%
    - 'show' command displays full detailed metrics for one client
    - 'live' refreshes every ${DASHBOARD_REFRESH_INTERVAL:-3} seconds

EOF
}

# Main execution
main() {
    local command=${1:-"help"}
    
    case "$command" in
        live)
            live_dashboard
            ;;
        list)
            list_clients
            ;;
        show)
            show_client "$2"
            ;;
        all)
            display_all_clients
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
