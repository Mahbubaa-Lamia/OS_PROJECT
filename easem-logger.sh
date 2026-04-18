#!/bin/bash

# E.A.S.E.M Chat - Master Side (Working Version)
# Uses two-file system: incoming.log and outgoing.log

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SHARED_DIR="$SCRIPT_DIR/../shared"
CONFIG_FILE="$SCRIPT_DIR/config/easem-config.conf"
CLIENTS_FILE="$SCRIPT_DIR/config/clients.list"
CHAT_DIR="$SCRIPT_DIR/../chat-data"

source "$SHARED_DIR/easem-utils.sh"
source "$SHARED_DIR/easem-logger.sh"

if file_exists "$CONFIG_FILE"; then
    source "$CONFIG_FILE"
fi

ensure_dir "$CHAT_DIR"

get_client_info() {
    grep "^$1:" "$CLIENTS_FILE" | head -1
}

start_chat() {
    local client_name=$1
    local client_info=$(get_client_info "$client_name")
    
    if [[ -z "$client_info" ]]; then
        print_error "Client not found: $client_name"
        return 1
    fi
    
    IFS=':' read -r name user host port <<< "$client_info"
    
    # Local conversation log
    local local_log="$CHAT_DIR/${client_name}_conversation.log"
    
    # Remote files on client
    local remote_incoming="~/.easem/chat/incoming.log"
    local remote_outgoing="~/.easem/chat/outgoing.log"
    
    # Setup remote directory
    ssh -p "$port" "$user@$host" "mkdir -p ~/.easem/chat && touch ~/.easem/chat/incoming.log ~/.easem/chat/outgoing.log" 2>/dev/null
    
    touch "$local_log"
    
    echo ""
    echo "════════════════════════════════════════════════════════"
    echo "  Chat: $client_name @ $host"
    echo "════════════════════════════════════════════════════════"
    echo "  Commands: r=refresh, exit=quit"
    echo ""
    read -p "Press Enter to start..."
    
    while true; do
        # Pull new messages from client (their outgoing = our incoming)
        local new_msgs=$(ssh -p "$port" "$user@$host" "cat ~/.easem/chat/outgoing.log 2>/dev/null" 2>/dev/null)
        
        if [[ -n "$new_msgs" ]]; then
            echo "$new_msgs" >> "$local_log"
            # Clear their outgoing after reading
            ssh -p "$port" "$user@$host" "> ~/.easem/chat/outgoing.log" 2>/dev/null
        fi
        
        # Display conversation
        clear
        echo "════════════════════════════════════════════════════════"
        echo "  Chat: $client_name"
        echo "════════════════════════════════════════════════════════"
        echo ""
        
        if [[ -s "$local_log" ]]; then
            tail -n 25 "$local_log"
        else
            echo "  [No messages]"
        fi
        
        echo ""
        echo "────────────────────────────────────────────────────────"
        echo -n "You: "
        
        read -r msg
        
        case "$msg" in
            exit|quit|q)
                echo "Chat closed."
                break
                ;;
            r|refresh|"")
                continue
                ;;
            *)
                local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
                local formatted="[$timestamp] admin: $msg"
                
                # Send to client (write to their incoming)
                echo "$formatted" | ssh -p "$port" "$user@$host" "cat >> ~/.easem/chat/incoming.log" 2>/dev/null
                
                # Log locally
                echo "$formatted" >> "$local_log"
                ;;
        esac
    done
}

case "${1:-help}" in
    start)
        if [[ -z "$2" ]]; then
            print_error "Usage: $0 start <client_name>"
            exit 1
        fi
        start_chat "$2"
        ;;
    list)
        grep -v '^#' "$CLIENTS_FILE" | grep -v '^$' | cut -d':' -f1
        ;;
    *)
        echo "E.A.S.E.M Chat"
        echo "Usage: $0 start <client_name>"
        ;;
esac
