# ZEUS Edge Solution
<img width="229" height="172" alt="Screenshot 2025-12-25 124023" src="https://github.com/user-attachments/assets/4e5c31ae-f2ae-4731-8c9b-516ec4874c81" />

## Description
**ZEUS** is a comprehensive, all-in-one edge computing and infrastructure management solution. Designed for reliability and ease of use, ZEUS integrates high-performance virtualization, robust high-availability clustering, and real-time monitoring into a single, cohesive platform. It transforms standard hardware into a powerful edge node capable of running critical workloads with enterprise-grade resilience.
Whether you are managing a single edge server or a distributed cluster, ZEUS provides the tools you need to deploy, monitor, and maintain your infrastructure efficiently.
## Features
### 🖥️ [Virtualization Management (kimchi & Wok) ↗](http://10.51.241.195:3002/#virtualization)
*   **Web-Based Administration**: Manage KVM guests directly from your browser using an HTML5 interface.
*   **Resource Control**: Create, start, stop, and migrate virtual machines with ease.
*   **Storage & Network**: Configure storage pools and network bridges effortlessly.
*   **Custom UI**: Enhanced user experience with a polished, modern interface.
### ⚡ [High Availability Clustering (ClusterLabs)↗](http://10.51.241.195:3002/#clusterlabs)
*   **Pacemaker & Corosync**: Industry-standard clustering stack for maximum uptime.
*   **Automated Failover**: Ensure your critical services remain available even if a node fails.
*   **PCS Integration**: Simplified cluster configuration using the Pacemaker Configuration System.
### 📊 [Real-Time Monitoring (Performa)↗](http://10.51.241.195:3002/#performa)
*   **Granular Metrics**: Track CPU, memory, I/O, and network usage in real-time.
*   **Web Dashboard**: Visualize performance data through interactive charts and graphs.
*   **Satellite Agent**: Lightweight node agent (`performa-satellite`) efficient data collection.
### ⌨️ [Web Terminal (Wetty)↗](http://10.51.241.195:3002/#wetty)
*   **Access Anywhere**: Full terminal access to your host via HTTP/HTTPS.
*   **Secure**: Operates over SSH for secure remote management without needing a dedicated SSH client.

  ## ZEUS Prerequisites (Quick Reference)

### Hardware
- 64-bit x86 CPU with **Intel VT-x / AMD-V**
- **8 GB RAM** minimum (16 GB+ recommended)
- **100 GB SSD** minimum (NVMe preferred)
- **1 Gbps network** (static IP recommended)
- Virtualization enabled in BIOS

### Cluster (Recommended)
- **2–3 nodes** minimum for high availability
- **32 GB RAM** per node for production
- Dual NICs (management + cluster traffic)

### Software
- **Ubuntu 24.04 LTS** (fresh install recommended)
- **KVM / QEMU / Libvirt**
- **Wok & Kimchi** (VM management)
- **Pacemaker & Corosync** (HA clustering)
- **Performa (Node.js)** for monitoring
- **Wetty + OpenSSH** for web terminal
- **Git, Python 3, systemd**

### Network
- Required open ports:
  - `8001` – VM Management (Wok/Kimchi)
  - `3000` – Web Terminal (Wetty)
  - `5405` – Corosync (UDP)
  - `2224` – PCS

 ## [Architecture↗](http://10.51.241.195:3002/#architecture)
The following diagram illustrates the high-level architecture of a ZEUS node:
<img width="1919" height="1042" alt="image" src="https://github.com/user-attachments/assets/a120d2bb-3728-4003-9082-1369c4eadfa3" />

## Advantages
*   **Unified Platform**: No need to stitch together disparate tools; ZEUS brings them all together.
*   **Edge-Ready**: Optimized for Ubuntu 24.04 LTS, ensuring compatibility with modern hardware standard in edge deployments.
*   **Open Source Foundation**: Built on battle-tested open-source technologies (KVM, Libvirt, Linux).
*   **Lightweight**: Designed to run efficiently on edge hardware with limited resources.
  

## Core Technology Stack
| Component | Technology | Role |
| :--- | :--- | :--- |
| **OS** | Ubuntu 24.04 LTS | Base Operating System |
| **Virtualization** | KVM / Libvirt | Hypervisor & API |
| **Management UI** | Wok (Python/CherryPy) | Web Server & Plugin Framework |
| **Frontend** | HTML5 / JavaScript | User Interface |
| **Clustering** | Pacemaker / Corosync | High Availability |
| **Monitoring** | Node.js (Performa) | Metrics Collection & Visualization |
| **Terminal** | Node.js (Wetty) / SSH | Remote Access |

## Comparisons: ZEUS vs. Traditional Edge setups
| Feature | ZEUS Edge Solution | Traditional Manual Setup |
| :--- | :--- | :--- |
| **Setup Time** | Minutes (Automated Scripts) | Hours/Days |
| **UI Experience** | Unified Web Dashboard | Multiple CLI/Web Interfaces |
| **Monitoring** | Integrated Real-time | External Tools Required |
| **Clustering** | Pre-configured HA Stack | Manual Configuration Complex |
| **Maintenance** | Single Package Management | Dependency Helper needed |
## Installation Guide
### Prerequisites
*   **OS**: Ubuntu 20.04 + LTS (Fresh Install recommended)
*   **User**: Root privileges (sudo)
*   **Hardware**: Virtualization-enabled CPU (VT-x or AMD-V)
### Steps
1.  **Clone the Repository**
    ```bash
    git clone https://github.com/sushrut-bhokre/Edge-Computing
    cd Edge-Computing
    ```
2.  **Run the Installer**
    The main installer orchestrates the setup of Wok, performa, wetty, and Cluster components.
    ```bash
    sudo chmod +x install.sh
    sudo ./install.sh
    ```
3.  **Access the Dashboard**
    *   **URL**: `https://10.51.241.195:3001`
    *   **Login**: Use your email to login.
4.  **Configuration check**
    *   **CLuster**: Ensure `pcsd service` is running (`sudo systemctl status pcsd`)
    *   **Monitoring**: Ensure `performa-satellite` is running (managed via cron/systemd).
    *   **Terminal**: Access Wetty at `http://<YOUR-NODE-IP>:3000/wetty` (default port).
    *   **VM Manager**: Access VMs from your broswer at `https://<YOUR-NODE-IP>:8001`
      
     **Note**: Your pc will restart after the installation.

## Documentation
For more detailed documentation, please visit our [docs](http://10.51.241.195:3002).
*   [Wok Documentation](https://github.com/kimchi-project/wok)
*   [Kimchi Documentation](https://github.com/kimchi-project/kimchi)
*   [ClusterLabs Info](https://clusterlabs.org/)
## Summary
ZEUS represents a leap forward for accessible edge infrastructure. By combining the power of KVM virtualization with the resilience of Pacemaker clustering and the visibility of Performa monitoring, it empowers administrators to deploy and maintain robust systems with minimal friction.
## Rights & License
This project is licensed under the **MIT License**.
*   **Wok/Kimchi**: LGPL v2.1 (Apache 2.0 for some components)
*   **Performa**: MIT License
*   **Wetty**: MIT License
All third-party components (Libvirt, QEMU, etc.) retain their respective licenses.
