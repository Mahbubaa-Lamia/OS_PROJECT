# Testing Guide

Guide for testing E.A.S.E.M functionality when **no client devices are available**.

---

## Purpose

This guide is for testing the system using only **one computer** (localhost as both master and client).

**Note:** For actual deployment with two laptops, see **[TWO_LAPTOP_SETUP.md](TWO_LAPTOP_SETUP.md)**

---

## Setup for Testing

### 1. Ensure SSH is Running
```bash
sudo service ssh start
sudo service ssh status
```

### 2. Add Localhost as Client
```bash
cd ~/workspace/easem/master
echo "localhost:$(whoami):127.0.0.1:22" >> config/clients.list
```

### 3. Copy SSH Key to Localhost
```bash
ssh-copy-id $(whoami)@127.0.0.1
# Enter your password
```

### 4. Test Connection
```bash
ssh $(whoami)@127.0.0.1 "echo 'Connection works!'"
```

---

## Test All Features

### 1. Dashboard
```bash
cd ~/workspace/easem/master
./easem-dashboard.sh list
```

**Expected:** Shows localhost as ONLINE with metrics

### 2. Live Monitoring
```bash
./easem-dashboard.sh live
# Press Ctrl+C to exit
```

**Expected:** Auto-refreshing display every 3 seconds

### 3. Remote Command
```bash
./easem-master.sh exec localhost "uptime"
./easem-master.sh exec localhost "df -h"
```

**Expected:** Command output displayed

### 4. Package Installation
```bash
./easem-master.sh install localhost htop
```

**Expected:** Package installed (or already installed message)

### 5. Chat System

**Terminal 1 - Master:**
```bash
cd ~/workspace/easem/master
./easem-chat.sh start localhost
```

**Terminal 2 - Client:**
```bash
cd ~/workspace/easem/agent
./easem-chat-client.sh
```

**Test:**
- Type messages on both sides
- Press Enter (empty) to refresh
- Type 'exit' to quit

### 6. Interactive Menu
```bash
./easem-master.sh menu
```

**Test:** Try all menu options

---

## Verification Checklist

- [ ] Dashboard shows localhost ONLINE
- [ ] Live monitoring displays and updates
- [ ] Commands execute successfully
- [ ] Package installation works
- [ ] Chat messages sync
- [ ] Menu options functional
- [ ] Remove client works
- [ ] Status command shows correct info

---

## Cleanup After Testing

Remove localhost from clients:
```bash
cd ~/workspace/easem/master
./easem-master.sh remove localhost
```

---

## Limitations of Localhost Testing

**What works:**
- ✅ All commands
- ✅ Monitoring
- ✅ Chat
- ✅ Package installation

**What's different from real deployment:**
- Network latency is zero
- All processes run on same machine
- SSH is local, not remote
- Can't test actual network issues

---

## Next Steps

After testing successfully:
1. Remove localhost from clients.list
2. Deploy to actual client devices
3. Follow **[TWO_LAPTOP_SETUP.md](TWO_LAPTOP_SETUP.md)**

---

**Testing complete? Now deploy to real devices!** 🚀
