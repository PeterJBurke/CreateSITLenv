#!/bin/bash
# Created with Gemini based on the prompt:
# "create a single sh script to install a service and enable it on linux. The service should run as user "dronepilot". This is the command the service should run:
# . ~/.profile
# cd ~/ardupilot/ArduCopter;  sim_vehicle.py  --out=udp:0.0.0.0:14550  --out tcp:0.0.0.0:5678 --custom-location=33.64586111,-117.84275,25,0"
# --- Final Version: Includes MAVProxy Daemon via --mavproxy-args ---

# --- Configuration ---
SERVICE_NAME="drone_sim"
SERVICE_USER="dronepilot"
SERVICE_DESC="ArduPilot SITL Service with MAVProxy Daemon" # Updated description
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"

# Define paths explicitly for clarity and robustness in service context
USER_HOME="/home/${SERVICE_USER}" # Assuming standard home location
VENV_ACTIVATE="${USER_HOME}/venv-ardupilot/bin/activate"
ARDUPILOT_DIR="${USER_HOME}/ardupilot"
VEHICLE_DIR="${ARDUPILOT_DIR}/ArduCopter"
SIM_VEHICLE_SCRIPT="${ARDUPILOT_DIR}/Tools/autotest/sim_vehicle.py"
GCC_ARM_PATH="/opt/gcc-arm-none-eabi-10-2020-q4-major/bin" # Adjust if different
CCACHE_PATH="/usr/lib/ccache" # Adjust if different

# --- Build the ExecStart command ---
# This explicitly sets up the environment and runs the command.
# Uses bash, sudo -u, activates venv, sets PATHs.
# Includes -v ArduCopter, -C flag, --mavproxy-args="--daemon", and tcpin output.
COMMAND_TO_RUN="/usr/bin/sudo -u ${SERVICE_USER} /bin/bash -c '\
  echo \"Setting up environment for ${SERVICE_USER}...\"; \
  TEMP_PATH=\"\$PATH\"; \
  if [ -d \"${USER_HOME}/bin\" ]; then TEMP_PATH=\"${USER_HOME}/bin:\$TEMP_PATH\"; echo \"Added ~/bin to PATH\"; fi; \
  if [ -d \"${USER_HOME}/.local/bin\" ]; then TEMP_PATH=\"${USER_HOME}/.local/bin:\$TEMP_PATH\"; echo \"Added ~/.local/bin to PATH\"; fi; \
  if [ -f \"${VENV_ACTIVATE}\" ]; then \
    echo \"Activating venv: ${VENV_ACTIVATE}\"; \
    source \"${VENV_ACTIVATE}\"; \
    TEMP_PATH=\"\$PATH\"; \
  else \
    echo \"WARNING: Virtualenv activate script not found: ${VENV_ACTIVATE}\"; \
  fi; \
  echo \"Exporting specific PATH additions...\"; \
  if [ -d \"${GCC_ARM_PATH}\" ]; then TEMP_PATH=\"${GCC_ARM_PATH}:\$TEMP_PATH\"; else echo \"WARNING: GCC ARM path not found: ${GCC_ARM_PATH}\"; fi; \
  if [ -d \"${ARDUPILOT_DIR}/Tools/autotest\" ]; then TEMP_PATH=\"${ARDUPILOT_DIR}/Tools/autotest:\$TEMP_PATH\"; else echo \"WARNING: ArduPilot autotest path not found\"; fi; \
  if [ -d \"${CCACHE_PATH}\" ]; then TEMP_PATH=\"${CCACHE_PATH}:\$TEMP_PATH\"; else echo \"WARNING: ccache path not found: ${CCACHE_PATH}\"; fi; \
  export PATH=\"\$TEMP_PATH\"; \
  echo \"Changing directory to ${VEHICLE_DIR}...\"; \
  cd \"${VEHICLE_DIR}\" && \
  echo \"Executing ${SIM_VEHICLE_SCRIPT} with MAVProxy daemon...\"; \
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
# These checks help catch setup errors before the service tries to run
paths_ok=true
echo "Checking required paths for user $SERVICE_USER..."
if ! sudo -u "$SERVICE_USER" test -f "$VENV_ACTIVATE"; then echo "Warning: Venv activate script not found: $VENV_ACTIVATE"; paths_ok=false; fi
if ! sudo -u "$SERVICE_USER" test -d "$VEHICLE_DIR"; then echo "Error: Vehicle directory not found: $VEHICLE_DIR"; paths_ok=false; fi
if ! sudo -u "$SERVICE_USER" test -f "$SIM_VEHICLE_SCRIPT"; then echo "Error: sim_vehicle.py script not found: $SIM_VEHICLE_SCRIPT"; paths_ok=false; fi
# Add checks for GCC_ARM_PATH, CCACHE_PATH if their absence is critical

