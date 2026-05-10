# E.A.S.E.M

**Enhanced Administration and System Environment Manager**

A lightweight, real-time remote monitoring and management system built with Bash.

---

## 🎯 What It Does

Monitor and control multiple Linux/WSL2 computers from one central master station:

- **📊 Real-time Monitoring** - CPU, Memory, Disk, Network, Uptime
- **⚡ Remote Commands** - Execute commands on any client
- **📦 Package Management** - Install software remotely
- **🔄 Live Dashboard** - Auto-refreshing metrics
- **💬 Chat System** - Communicate with clients
- **🔒 Secure** - SSH key authentication

---

## 🚀 Quick Start

### Master (Control Station)
```bash
cd ~/workspace/easem/master
./easem-master.sh init
```

### Client (Monitored PC)
```bash
cd ~/workspace/easem/agent
./easem-agent.sh init
sudo service ssh start
```

### Connect Them
```bash
# On Master
./easem-deploy.sh laptop2 username client_ip 22
./easem-dashboard.sh list
```

---

## 📖 Documentation

- **[SETUP.md](SETUP.md)** - Installation and configuration
- **[TWO_LAPTOP_SETUP.md](TWO_LAPTOP_SETUP.md)** - Complete two-device guide
- **[TESTING_GUIDE.md](TESTING_GUIDE.md)** - Testing without clients

---

## 🎮 Usage

```bash
# Monitor all clients
./easem-dashboard.sh list

# Live monitoring
./easem-dashboard.sh live

# Execute command
./easem-master.sh exec laptop2 "uptime"

# Install package
./easem-master.sh install laptop2 htop

# Chat
./easem-chat.sh start laptop2

# Interactive menu
./easem-master.sh menu
```

---

## 📁 Project Structure

```
easem/
├── master/          # Control station scripts
├── agent/           # Client scripts
├── shared/          # Shared utilities
└── docs/            # Documentation
```

---

## ✨ Features

| Feature | Status |
|---------|--------|
| Real-time monitoring | ✅ |
| Remote command execution | ✅ |
| Package installation | ✅ |
| Live dashboard | ✅ |
| Client management | ✅ |
| Chat system | ✅ |
| Auto-reconnect | ✅ |
| Secure (SSH keys) | ✅ |

---

## 🔧 Requirements

- WSL2 Ubuntu (or native Linux)
- SSH (client and server)
- Same network connection
- Bash 4.0+

---

## 📝 Example Output

```
CLIENT       STATUS     HOST               CPU      MEMORY     DISK       UPTIME
------       ------     ----               ---      ------     ----       ------
laptop2      ONLINE    192.168.1.105      0.8%     13.7%      1%        2 hours
laptop3      ONLINE    192.168.1.110      2.1%     45.3%      12%       5 hours
server1      OFFLINE   192.168.1.50       -        -          -         -
```

---

## 🤝 Contributing

Educational project - built for learning system administration with Bash.

---
**E.A.S.E.M** - Making remote system administration easier! 🚀

