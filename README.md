

# 🚀 E.A.S.E.M

## Enhanced Administration and System Environment Manager

A lightweight, real-time **distributed system monitoring and management platform** built using Bash scripting.

This project simulates real-world **DevOps and system administration tools** used for remote infrastructure management.

---

# 🎯 What It Does

E.A.S.E.M allows a central master system to monitor and control multiple Linux/WSL2 machines in real time.

---

## 📊 Core Features

* 📊 **Real-time Monitoring:** CPU, Memory, Disk, Network, Uptime tracking
* ⚡ **Remote Command Execution:** Run commands on multiple client machines
* 📦 **Package Management:** Install software remotely via master system
* 🔄 **Live Dashboard:** Auto-refreshing system metrics
* 💬 **Chat System:** Communication between master and clients
* 🔒 **Secure Communication:** SSH key-based authentication
* 🔁 **Auto-Reconnect:** Handles connection drops automatically

---

# 🎯 Project Impact

This project demonstrates how **real-world system administration and DevOps infrastructure** works in distributed environments.
It simulates centralized control over multiple machines using secure SSH communication.

---

# 🏗️ System Architecture

```id="0r3xk2"
Master Node (Controller)
        ↓
SSH Secure Connection
        ↓
Agent Nodes (Clients)
        ↓
System Metrics Collection + Execution
```

---

# 🚀 Quick Start

## 🖥️ Master (Control Station)

```bash id="e9k2pq"
cd ~/workspace/easem/master
./easem-master.sh init
```

---

## 💻 Client (Monitored Machine)

```bash id="k3m8ta"
cd ~/workspace/easem/agent
./easem-agent.sh init
sudo service ssh start
```

---

## 🔗 Connect System

```bash id="w7x9lf"
./easem-deploy.sh laptop2 username client_ip 22
./easem-dashboard.sh list
```

---

# 🎮 Usage Guide

```bash id="z2q8nm"
# View all clients
./easem-dashboard.sh list

# Live monitoring dashboard
./easem-dashboard.sh live

# Execute remote command
./easem-master.sh exec laptop2 "uptime"

# Install package remotely
./easem-master.sh install laptop2 htop

# Start chat session
./easem-chat.sh start laptop2

# Interactive system menu
./easem-master.sh menu
```

---

# 📁 Project Structure

```text id="x1v5pl"
easem/
├── master/     → Central control system scripts  
├── agent/      → Client-side monitoring scripts  
├── shared/     → Shared utilities and helpers  
└── docs/       → Full system documentation  
```

---

# ✨ Key Features Overview

| Feature                     | Status |
| --------------------------- | ------ |
| Real-time system monitoring | ✅      |
| Remote command execution    | ✅      |
| Package management          | ✅      |
| Live dashboard UI           | ✅      |
| Multi-client support        | ✅      |
| Chat system                 | ✅      |
| SSH security                | ✅      |
| Auto recovery               | ✅      |

---

# 🔧 Requirements

* WSL2 or Linux OS
* SSH server + client setup
* Same network connectivity
* Bash 4.0+

---

# 🧠 Skills Demonstrated

* Distributed system design
* Linux system administration
* Process + resource monitoring
* SSH-based secure communication
* Automation scripting
* DevOps-style architecture thinking

---

# 📝 Example Output

```text id="c8tq1d"
CLIENT       STATUS     HOST               CPU      MEMORY     DISK       UPTIME
------       ------     ----               ---      ------     ----       ------
laptop2      ONLINE    192.168.1.105      0.8%     13.7%      1%        2 hours
laptop3      ONLINE    192.168.1.110      2.1%     45.3%      12%       5 hours
server1      OFFLINE   192.168.1.50       -        -          -         -
```

---

# 🌍 Use Cases

* Server monitoring systems
* DevOps infrastructure management
* Educational OS & networking simulation
* Remote Linux system administration
* Distributed computing learning project

---

# 🤝 Contributing

This is an educational project designed to learn:

* System administration
* Bash automation
* Distributed system design

---

# 🚀 Author

Created by **Mahbubaa Lamia**
To demonstrate advanced Linux system automation, DevOps concepts, and distributed monitoring systems.

---

💡 **E.A.S.E.M — Making system administration smarter, simpler, and centralized.**

-
