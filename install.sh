#!/bin/bash
# Combined installer for CreateSITLenv
# Supports manual setup (SITL, MAVProxy, ArduCopter build) and systemd service install
# Peter Burke / Cascade AI 2025

set -e

# Color and style codes
BOLD="\033[1m"
YELLOW="\033[1;33m"
GREEN="\033[1;32m"
RED="\033[1;31m"
RESET="\033[0m"

show_menu() {
    echo -e "\n${YELLOW}${BOLD}*********************************************${RESET}"
    echo -e "${YELLOW}${BOLD}*         CreateSITLenv - Installer         *${RESET}"
    echo -e "${YELLOW}${BOLD}*********************************************${RESET}"
    echo -e "${BOLD}Choose installation type:${RESET}"
    echo "  1) Manual install (dependencies, build, no service)"
    echo "  2) Full install (manual + systemd service for auto virtual drone)"
    echo "  q) Quit"
    echo -e "${YELLOW}${BOLD}*********************************************${RESET}"
}

manual_install() {
    echo -e "\n${YELLOW}${BOLD}********** STEP 1: Manual Installation: Setting up SITL, MAVProxy, ArduCopter build **********${RESET}"
    echo -e "${BOLD}Updating package list...${RESET}"
    sudo apt-get update -y
    echo -e "${BOLD}Upgrading packages...${RESET}"
    sudo DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" upgrade -y
    echo -e "${BOLD}Installing dependencies (git only)...${RESET}"
    sudo apt-get install git -y

    if ! id "dronepilot" &>/dev/null; then
        echo -e "${BOLD}${YELLOW}User 'dronepilot' does not exist. Creating...${RESET}"
        sudo useradd -m -s /bin/bash dronepilot
    else
        echo -e "${GREEN}${BOLD}User 'dronepilot' exists.${RESET}"
    fi

    echo -e "${BOLD}Setting up ArduPilot environment for 'dronepilot'...${RESET}"
    sudo -u dronepilot bash <<'EOF'
cd ~
if [ ! -d "ardupilot" ]; then
    echo "Cloning ArduPilot repo..."
    git clone https://github.com/ArduPilot/ardupilot.git
else
    echo "ArduPilot repo already exists."
fi
cd ardupilot
echo "Updating submodules..."
git submodule update --init --recursive
echo "Running ArduPilot prerequisites script..."
Tools/environment_install/install-prereqs-ubuntu.sh -y
echo "Sourcing profile..."
. ~/.profile
EOF

    echo -e "\n${GREEN}${BOLD}Manual install complete!${RESET}"
    echo -e "${BOLD}To run SITL, as 'dronepilot':${RESET}"
    echo "  cd ~/ardupilot/ArduCopter"
    echo "  sim_vehicle.py --console --map --osd --out=udp:127.0.0.1:14550 --custom-location=33.64586111,-117.84275,25,0"
    echo "(You may need to run '. ~/.profile' first)"
}

service_install() {
    echo -e "\n${YELLOW}${BOLD}********** STEP 2: Service Installation: Setting up systemd virtual drone service **********${RESET}"
    manual_install
    echo -e "${BOLD}Proceeding to systemd service setup...${RESET}"
    sudo bash install_drone_service.sh
    echo -e "\n${GREEN}${BOLD}Systemd service installed!${RESET}"
    echo -e "${BOLD}To manage the service:${RESET}"
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
