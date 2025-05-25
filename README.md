# CreateSITLenv: ArduPilot SITL & MAVProxy Installer

**CreateSITLenv** enables:
1. **Manual installation and use** of MAVProxy, SITL, and ArduCopter (build, run, customize virtual drones yourself)
2. **Automated setup of a systemd service** to run a virtual drone (ArduPilot SITL + MAVProxy) on boot

---

## Features
- Installs all dependencies for ArduPilot SITL, MAVProxy, and build tools
- Optionally sets up a `dronepilot` user and a systemd service for automatic virtual drone startup
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
- Linux with systemd
- `sudo` and `bash` installed
- If using service: `dronepilot` user (installer will create if missing)

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
