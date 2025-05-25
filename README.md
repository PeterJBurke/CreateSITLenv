# A simulated, virtual drone for testing and development

## Features

- **Manual installation and use of MAVProxy, SITL, and ArduCopter**  
  Build, run, and customize virtual drones yourself ([ArduPilot SITL setup guide](https://ardupilot.org/dev/docs/setting-up-sitl-on-linux.html)).
- **Automated setup of a systemd service**  
  Runs a virtual drone (ArduPilot SITL + MAVProxy) automatically on boot as a background service.

## Usage & Connection

**Automatic Mode (Recommended):**
- After installation, the simulated drone runs as a service and can be connected to from any ground control station (GCS) software (e.g., Mission Planner, QGroundControl, MAVProxy).
- **Connect using:**
  - **TCP:** `tcp://<SERVER_IP>:5678`
  - **UDP:** `udp://<SERVER_IP>:14550`
  - Replace `<SERVER_IP>` with your server's IP address.
  - Use TCP for most GCS software (e.g., QGroundControl, Mission Planner). Use UDP if your GCS or workflow prefers it.

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
- An account that is not root (required for both manual and automatic installation)
- A dedicated user account (e.g., `dronepilot`)—see below

---

## Quick Start & Installation

1. **Clone and Run Installer**
    ```bash
    git clone https://github.com/PeterJBurke/CreateSITLenv.git
    cd CreateSITLenv
    bash install.sh
    ```
2. **Choose Installation Mode:**
    - **Automatic (Recommended):** Installs dependencies, builds ArduPilot, sets up Python environment, and enables a systemd service (`drone_sim`) that runs a virtual drone automatically on boot as user `dronepilot`.
    - **Manual:** Installs dependencies, builds ArduPilot, sets up Python environment, but you manually run SITL/MAVProxy as needed.

After installation, follow the [Use Instructions](#use-instructions) above for connecting your GCS.

---

## Creating a Dedicated User Account

To run the SITL/MAVProxy service, you must use a dedicated non-root user (e.g., `dronepilot`) that is a member of the `sudo` group.

```bash
sudo useradd -m -s /bin/bash dronepilot
sudo passwd dronepilot
sudo usermod -aG sudo dronepilot
```
- Log out and back in as `dronepilot` for changes to take effect.
- Substitute your preferred username as needed.

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
