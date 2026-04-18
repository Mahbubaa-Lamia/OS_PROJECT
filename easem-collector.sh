#!/bin/bash

# E.A.S.E.M Chat Client (Working Version)
# Uses two-file system: incoming.log and outgoing.log

CHAT_DIR="$HOME/.easem/chat"
INCOMING="$CHAT_DIR/incoming.log"
OUTGOING="$CHAT_DIR/outgoing.log"
CONVERSATION="$CHAT_DIR/conversation.log"

# Setup
mkdir -p "$CHAT_DIR"
touch "$INCOMING" "$OUTGOING" "$CONVERSATION"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo ""
echo "════════════════════════════════════════════════════════"
echo "  E.A.S.E.M Chat Client"
echo "════════════════════════════════════════════════════════"
echo "  Commands: r=refresh, exit=quit"
echo ""
read -p "Press Enter to start..."

while true; do
    # Merge incoming (admin messages) into conversation
    if [[ -s "$INCOMING" ]]; then
        cat "$INCOMING" >> "$CONVERSATION"
        > "$INCOMING"  # Clear after merging
    fi
    
    clear
    echo "════════════════════════════════════════════════════════"
    echo "  Chat with Admin"
    echo "════════════════════════════════════════════════════════"
    echo ""
    
    # Show full conversation (both sides)
    if [[ -s "$CONVERSATION" ]]; then
        tail -n 25 "$CONVERSATION"
    else
        echo "  [No messages]"
    fi
    
    echo ""
    echo "────────────────────────────────────────────────────────"
    echo -n "You: "
    
    read -t 0.1 -r msg 2>/dev/null || read -r msg
    
    case "$msg" in
        exit|quit|q)
            echo "Chat closed."
            break
            ;;
        r|refresh|"")
            continue
            ;;
        *)
            timestamp=$(date '+%Y-%m-%d %H:%M:%S')
            formatted="[$timestamp] client: $msg"
            
            # Add to outgoing (for master to read)
            echo "$formatted" >> "$OUTGOING"
            
            # Also add to local conversation (so we see it)
            echo "$formatted" >> "$CONVERSATION"
            
            echo -e "${GREEN}Sent!${NC}"
            sleep 0.5
            ;;
    esac
done
