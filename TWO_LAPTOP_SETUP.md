# Two-Laptop Setup Guide

Complete step-by-step guide for setting up E.A.S.E.M on two laptops connected via WiFi.

---

## Prerequisites

- Two Windows laptops with WSL2 Ubuntu installed
- Both connected to the same WiFi network
- Project folder on Desktop of both laptops

---

## Setup Steps

### PHASE 1: Both Laptops - Initial Setup

**On Both Laptop 1 and Laptop 2:**

```bash
# Open WSL
wsl

# Install SSH server
sudo apt update
sudo apt install openssh-server -y

# Start SSH service
sudo service ssh start

# Copy project to WSL (replace YOUR_USERNAME)
cd ~/workspace
cp -r "/mnt/c/Users/YOUR_USERNAME/Desktop/easem" .
cd easem
```

---

### PHASE 2: Laptop 1 (Master) - Setup

```bash
# Initialize master
cd ~/workspace/easem/master
./easem-master.sh init

# Generate SSH key (if you don't have one)
ssh-keygen -t rsa -b 4096
# Press Enter for all prompts

# Check master status
./easem-master.sh status
```

---

### PHASE 3: Laptop 2 (Agent) - Setup

```bash
# Initialize agent
cd ~/workspace/easem/agent
./easem-agent.sh init

# Get your IP address (write this down!)
hostname -I
# Example output: 192.168.1.105

# Get your username (write this down!)
whoami
# Example output: reyad

# Verify SSH is running
sudo service ssh status

# Test agent collector
./easem-collector.sh
# Should show system metrics
```

---

### PHASE 4: Laptop 1 (Master) - Connect to Agent

**You need from Laptop 2:**
- Username (e.g., reyad)
- IP address (e.g., 192.168.1.105)

```bash
# Test network connection
ping 192.168.1.105
# Should see replies - Press Ctrl+C to stop

# Copy SSH key to Laptop 2
ssh-copy-id reyad@192.168.1.105
# Enter Laptop 2's password when prompted

# Test SSH connection
ssh reyad@192.168.1.105 "echo 'Connection works!'"
# Should print "Connection works!" without asking password

# Deploy agent to Laptop 2
cd ~/workspace/easem/master
./easem-deploy.sh laptop2 reyad 192.168.1.105 22

# Verify connection
./easem-dashboard.sh list
# Should show: laptop2    ONLINE    192.168.1.105
```

---

## Testing All Features

### 1. List Clients with Metrics
```bash
cd ~/workspace/easem/master
./easem-dashboard.sh list
```

Expected output:
```
CLIENT       STATUS     HOST               CPU      MEMORY     DISK       UPTIME
------       ------     ----               ---      ------     ----       ------
laptop2      ONLINE    192.168.1.105      0.5%     13.8%      1%        2 hours
```

### 2. Live Dashboard
```bash
./easem-dashboard.sh live
# Updates every 3 seconds
# Press Ctrl+C to exit
```

### 3. Execute Commands
```bash
./easem-master.sh exec laptop2 "uptime"
./easem-master.sh exec laptop2 "df -h"
./easem-master.sh exec laptop2 "free -h"
```

### 4. Install Package
```bash
./easem-master.sh install laptop2 htop
```

### 5. Chat Feature

**Terminal 1 - Master (Laptop 1):**
```bash
cd ~/workspace/easem/master
./easem-chat.sh start laptop2
# Type messages, press Enter
# Type 'r' to refresh
# Type 'exit' to quit
```

**Terminal 2 - Client (Laptop 2):**
```bash
cd ~/workspace/easem/agent
./easem-chat-client.sh start
# Type messages, press Enter
# Type 'r' to refresh
# Type 'exit' to quit
```

### 6. Interactive Menu
```bash
cd ~/workspace/easem/master
./easem-master.sh menu
```

---

## After Restart/Shutdown

When you restart your laptops or close WSL, follow these steps to reconnect:

### On Laptop 2 (Client) - Do This First
```bash
# Open WSL
wsl

# Start SSH service
sudo service ssh start

# Verify agent is ready
cd ~/workspace/easem/agent
./easem-agent.sh status
```

