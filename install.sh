#!/bin/bash
# Combined installer for CreateSITLenv
# Supports manual setup (SITL, MAVProxy, ArduCopter build) and systemd service install
# Peter Burke / Cascade AI 2025

set -e

show_menu() {
    echo "\n==============================="
    echo "CreateSITLenv - Installer"
    echo "==============================="
    echo "Choose installation type:"
    echo "  1) Manual install (dependencies, build, no service)"
    echo "  2) Full install (manual + systemd service for auto virtual drone)"
    echo "  q) Quit"
    echo "==============================="
}

manual_install() {
    echo "\n--- Manual Installation: Setting up SITL, MAVProxy, ArduCopter build ---"
    sudo apt-get update -y
    sudo apt-get upgrade -y
    sudo apt-get install emacs git gitk git-gui python3-wxgtk4.0 python-is-python3 -y

    if ! id "dronepilot" &>/dev/null; then
        echo "User 'dronepilot' does not exist. Creating..."
        sudo useradd -m -s /bin/bash dronepilot
    fi

    sudo -u dronepilot bash <<'EOF'
cd ~
if [ ! -d "ardupilot" ]; then
    git clone https://github.com/ArduPilot/ardupilot.git
fi
cd ardupilot
git submodule update --init --recursive
Tools/environment_install/install-prereqs-ubuntu.sh -y
. ~/.profile
EOF

    echo "\nManual install complete!"
    echo "To run SITL, as 'dronepilot':"
    echo "  cd ~/ardupilot/ArduCopter"
    echo "  sim_vehicle.py --console --map --osd --out=udp:127.0.0.1:14550 --custom-location=33.64586111,-117.84275,25,0"
    echo "(You may need to run '. ~/.profile' first)"
}

service_install() {
    echo "\n--- Service Installation: Setting up systemd virtual drone service ---"
    manual_install
    echo "\nProceeding to service setup..."
    sudo bash install_drone_service.sh
    echo "\nSystemd service installed!"
    echo "To manage the service:"
    echo "  sudo systemctl status drone_sim"
    echo "  sudo systemctl start drone_sim"
    echo "  sudo systemctl stop drone_sim"
    echo "  sudo systemctl restart drone_sim"
    echo "  sudo systemctl enable drone_sim"
}

while true; do
    show_menu
    read -p "Enter choice [1/2/q]: " choice
    case "$choice" in
        1)
            manual_install
            break
            ;;
        2)
            service_install
            break
            ;;
        q|Q)
            echo "Exiting installer."
            exit 0
            ;;
        *)
            echo "Invalid choice. Please enter 1, 2, or q."
            ;;
    esac
done
