#!/bin/bash
# Created with Gemini based on the prompt:
# "create a single sh script to install a service and enable it on linux. The service should run as user "dronepilot". This is the command the service should run:
# . ~/.profile
# cd ~/ardupilot/ArduCopter;  sim_vehicle.py  --out=udp:0.0.0.0:14550  --out tcp:0.0.0.0:5678 --custom-location=33.64586111,-117.84275,25,0"
# --- V2: Removed explicit Group= directive to resolve potential 216/GROUP errors ---

# --- Configuration ---
SERVICE_NAME="drone_sim"
SERVICE_USER="dronepilot"
SERVICE_DESC="ArduPilot Drone Simulator Service"
# Get the user's home directory dynamically
USER_HOME=$(getent passwd "$SERVICE_USER" | cut -d: -f6)
# If USER_HOME is empty, the user doesn't exist or command failed
if [ -z "$USER_HOME" ]; then
    echo "Error: Could not determine home directory for user '$SERVICE_USER'." >&2
    echo "Please ensure the user exists before running this script." >&2
    # Exit here if user doesn't exist, as we can't proceed
    if ! id "$SERVICE_USER" &>/dev/null; then
        echo "Error: User '$SERVICE_USER' does not exist." >&2
        echo "Please create the user first, for example:" >&2
        echo "  sudo useradd -m -s /bin/bash $SERVICE_USER" >&2
        # Optionally add to necessary groups if needed, e.g., dialout for serial ports
        # echo "  sudo usermod -aG dialout $SERVICE_USER" >&2
        exit 1
    else
        # User exists but getent failed - less likely, but possible permission issue
        echo "Warning: Could not automatically determine home directory for '$SERVICE_USER'." >&2
        echo "Attempting to guess home directory as /home/$SERVICE_USER. Verify this is correct." >&2
        USER_HOME="/home/$SERVICE_USER" # Fallback guess
        if [ ! -d "$USER_HOME" ]; then
             echo "Error: Fallback home directory $USER_HOME does not exist." >&2
             exit 1
        fi
    fi
fi

WORKING_DIR="${USER_HOME}/ardupilot/ArduCopter"
# Use 'exec' so the final process replaces the shell, cleaner process tree
# Ensure the path to sim_vehicle.py is correct or it's in the PATH after sourcing .profile
# Using full path to sh for robustness
COMMAND_TO_RUN="/bin/sh -c '. ${USER_HOME}/.profile && cd ${WORKING_DIR} && exec sim_vehicle.py --out=udp:0.0.0.0:14550 --out tcp:0.0.0.0:5678 --custom-location=33.64586111,-117.84275,25,0'"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"

# --- Script Logic ---

# 1. Check if running as root
if [ "$(id -u)" -ne 0 ]; then
   echo "Error: This script must be run as root or with sudo." >&2
   exit 1
fi

# 2. Check if the user exists (already done partially when getting home dir)
if ! id "$SERVICE_USER" &>/dev/null; then
    # This is redundant if the USER_HOME check above exits, but kept for clarity
    echo "Error: User '$SERVICE_USER' does not exist." >&2
    echo "Please create the user first." >&2
    exit 1
fi
echo "User '$SERVICE_USER' found."
echo "Home directory set to: $USER_HOME"
echo "Working directory set to: $WORKING_DIR"
echo "Service command: $COMMAND_TO_RUN"

# Verify working directory exists for the target user
if ! sudo -u "$SERVICE_USER" test -d "$WORKING_DIR"; then
    echo "Warning: Working directory '$WORKING_DIR' does not exist or is not accessible by user '$SERVICE_USER'." >&2
    echo "The service might fail to start. Please ensure the directory exists and the user has permissions." >&2
    # Decide whether to exit or continue with warning
    # read -p "Continue anyway? (y/N): " confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || exit 1
fi


# 3. Create the systemd service file
echo "Creating systemd service file at ${SERVICE_FILE}..."

cat << EOF > "${SERVICE_FILE}"
[Unit]
Description=${SERVICE_DESC}
# Start after network is ready, crucial for network-based services
After=network-online.target
Wants=network-online.target

[Service]
User=${SERVICE_USER}
# Group= directive removed - systemd will use the user's primary group by default
WorkingDirectory=${WORKING_DIR}

# Ensure PATH is set correctly, sourcing .profile might not always work as expected in non-interactive systemd context
# Environment="PATH=/bin:/usr/bin:/usr/local/bin:${USER_HOME}/.local/bin:${USER_HOME}/bin" # Example, adjust as needed
# Or rely on PamEnvironment=yes if user session environment is needed (see systemd docs)

# Use sh -c to handle sourcing profile and changing directory
# Make sure sim_vehicle.py is executable and in the PATH or specify full path
ExecStart=${COMMAND_TO_RUN}

# Restart policy
Restart=on-failure
RestartSec=10s

# Output logging to systemd journal
StandardOutput=journal
StandardError=journal

# Optional: Define resource limits if necessary
# LimitNOFILE=65536

# Optional: Kill mode if sim_vehicle.py spawns child processes that need cleanup
# KillMode=process

[Install]
WantedBy=multi-user.target
EOF

# 4. Set permissions (systemd usually handles this, but explicit doesn't hurt)
chmod 644 "${SERVICE_FILE}"

echo "Service file created."

# 5. Reload systemd manager configuration
echo "Reloading systemd daemon..."
systemctl daemon-reload

# 6. Enable the service to start on boot
echo "Enabling service ${SERVICE_NAME}..."
systemctl enable "${SERVICE_NAME}.service"

# 7. Start the service immediately
echo "Starting service ${SERVICE_NAME}..."
systemctl start "${SERVICE_NAME}.service"

# 8. Display service status
echo "Service ${SERVICE_NAME} status:"
# Use --no-pager to prevent status from taking over the terminal
# Check the exit code of the start command before showing status
if systemctl is-active --quiet "${SERVICE_NAME}"; then
  echo "Service started successfully."
  systemctl --no-pager status "${SERVICE_NAME}.service"
else
  echo "Error: Service failed to start. Please check logs." >&2
  # Show status even on failure for more details
  systemctl --no-pager status "${SERVICE_NAME}.service"
  echo "Check logs with: sudo journalctl -u ${SERVICE_NAME} -e" >&2
  exit 1 # Exit with error if service failed to start
fi


echo ""
echo "--- Installation Complete ---"
echo "Service '${SERVICE_NAME}' is enabled and started."
echo "To check logs: sudo journalctl -u ${SERVICE_NAME} -f"
echo "To check status: sudo systemctl status ${SERVICE_NAME}"
echo "To stop service: sudo systemctl stop ${SERVICE_NAME}"
echo "To restart service: sudo systemctl restart ${SERVICE_NAME}"
echo "To disable service on boot: sudo systemctl disable ${SERVICE_NAME}"

exit 0

# --- HOW TO INSTALL ---
# 1. Ensure the user 'dronepilot' exists on the system. If not, create it:
#    sudo useradd -m -s /bin/bash dronepilot
#    # Optionally add the user to groups if needed (e.g., dialout for serial):
#    # sudo usermod -aG dialout dronepilot
#
# 2. Ensure the 'dronepilot' user has the ardupilot code checked out and built,
#    specifically the directory specified in WORKING_DIR (~/ardupilot/ArduCopter by default).
#    Also ensure `sim_vehicle.py` is executable and potentially in the PATH set by ~/.profile.
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
