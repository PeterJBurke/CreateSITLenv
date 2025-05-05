# ArduPilot Drone Simulator Systemd Service Installer

This repository contains a shell script (`install_drone_service.sh`) designed to automate the setup of a systemd service for running the ArduPilot `sim_vehicle.py` simulator on a Linux system.

The service (`drone_sim.service`) will be configured to:

*   Run as the user `dronepilot`.
*   Automatically start on system boot.
*   Execute `sim_vehicle.py` from the `dronepilot` user's `~/ardupilot/ArduCopter` directory.
*   Source the `dronepilot` user's `~/.profile` before execution to set up the environment (e.g., PATH).
*   Output SITL MAVLink data via UDP and TCP.
*   Restart automatically on failure.

## Prerequisites

1.  **Systemd:** Your Linux distribution must use systemd (most modern distributions like Ubuntu, Debian, Fedora, CentOS do).
2.  **`dronepilot` User:** The user `dronepilot` must exist on the system. If not, create it:
    ```bash
    sudo useradd -m -s /bin/bash dronepilot
    ```
    *Note: You might need to add this user to specific groups (e.g., `dialout` for hardware access) depending on your needs, although it's less likely required for the simulator:*
    ```bash
    # Example: sudo usermod -aG dialout dronepilot
    ```
3.  **ArduPilot Source Code:** The `dronepilot` user must have the ArduPilot source code checked out and potentially built within their home directory, specifically at `~/ardupilot/ArduCopter`. The script assumes this path.
    *   Log in or switch to the `dronepilot` user (`su - dronepilot` or `sudo -iu dronepilot`) to perform the checkout/setup if needed.
    *   Ensure `sim_vehicle.py` is present and executable within that directory.
    *   Ensure any necessary dependencies for `sim_vehicle.py` are installed and accessible by the `dronepilot` user (often handled by ArduPilot's setup scripts).
4.  **`.profile` Configuration:** The `dronepilot` user's `~/.profile` should correctly set up any necessary environment variables (like `PATH`) so that `sim_vehicle.py` and its dependencies can be found and executed when sourced.

## Installation Instructions

1.  **Save the Script:** Download or copy the content of `install_drone_service.sh` to your Linux machine.
2.  **Make Executable:** Open a terminal and navigate to the directory where you saved the script. Make it executable:
    ```bash
    chmod +x install_drone_service.sh
    ```
3.  **Run the Installer:** Execute the script using `sudo`:
    ```bash
    sudo ./install_drone_service.sh
    ```
    The script will:
    *   Check if run as root.
    *   Verify the `dronepilot` user exists.
    *   Create the systemd service file `/etc/systemd/system/drone_sim.service`.
    *   Reload the systemd daemon.
    *   Enable the service (start on boot).
    *   Start the service immediately.
    *   Show the service status.

## Verification

After running the script, check if the service is running correctly:

*   **Check Status:**
    ```bash
    sudo systemctl status drone_sim.service
    ```
    Look for `Active: active (running)`.

*   **Follow Logs:** View the service's logs in real-time:
    ```bash
    sudo journalctl -u drone_sim.service -f
    ```
    Press `Ctrl+C` to stop following.

*   **Check Specific Errors:** If the service failed, check the end of the logs for errors:
    ```bash
    sudo journalctl -u drone_sim.service -e --no-pager
    ```

*   **Connect with GCS:** Try connecting your Ground Control Station (like QGroundControl or Mission Planner) to `udp:0.0.0.0:14550` or `tcp:0.0.0.0:5678` on the machine running the service.

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

*   **Service Fails to Start:** Check the logs (`journalctl -u drone_sim.service -e`) for specific error messages. Common causes include:
    *   Incorrect path to `ardupilot/ArduCopter` or `sim_vehicle.py`.
    *   `sim_vehicle.py` not being executable (`chmod +x ~/ardupilot/ArduCopter/sim_vehicle.py` as `dronepilot` user).
    *   Missing dependencies for `sim_vehicle.py`.
    *   Errors within the `dronepilot` user's `~/.profile`.
    *   Permissions issues (the `dronepilot` user cannot access needed files/directories).
*   **Environment Issues:** Systemd services don't always inherit the same environment as an interactive login shell, even when sourcing `.profile`. If `sim_vehicle.py` can't find commands/libraries, consider explicitly setting the `PATH` or other variables using the `Environment=` directive within the `.service` file itself (requires modifying the `install_drone_service.sh` script or editing `/etc/systemd/system/drone_sim.service` manually and running `sudo systemctl daemon-reload`).
