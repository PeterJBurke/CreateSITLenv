# CreateSITLenv: ArduPilot SITL & MAVProxy Installer

## Use Instructions

**Automatic Mode:**
- Once installed and running as a service, the simulated drone can be connected to from any ground control station (GCS) software, such as Mission Planner or QGroundControl.
- Use the IP address of the server and port **5678** to connect:
  - **TCP:** `tcp://IPADDRESSOFSERVER:5678`
- Replace `IPADDRESSOFSERVER` with the actual IP address of your server.
- Example GCS: Mission Planner, QGroundControl, MAVProxy, etc.

> **Important:** Do **not** run these scripts as the `root` user. Only use `sudo` when prompted by the scripts for specific actions (such as installing packages or enabling the systemd service). Always run the scripts from a regular user account (e.g., `dronepilot` or your own username).

**CreateSITLenv** enables:
1. **Manual installation and use** of MAVProxy, SITL, and ArduCopter (build, run, customize virtual drones yourself)
   ([ArduPilot SITL setup guide](https://ardupilot.org/dev/docs/setting-up-sitl-on-linux.html))
2. **Automated setup of a systemd service** to run a virtual drone (ArduPilot SITL + MAVProxy) on boot

---

## Features
- Installs all dependencies for ArduPilot SITL, MAVProxy, and build tools
- Optionally sets up a systemd service for automatic virtual drone startup
- Supports both manual and automated workflows
- Easy, interactive installer (`install.sh`)

---


## Quick Start

```bash
git clone https://github.com/PeterJBurke/CreateSITLenv.git
cd CreateSITLenv
bash install.sh
```

---

## Installation Options

### 1. Manual Install (for advanced/custom users)
- Installs dependencies
- Clones and builds ArduPilot
- Sets up Python environment
- You manually run SITL, MAVProxy, or compile as needed

### 2. Full Install (auto-service)
- Everything from manual install
- PLUS: Installs and enables a systemd service (`drone_sim`) that runs a virtual drone automatically on boot, as user `dronepilot`

---

## Usage

### Manual Workflow
After install, as `dronepilot`:
```bash
cd ~/ardupilot/ArduCopter
sim_vehicle.py --console --map --osd --out=udp:127.0.0.1:14550 --custom-location=33.64586111,-117.84275,25,0
```
(You may need to run `. ~/.profile` first)

### Service Workflow
- The `drone_sim` service starts a virtual drone at boot
- To manage:
    - `sudo systemctl status drone_sim`
    - `sudo systemctl start drone_sim`
    - `sudo systemctl stop drone_sim`
    - `sudo systemctl restart drone_sim`
    - `sudo systemctl enable drone_sim`
- Connect your GCS (QGroundControl, etc) to:
    - UDP: `udp://<SERVER_IP>:14550`
    - TCP: `tcp://<SERVER_IP>:5678`

---

## Prerequisites
- Linux (tested on Ubuntu 20.04/22.04/24.04 LTS)
- An account that is not root (required for both manual and automatic installation)
- A dedicated user account (e.g., `dronepilot`)—see below

---

## Creating a Dedicated User Account

To run the SITL/MAVProxy service, you must use a dedicated non-root user (e.g., `dronepilot`) that is a member of the `sudo` group.

**To create a new user from the root account or with sudo:**

```bash
sudo useradd -m -s /bin/bash dronepilot
```
- `-m` creates a home directory (recommended)
- `-s /bin/bash` sets the default shell to bash

**Set a password for the new user:**
```bash
sudo passwd dronepilot
```
- You will be prompted to enter and confirm the password for the new account

**Add the user to the sudo group (required):**
```bash
sudo usermod -aG sudo dronepilot
```
- After running this command, log out and log back in as `dronepilot` for the change to take effect.
- This grants the user administrative rights needed for installation and service management.

If you want to use a different username, substitute it for `dronepilot` throughout the instructions and scripts.

---

## Troubleshooting
- **Missing dependencies:** Rerun the installer
- **Service fails to start:** Check logs: `journalctl -u drone_sim`
- **GCS can't connect:** Ensure firewall allows UDP 14550/TCP 5678
- **Manual run errors:** Ensure `. ~/.profile` is sourced and you are in the correct directory

---

## Advanced/Customization
- Edit the systemd service template in `install_drone_service.sh` for custom ports, locations, or vehicle types
- See ArduPilot and MAVProxy docs for more advanced options

---

## References
- [ArduPilot SITL Setup](https://ardupilot.org/dev/docs/setting-up-sitl-on-linux.html)
- [MAVProxy Quickstart](https://ardupilot.org/mavproxy/docs/getting_started/quickstart.html)

---

## License
MIT

---

## Changelog
- v1.0: Initial release with combined installer and unified documentation
