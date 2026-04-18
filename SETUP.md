#!/bin/bash

#############################################
# E.A.S.E.M - Chat Common Functions
# Shared functions for chat feature
#############################################

# Source utilities
_CHAT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_CHAT_DIR/easem-utils.sh"

# Get chat file path
get_chat_file() {
    local master_name=$1
    local client_name=$2
    local chat_dir=${3:-"$_CHAT_DIR/../chat-data"}
    
    echo "$chat_dir/chat_${master_name}_${client_name}.log"
}

# Send chat message
send_message() {
    local chat_file=$1
    local sender=$2
    local message=$3
    
    # Sanitize message
    message=$(echo "$message" | sed 's/[;&|`]//g')
    
    # Append message with timestamp
    local timestamp
    timestamp=$(date '+%H:%M:%S')
    echo "[$timestamp] [$sender] $message" >> "$chat_file"
}

# Read chat messages
read_messages() {
    local chat_file=$1
    local lines=${2:-50}
    
    if file_exists "$chat_file"; then
        tail -n "$lines" "$chat_file"
    fi
}

# Get unread message count (simple implementation)
get_unread_count() {
    local chat_file=$1
    local last_read_file="${chat_file}.lastread"
    
    if ! file_exists "$chat_file"; then
        echo "0"
        return
    fi
    
    local total_lines
    total_lines=$(wc -l < "$chat_file" 2>/dev/null || echo "0")
    
    if file_exists "$last_read_file"; then
        local last_read
        last_read=$(cat "$last_read_file")
        echo $((total_lines - last_read))
    else
        echo "$total_lines"
    fi
}

# Mark messages as read
mark_as_read() {
    local chat_file=$1
    local last_read_file="${chat_file}.lastread"
    
    if file_exists "$chat_file"; then
        wc -l < "$chat_file" > "$last_read_file"
    fi
}

# Sync chat file to remote
sync_to_remote() {
    local local_file=$1
    local remote_user=$2
    local remote_host=$3
    local remote_path=$4
    local ssh_port=${5:-22}
    
    # Use rsync if available, otherwise scp
    if command_exists rsync; then
        rsync -az -e "ssh -p $ssh_port -o ConnectTimeout=5 -o BatchMode=yes" "$local_file" "$remote_user@$remote_host:$remote_path" 2>/dev/null
    else
        scp -P "$ssh_port" -o ConnectTimeout=5 -o BatchMode=yes "$local_file" "$remote_user@$remote_host:$remote_path" 2>/dev/null
    fi
}

# Sync chat file from remote
sync_from_remote() {
    local remote_user=$1
    local remote_host=$2
    local remote_path=$3
    local local_file=$4
    local ssh_port=${5:-22}
    
    # Use rsync if available, otherwise scp
    if command_exists rsync; then
        rsync -az -e "ssh -p $ssh_port -o ConnectTimeout=5 -o BatchMode=yes" "$remote_user@$remote_host:$remote_path" "$local_file" 2>/dev/null
    else
        scp -P "$ssh_port" -o ConnectTimeout=5 -o BatchMode=yes "$remote_user@$remote_host:$remote_path" "$local_file" 2>/dev/null
    fi
}

# Clear chat history
clear_chat() {
    local chat_file=$1
    
    if file_exists "$chat_file"; then
        > "$chat_file"
        print_success "Chat history cleared"
    fi
}

# Export functions
export -f get_chat_file
export -f send_message
export -f read_messages
export -f get_unread_count
export -f mark_as_read
export -f sync_to_remote
export -f sync_from_remote
export -f clear_chat