### On Laptop 1 (Master)
```bash
# Open WSL
wsl

# Check connection
cd ~/workspace/easem/master
./easem-dashboard.sh list
```

**That's it!** The SSH keys are already set up, so the connection should work automatically.

---

## Troubleshooting

### Problem: Can't Ping Between Laptops
**Solution:**
- Verify both are on the same WiFi
- Use WSL IP address, not Windows IP
- Check Windows Firewall settings

### Problem: SSH Connection Refused
**Solution:**
```bash
# On Laptop 2
sudo service ssh start
sudo service ssh status
```

### Problem: Client Shows OFFLINE
**Solution:**
```bash
# On Laptop 1
ssh reyad@192.168.1.105 "echo test"
# If this works, the issue is in clients.list

# Check clients.list format
cat master/config/clients.list
# Should be: laptop2:reyad:192.168.1.105:22
```

### Problem: Permission Denied (SSH)
**Solution:**
```bash
# On Laptop 1
ssh-copy-id reyad@192.168.1.105
# Re-enter password

# Test again
ssh reyad@192.168.1.105 "echo OK"
```

### Problem: Metrics Not Showing
**Solution:**
```bash
# On Laptop 2
cd ~/workspace/easem/agent
./easem-collector.sh
# Should show metrics

# If not working, check if scripts are executable
chmod +x *.sh ../shared/*.sh
```

### Problem: Chat Not Syncing
**Solution:**
```bash
# Clear old chat files
rm ~/workspace/easem/chat-data/*.log

# On Laptop 2 also
ssh reyad@192.168.1.105 "rm ~/workspace/easem/chat-data/*.log"

# Start fresh chat
./easem-chat.sh start laptop2
```

---

## Pre-Demo Checklist

Before demonstrating your project:

- [ ] Both laptops charged
- [ ] Both on same WiFi
- [ ] SSH service running on Laptop 2
- [ ] Dashboard shows laptop2 ONLINE
- [ ] Can execute test command
- [ ] Live dashboard works
- [ ] Chat tested and working
- [ ] Know all commands

---

## Demo Flow (10-12 minutes)

1. **Introduction** (1 min)
   - Explain E.A.S.E.M purpose
   - Show two laptops connected

2. **Show Connection** (2 min)
   ```bash
   ./easem-dashboard.sh list
   ```

3. **Live Monitoring** (2 min)
   ```bash
   ./easem-dashboard.sh live
   ```

4. **Remote Commands** (2 min)
   ```bash
   ./easem-master.sh exec laptop2 "uptime"
   ./easem-master.sh exec laptop2 "df -h"
   ./easem-master.sh install laptop2 neofetch
   ./easem-master.sh exec laptop2 "neofetch"
   ```

5. **Chat Demo** (3 min)
   - Open on both laptops
   - Send messages
   - Show refresh

6. **Wrap Up** (2 min)
   - Show logs
   - Explain security
   - Q&A

---

## Quick Reference

### Essential Commands

**Master:**
```bash
./easem-master.sh menu              # Interactive menu
./easem-dashboard.sh list           # Quick overview
./easem-dashboard.sh live           # Live monitoring
./easem-master.sh exec laptop2 CMD  # Execute command
./easem-chat.sh start laptop2       # Start chat
./easem-master.sh remove laptop2    # Remove client
```

**Agent:**
```bash
./easem-agent.sh status             # Check status
./easem-agent.sh metrics            # Show metrics
./easem-chat-client.sh start        # Start chat
```

### IP and Credentials

For this guide, example values used:
- **Laptop 2 Username:** reyad
- **Laptop 2 IP:** 192.168.1.105
- **Laptop 2 Password:** 1234
- **SSH Port:** 22

Replace with your actual values!

---

## Success Criteria

Your setup is successful when:
- ✅ Dashboard shows client ONLINE
- ✅ Can execute commands remotely
- ✅ Live monitoring displays metrics
- ✅ Can install packages
- ✅ Chat works both directions
- ✅ Survives restart (just need to start SSH)

---

**You're ready to demonstrate!** 🎉
