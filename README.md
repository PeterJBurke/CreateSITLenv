# A simulated, virtual drone for testing and development

![ChatGPT Image May 25, 2025, 06_29_30 PM](https://github.com/user-attachments/assets/ebd03b9c-5a2b-4c81-a359-be0b43b8258f)

## What This Does

This installer automates the complete setup of an ArduPilot Software-In-The-Loop (SITL) environment on Linux. Here's what happens during installation:

1. **Downloads the ArduPilot Codebase**: Clones the official [ArduPilot GitHub repository](https://github.com/ArduPilot/ardupilot) to your local disk (`~/ardupilot`), including all necessary submodules for simulation.

2. **Sets Up the Build Environment**: Runs ArduPilot's `install-prereqs-ubuntu.sh` script (contained within the cloned repository) to automatically install all required dependencies, compilers, Python packages, and tools needed for building and running the simulator on Linux.

3. **Creates a Systemd Service**: Optionally installs a background service (`drone_sim`) that automatically starts on boot, giving you an always-on virtual drone that runs continuously as the `dronepilot` user.

4. **Opens Network Ports for Remote Access**: Configures the simulator to accept connections from any Ground Control Station (GCS) software anywhere in the world via:
   - **TCP Port 5678 & 6789**: For reliable connections from most GCS applications (QGroundControl, Mission Planner, etc.). Multiple ports allow simultaneous connections.
   - **UDP Port 14550**: For traditional MAVLink UDP connections

Once installed, your virtual drone is accessible remotely, making it perfect for cloud deployments, remote development, testing, and continuous integration pipelines.

## Features

- **Installs MAVProxy, SITL, and ArduCopter**  
  Build, run, and customize virtual drones yourself ([ArduPilot SITL setup guide](https://ardupilot.org/dev/docs/setting-up-sitl-on-linux.html)).
- **Creates a virtual drone in the cloud**  
  Installs a background service to automatically run on boot, for an always-on virtual drone accessible from anywhere on the internet.

## Usage & Connection

**Automatic Mode (Recommended):**
- After installation, the simulated drone runs as a service and can be connected to from any ground control station (GCS) software (e.g., Mission Planner, QGroundControl, MAVProxy).
- **Connect using:**
  - **TCP:** `tcp://<SERVER_IP>:5678` or `tcp://<SERVER_IP>:6789`
  - **UDP:** `udp://<SERVER_IP>:14550`
  - Replace `<SERVER_IP>` with your server's IP address.
  - Use TCP for most GCS software (e.g., QGroundControl, Mission Planner). Multiple TCP ports allow simultaneous connections from different GCS instances. Use UDP if your GCS or workflow prefers it.

**Manual Mode:**
- After installation, you can start the simulator manually as `dronepilot`:
  ```bash
  cd ~/ardupilot/ArduCopter
  sim_vehicle.py --console --map --osd --out=udp:127.0.0.1:14550 --custom-location=33.64586111,-117.84275,25,0
  ```
  (You may need to run `. ~/.profile` first)

---

## Prerequisites
- Linux (tested on Ubuntu 20.04/22.04/24.04 LTS)
- Root or sudo access to create the `dronepilot` user
- Git installed on your system

---

## Quick Start & Installation

### Step 1: Create the dronepilot User

First, as a user with sudo privileges (or root), create the dedicated `dronepilot` user:

```bash
sudo useradd -m -s /bin/bash dronepilot
sudo passwd dronepilot
sudo usermod -aG sudo dronepilot
```

### Step 2: Switch to dronepilot User

```bash
su - dronepilot
```

### Step 3: Clone and Run Installer

```bash
git clone https://github.com/PeterJBurke/CreateSITLenv.git
cd CreateSITLenv
bash install.sh
```

### Step 4: Choose Installation Mode

The installer will present a menu:
- **Manual (Option 1):** Installs dependencies, builds ArduPilot, sets up Python environment. You manually run SITL/MAVProxy as needed.
- **Full Install (Option 2 - Recommended):** Manual setup + systemd service (`drone_sim`) that runs a virtual drone automatically on boot.

After installation, follow the [Usage & Connection](#usage--connection) instructions above for connecting your GCS.

---

## Troubleshooting
- **"ERROR: This installer must be run as the 'dronepilot' user":** Make sure you created the `dronepilot` user and switched to it (`su - dronepilot`) before running the installer
- **Missing dependencies:** Rerun the installer
- **Service fails to start:** Check logs: `journalctl -u drone_sim`
- **GCS can't connect:** Ensure firewall allows UDP 14550/TCP 5678/TCP 6789
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