if [ "$paths_ok" = false ]; then
    echo "Error: One or more required paths not found or accessible by user $SERVICE_USER. Please check configuration and setup." >&2
    # Optionally exit here if checks fail critically
    # exit 1
fi
echo "Path checks completed."


# 4. Create the systemd service file
echo "Creating systemd service file at ${SERVICE_FILE}..."

cat << EOF > "${SERVICE_FILE}"
[Unit]
Description=${SERVICE_DESC}
# Start after network is ready, crucial for network-based services
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

# Type=forking might be needed if mavproxy truly forks cleanly with --daemon,
# but start with simple (default) and see if it works. If sim_vehicle.py
# exits AFTER successfully launching mavproxy daemon and sitl, then change
# Type=simple to Type=forking and potentially add GuessMainPID=no if needed.
# Start with Type=simple first.
# Type=simple # (Default) Assumes the main process started by ExecStart stays running.

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
systemctl enable "${SERVICE_NAME}.service"

# 8. Start the service immediately
echo "Starting service ${SERVICE_NAME}..."
systemctl start "${SERVICE_NAME}.service"

# 9. Display service status
echo "Service ${SERVICE_NAME} status:"
# Use --no-pager to prevent status from taking over the terminal
# Give the service a moment to start before checking status
sleep 3
if systemctl is-active --quiet "${SERVICE_NAME}"; then
  echo "Service started successfully."
  systemctl --no-pager status "${SERVICE_NAME}.service"
else
  echo "Error: Service failed to start or stopped shortly after starting. Please check logs." >&2
  # Show status even on failure for more details
  systemctl --no-pager status "${SERVICE_NAME}.service"
  echo "Check logs with: sudo journalctl -u ${SERVICE_NAME} -e" >&2
  exit 1 # Exit with error if service failed to start
fi

echo ""
echo "--- Installation Complete ---"
echo "Service '${SERVICE_NAME}' is enabled and should be running."
echo "This version attempts to run MAVProxy as a daemon via sim_vehicle.py."
echo "GCS should connect to MAVProxy outputs: udp:0.0.0.0:14550 or by connecting TO tcp:0.0.0.0:5678."
echo "To check logs: sudo journalctl -u ${SERVICE_NAME} -f"
echo "To check status: sudo systemctl status ${SERVICE_NAME}"
echo "To stop service: sudo systemctl stop ${SERVICE_NAME}"
echo "To restart service: sudo systemctl restart ${SERVICE_NAME}"
echo "To disable service on boot: sudo systemctl disable ${SERVICE_NAME}"

exit 0

# --- HOW TO INSTALL ---
# 1. Ensure the user 'dronepilot' exists on the system. If not, create it:
#    sudo useradd -m -s /bin/bash dronepilot
#
# 2. Ensure the 'dronepilot' user has:
#    - The ardupilot code checked out (e.g., in ~/ardupilot).
#    - A Python virtual environment set up (e.g., ~/venv-ardupilot) with ArduPilot SITL dependencies installed (mavproxy, empy, etc.).
#    - Necessary build tools like the ARM GCC toolchain installed (if the paths at the top of the script are relevant).
#    - The paths configured near the top of this script match your setup.
#
# 3. Save this script content to a file, e.g., install_drone_service.sh
#
# 4. Make the script executable:
#    chmod +x install_drone_service.sh
#
# 5. Run the script with root privileges:
#    sudo ./install_drone_service.sh
#
# 6. Check the output and the service status/logs for any errors.
#    sudo systemctl status drone_sim
#    sudo journalctl -u drone_sim -f
# --- END HOW TO INSTALL ---
