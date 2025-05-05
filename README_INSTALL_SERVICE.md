# ArduPilot Drone Simulator Systemd Service Installer

This repository contains a shell script (`install_drone_service.sh`) designed to automate the setup of a systemd service for running the ArduPilot SITL simulator on a Linux system.

The service (`drone_sim.service`) will be configured to:

*   Run the SITL process as the user `dronepilot` (using `sudo -u dronepilot`).
*   Automatically start on system boot.
*   Explicitly set up the necessary environment (PATH modifications, Python virtual environment activation) within the service command.
*   Execute `sim_vehicle.py` from its standard location (`~/ardupilot/Tools/autotest/sim_vehicle.py`), specifying the vehicle type (`-v ArduCopter`).
*   Run **without** automatically starting MAVProxy (`--no-mavproxy`). The SITL process itself will listen for connections.
*   Output SITL MAVLink data directly from the simulator process via UDP and TCP on the specified ports (`--out=udp:0.0.0.0:14550 --out tcp:0.0.0.0:5678`).
*   Restart automatically on failure.

**Note on Approach:** After significant troubleshooting, directly using systemd's `User=` and `Group=` directives, or relying solely on sourcing `.profile`, proved unreliable in this specific non-interactive context with `sim_vehicle.py`. The final script uses `sudo -u dronepilot` and embeds the necessary environment setup directly into the `ExecStart` command for maximum robustness.

## Prerequisites

1.  **Systemd:** Your Linux distribution must use systemd (most modern distributions like Ubuntu, Debian, Fedora, CentOS do).
2.  **`wget`:** The `wget` command-line utility must be installed. If not, install it (e.g., `sudo apt update && sudo apt install wget` on Debian/Ubuntu or `sudo yum install wget` on CentOS/Fedora).
3.  **`sudo`:** The `sudo` package must be installed and configured.
4.  **`bash`:** The `/bin/bash` shell must be available (standard on most systems).
5.  **`dronepilot` User:** The user `dronepilot` must exist on the system.
    ```bash
    # If the user doesn't exist, create it:
    sudo useradd -m -s /bin/bash dronepilot
    # Optionally add to groups if needed (e.g., dialout):
    # sudo usermod -aG dialout dronepilot
    ```
6.  **ArduPilot Source Code & Build Tools:** The `dronepilot` user must have:
    *   The ArduPilot source code checked out (default assumed path: `/home/dronepilot/ardupilot`).
    *   A Python virtual environment (default assumed path: `/home/dronepilot/venv-ardupilot`) set up using `Tools/environment_install/install-prereqs-ubuntu.sh` or equivalent, containing necessary Python dependencies (`mavproxy`, `empy`, etc.).
    *   Any required build tools installed (like `gcc-arm-none-eabi`, `ccache` if paths are set in the script). The script *assumes* locations like `/opt/gcc-arm-none-eabi...` and `/usr/lib/ccache` - **verify or modify paths near the top of `install_drone_service.sh` if your locations differ.**
7.  **Permissions:** The `dronepilot` user must have the necessary permissions to read/execute files in the specified directories (ardupilot source, venv, etc.).

## Installation Instructions

1.  **Review Script Configuration:** Before running, **open `install_drone_service.sh` (if downloaded) or review the script content** and verify the paths defined near the top (e.g., `USER_HOME`, `VENV_ACTIVATE`, `ARDUPILOT_DIR`, `GCC_ARM_PATH`, `CCACHE_PATH`) match your system setup. Adjust them if necessary.
2.  **Download the Script:** Open a terminal and use `wget` to download the installer script:
    ```bash
    wget https://raw.githubusercontent.com/PeterJBurke/CreateSITLenv/main/install_drone_service.sh
    # Ensure this URL points to the correct final version
    ```
3.  **Make Executable:** Make the downloaded script executable:
    ```bash
    chmod +x install_drone_service.sh
    ```
4.  **Run the Installer:** Execute the script using `sudo`:
    ```bash
    sudo ./install_drone_service.sh
    ```
    The script will:
    *   Check if run as root.
    *   Verify the `dronepilot` user exists.
    *   Perform basic checks for required directories/files.
    *   Create the systemd service file `/etc/systemd/system/drone_sim.service` with the explicit environment setup.
    *   Reload the systemd daemon.
    *   Enable the service (start on boot).
    *   Start the service immediately.
    *   Show the service status after a short delay.

## Verification

After running the script, check if the service is running correctly:

*   **Check Status:**
    ```bash
    sudo systemctl status drone_sim.service
    ```
    Look for `Active: active (running)`.

*   **Follow Logs:** View the service's logs, including the environment setup echoes:
    ```bash
    sudo journalctl -u drone_sim.service -f
    ```
    Press `Ctrl+C` to stop following. Look for the build completion and the `RiTW: Window access not found, logging to /tmp/ArduCopter.log` message, which indicates the SITL process started correctly in the background.

*   **Check SITL Log:** (Optional) Check the log file mentioned if needed for SITL-specific messages:
    ```bash
    sudo -u dronepilot tail -f /tmp/ArduCopter.log
    ```

*   **Connect with GCS:** Try connecting your Ground Control Station (like QGroundControl or Mission Planner) **directly** to `udp:0.0.0.0:14550` or `tcp:0.0.0.0:5678` (or `udp://<SERVER_IP>:14550`, `tcp://<SERVER_IP>:5678` if connecting remotely) on the machine running the service. MAVProxy is *not* started by this service.

## Managing the Service

Use standard `systemctl` commands to manage the service:

*   **Stop:**
    ```bash
    sudo systemctl stop drone_sim.service
    ```
*   **Start:**
    ```bash
    sudo systemctl start drone_sim.service
    ```
*   **Restart:**
    ```bash
    sudo systemctl restart drone_sim.service
    ```
*   **Disable (Prevent starting on boot):**
    ```bash
    sudo systemctl disable drone_sim.service
    ```
*   **Enable (Start on boot):**
    ```bash
    sudo systemctl enable drone_sim.service
    ```

## Troubleshooting

*   **Service Fails to Start:** Check `sudo journalctl -u drone_sim.service -e --no-pager`. Common causes based on this setup:
    *   Incorrect paths configured at the top of `install_drone_service.sh`.
    *   Missing Python virtual environment or dependencies (`empy`, etc.).
    *   Missing ArduPilot source code or `sim_vehicle.py` script.
    *   Permissions issues preventing `dronepilot` user from accessing files/directories.
    *   Build errors during the SITL compilation step (check the detailed journalctl logs).
*   **Cannot Connect with GCS:** Ensure no firewall is blocking ports 14550 (UDP) or 5678 (TCP) on the server. Double-check the service is `active (running)`.
