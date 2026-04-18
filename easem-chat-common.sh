# E.A.S.E.M Master Configuration File
# Edit this file to configure your monitoring setup

# Master Information
MASTER_NAME="master-control"
MASTER_USER="$(whoami)"

# Client List (format: name:user:host:port)
# Example: laptop1:username:192.168.1.10:22
# Add your clients below (one per line):
# client1:user:192.168.1.100:22
# client2:user:192.168.1.101:22

# SSH Configuration
SSH_KEY_PATH="$HOME/.ssh/id_rsa"
SSH_TIMEOUT=10
SSH_OPTIONS="-o ConnectTimeout=$SSH_TIMEOUT -o BatchMode=yes -o StrictHostKeyChecking=no"

# Monitoring Configuration
METRICS_REFRESH_INTERVAL=5  # seconds
DASHBOARD_REFRESH_INTERVAL=3  # seconds

# Chat Configuration
CHAT_REFRESH_INTERVAL=1  # seconds
CHAT_HISTORY_LINES=50

# Logging Configuration
LOG_RETENTION_DAYS=7
DEBUG_MODE=0  # Set to 1 for verbose logging

# Colors (for terminal display)
ENABLE_COLORS=1  # Set to 0 to disable colors
