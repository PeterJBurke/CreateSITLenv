#!/bin/bash
# Created with Gemini based on the prompt:
# "create a single sh script to install a service and enable it on linux. The service should run as user "dronepilot". This is the command the service should run:
# . ~/.profile
# cd ~/ardupilot/ArduCopter;  sim_vehicle.py  --out=udp:0.0.0.0:14550  --out tcp:0.0.0.0:5678 --custom-location=33.64586111,-117.84275,25,0"
# --- Final Version: Simplified ExecStart, includes MAVProxy Daemon ---

# --- Configuration ---
SERVICE_NAME="drone_sim"
SERVICE_USER="dronepilot"
SERVICE_DESC="ArduPilot SITL Service with MAVProxy Daemon (Simplified)"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"

# Define paths explicitly for checks and clarity
USER_HOME="/home/${SERVICE_USER}" # Assuming standard home location
VENV_ACTIVATE="${USER_HOME}/venv-ardupilot/bin/activate"
ARDUPILOT_DIR="${USER_HOME}/ardupilot"
VEHICLE_DIR="${ARDUPILOT_DIR}/ArduCopter"
SIM_VEHICLE_SCRIPT="${ARDUPILOT_DIR}/Tools/autotest/sim_vehicle.py"

# --- Build the Simplified ExecStart command ---
# Activates Venv, CDs into vehicle dir, executes sim_vehicle.py with necessary flags.
# Relies on venv activation setting up the necessary PATH for python/mavproxy.
COMMAND_TO_RUN="/usr/bin/sudo -u ${SERVICE_USER} /bin/bash -c '\
  source \"${VENV_ACTIVATE}\" && \
  cd \"${VEHICLE_DIR}\" && \
  exec \"${SIM_VEHICLE_SCRIPT}\" -v ArduCopter -C --mavproxy-args=\"--daemon\" --out=udp:0.0.0.0:14550 --out tcpin:0.0.0.0:5678 --custom-location=33.64586111,-117.84275,25,0 \
'"

# --- Script Logic ---

# 1. Check if running as root
if [ "$(id -u)" -ne 0 ]; then
   echo "Error: This script must be run as root or with sudo." >&2
   exit 1
fi

# 2. Check if the user exists
if ! id "$SERVICE_USER" &>/dev/null; then
    echo "Error: User '$SERVICE_USER' does not exist." >&2
    echo "Please create the user first, for example:" >&2
    echo "  sudo useradd -m -s /bin/bash $SERVICE_USER" >&2
    exit 1
fi
echo "User '$SERVICE_USER' found."

# 3. Check required paths exist (as dronepilot user)
paths_ok=true
echo "Checking required paths for user $SERVICE_USER..."
if ! sudo -u "$SERVICE_USER" test -f "$VENV_ACTIVATE"; then echo "Error: Venv activate script not found: $VENV_ACTIVATE"; paths_ok=false; fi
if ! sudo -u "$SERVICE_USER" test -d "$VEHICLE_DIR"; then echo "Error: Vehicle directory not found: $VEHICLE_DIR"; paths_ok=false; fi
if ! sudo -u "$SERVICE_USER" test -f "$SIM_VEHICLE_SCRIPT"; then echo "Error: sim_vehicle.py script not found: $SIM_VEHICLE_SCRIPT"; paths_ok=false; fi

if [ "$paths_ok" = false ]; then
    echo "Error: One or more required paths not found or accessible by user $SERVICE_USER. Please check configuration and setup." >&2
    exit 1 # Exit if core paths are missing
fi
echo "Path checks completed."


# 4. Create the systemd service file
echo "Creating systemd service file at ${SERVICE_FILE}..."

cat << EOF > "${SERVICE_FILE}"
[Unit]
Description=${SERVICE_DESC}
After=network-online.target
Wants=network-online.target

[Service]
# User=, Group=, WorkingDirectory= omitted; handled by ExecStart command
ExecStart=${COMMAND_TO_RUN}

# Restart policy
Restart=on-failure
RestartSec=10s

# Output logging to systemd journal
StandardOutput=journal
StandardError=journal

# Type=simple (default) is appropriate here. MAVProxy daemonizes itself,
# but sim_vehicle.py likely remains as the main foreground process for systemd.
# Type=simple

[Install]
WantedBy=multi-user.target
EOF

# 5. Set permissions
chmod 644 "${SERVICE_FILE}"

echo "Service file created."

# 6. Reload systemd manager configuration
echo "Reloading systemd daemon..."
systemctl daemon-reload

# 7. Enable the service to start on boot
echo "Enabling service ${SERVICE_NAME}..."
# Stop service first before enabling, avoids potential issues if it was somehow masked
systemctl stop "${SERVICE_NAME}.service" >/dev/null 2>&1 || true
systemctl enable "${SERVICE_NAME}.service"

# 8. Start the service immediately
echo "Starting service ${SERVICE_NAME}..."
systemctl start "${SERVICE_NAME}.service"

# 9. Display service status
echo "Service ${SERVICE_NAME} status:"
sleep 3 # Give the service a moment to initialize
if systemctl is-active --quiet "${SERVICE_NAME}"; then
  echo "Service started successfully."
  systemctl --no-pager status "${SERVICE_NAME}.service"
else
  echo "Error: Service failed to start or stopped shortly after starting. Please check logs." >&2
  systemctl --no-pager status "${SERVICE_NAME}.service"
  echo "Check logs with: sudo journalctl -u ${SERVICE_NAME} -e" >&2
  exit 1
fi

echo ""
echo "--- Installation Complete ---"
echo "Service '${SERVICE_NAME}' is enabled and should be running."
echo "This version uses a simplified startup command."
echo "GCS should connect to MAVProxy outputs: udp:0.0.0.0:14550 or by connecting TO tcp:0.0.0.0:5678."
echo "To check logs: sudo journalctl -u ${SERVICE_NAME} -f"
echo "To check status: sudo systemctl status ${SERVICE_NAME}"
echo "To stop service: sudo systemctl stop ${SERVICE_NAME}"
echo "To restart service: sudo systemctl restart ${SERVICE_NAME}"
echo "To disable service on boot: sudo systemctl disable ${SERVICE_NAME}"

exit 0

# --- HOW TO INSTALL ---
# 1. Ensure user 'dronepilot' exists (sudo useradd -m -s /bin/bash dronepilot).
# 2. Ensure dronepilot has ArduPilot code (~/ardupilot) and Python venv (~/venv-ardupilot) set up with dependencies.
# 3. Verify paths near top of script if your setup differs.
# 4. Save this script (e.g., install_drone_service.sh).
# 5. chmod +x install_drone_service.sh
# 6. sudo ./install_drone_service.sh
# 7. Check status and logs (sudo systemctl status drone_sim, sudo journalctl -u drone_sim -f).
# --- END HOW TO INSTALL ---
