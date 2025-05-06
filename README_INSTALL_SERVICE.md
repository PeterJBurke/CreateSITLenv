# ArduPilot Drone Simulator Systemd Service Installer

This repository contains a shell script (`install_drone_service.sh`) designed to automate the setup of a systemd service for running the ArduPilot SITL simulator and MAVProxy on a Linux system.

**Key Changes in this Version:**

*   **MAVProxy Included:** This version uses `sim_vehicle.py` to launch both the SITL simulator and MAVProxy.
*   **MAVProxy Daemon Mode:** It leverages the `--mavproxy-args="--daemon"` flag to instruct MAVProxy to run as a background daemon, which is more suitable for a systemd service environment.
*   **TCP Input:** The TCP output is configured as `tcpin:0.0.0.0:5678`, meaning MAVProxy will *listen* for incoming TCP connections from a GCS on port 5678.

The service (`drone_sim.service`) will be configured to:

*   Run the main process as the user `dronepilot` (using `sudo -u dronepilot`).
*   Automatically start on system boot.
*   Explicitly set up the necessary environment (PATH modifications, Python virtual environment activation) within the service command.
*   Execute `sim_vehicle.py` from its standard location (`~/ardupilot/Tools/autotest/sim_vehicle.py`), specifying the vehicle type (`-v ArduCopter`).
*   Instruct MAVProxy (via `sim_vehicle.py`) to run in daemon mode.
*   Output MAVLink data via MAVProxy:
    *   Broadcasting via UDP on port 14550 (`udp:0.0.0.0:14550`).
    *   Listening for incoming TCP connections on port 5678 (`tcpin:0.0.0.0:5678`).
*   Restart automatically on failure.

## Prerequisites

1.  **Systemd:** Your Linux distribution must use systemd.
2.  **`wget`:** Must be installed (`sudo apt install wget` or `sudo yum install wget`).
3.  **`sudo`:** Must be installed and configured.
4.  **`bash`:** Must be available at `/bin/bash`.
5.  **`dronepilot` User:** The user `dronepilot` must exist on the system.
    ```bash
    # If the user doesn't exist, create it:
    sudo useradd -m -s /bin/bash dronepilot
    # Optionally add to groups if needed (e.g., dialout):
    # sudo usermod -aG dialout dronepilot
    ```
6.  **ArduPilot Source Code & Build Tools:** The `dronepilot` user must have:
    *   The ArduPilot source code checked out (default assumed path: `/home/dronepilot/ardupilot`).
    *   A Python virtual environment (default assumed path: `/home/dronepilot/venv-ardupilot`) set up using `Tools/environment_install/install-prereqs-ubuntu.sh` or equivalent, containing necessary Python dependencies (`mavproxy`, `empy`, etc.). Ensure `mavproxy.py` is executable and findable within the activated venv's PATH.
    *   Any required build tools installed (like `gcc-arm-none-eabi`, `ccache` if paths are set in the script). Verify paths near the top of `install_drone_service.sh`.
7.  **Permissions:** The `dronepilot` user must have permissions to read/execute files in the specified directories.

## Installation Instructions

1.  **Review Script Configuration:** Before running, **open `install_drone_service.sh` (if downloaded) or review the script content** and verify the paths defined near the top (e.g., `USER_HOME`, `VENV_ACTIVATE`, `ARDUPILOT_DIR`, `GCC_ARM_PATH`, `CCACHE_PATH`) match your system setup. Adjust them if necessary.
2.  **Download the Script:** Open a terminal and use `wget` to download the installer script:
    ```bash
    wget https://raw.githubusercontent.com/PeterJBurke/CreateSITLenv/main/install_drone_service.sh
    # Ensure this URL points to the correct final version
    ```
3.  **Make Executable:**
    ```bash
    chmod +x install_drone_service.sh
    ```
4.  **Run the Installer:** Execute the script using `sudo`:
    ```bash
    sudo ./install_drone_service.sh
    ```
    The script will perform checks, create the systemd service file (`/etc/systemd/system/drone_sim.service`), reload systemd, enable the service, start it, and show the status.

## Verification

After running the script, check if the service is running correctly:

*   **Check Status:**
    ```bash
    sudo systemctl status drone_sim.service
    ```
    Look for `Active: active (running)`. You should see `sim_vehicle.py` and potentially `mavproxy.py` processes listed under the CGroup tasks (MAVProxy might detach fully depending on the daemon implementation).

*   **Follow Logs:** View the service's logs:
    ```bash
    sudo journalctl -u drone_sim.service -f
    ```
    Look for the build completion and successful launch messages. You might see MAVProxy-specific startup messages here as well.

*   **Check SITL Log:** (Optional) Check the SITL binary's direct log file:
    ```bash
    sudo -u dronepilot tail -f /tmp/ArduCopter.log
    ```

*   **Connect with GCS:** Try connecting your Ground Control Station (like QGroundControl or Mission Planner) to the MAVProxy outputs:
    *   **UDP:** Connect to `udp:0.0.0.0:14550` (or `udp://<SERVER_IP>:14550` if connecting remotely).
    *   **TCP:** Configure your GCS to make an *outgoing* TCP connection to `tcp:0.0.0.0:5678` (or `tcp://<SERVER_IP>:5678` if connecting remotely). MAVProxy is *listening* on this port.

## Managing the Service

Use standard `systemctl` commands:

*   **Stop:** `sudo systemctl stop drone_sim.service`
*   **Start:** `sudo systemctl start drone_sim.service`
*   **Restart:** `sudo systemctl restart drone_sim.service`
*   **Disable:** `sudo systemctl disable drone_sim.service`
*   **Enable:** `sudo systemctl enable drone_sim.service`

## Troubleshooting

*   **Service Fails to Start:** Check `sudo journalctl -u drone_sim.service -e --no-pager`. Look for errors related to path setup, venv activation, build failures, MAVProxy errors (e.g., missing dependencies, port conflicts), or issues with the `--daemon` flag.
*   **Cannot Connect with GCS:** Ensure no firewall is blocking ports 14550 (UDP) or 5678 (TCP). Verify the service is `active (running)`. Double-check your GCS connection type (UDP broadcast vs. TCP outgoing connection). Use tools like `netstat -tulnp | grep LISTEN` or `ss -tulnp | grep LISTEN` on the server to confirm MAVProxy is listening on the expected ports.
