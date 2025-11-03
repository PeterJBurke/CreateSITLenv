#!/bin/bash
# Combined installer for CreateSITLenv
# Supports manual setup (SITL, MAVProxy, ArduCopter build) and systemd service install
# Peter Burke / Cascade AI 2025

set -e

# Save the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

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

check_user() {
    # Verify running as dronepilot
    if [ "$(whoami)" != "dronepilot" ]; then
        echo -e "${RED}${BOLD}ERROR: This installer must be run as the 'dronepilot' user.${RESET}"
        echo -e "${BOLD}Please follow these steps:${RESET}"
        echo -e "  1. Create the dronepilot user (as root/sudo user):"
        echo -e "     ${YELLOW}sudo useradd -m -s /bin/bash dronepilot${RESET}"
        echo -e "     ${YELLOW}sudo passwd dronepilot${RESET}"
        echo -e "     ${YELLOW}sudo usermod -aG sudo dronepilot${RESET}"
        echo -e "  2. Switch to dronepilot user:"
        echo -e "     ${YELLOW}su - dronepilot${RESET}"
        echo -e "  3. Clone and run this installer:"
        echo -e "     ${YELLOW}git clone https://github.com/PeterJBurke/CreateSITLenv.git${RESET}"
        echo -e "     ${YELLOW}cd CreateSITLenv${RESET}"
        echo -e "     ${YELLOW}bash install.sh${RESET}"
        exit 1
    fi
    echo -e "${GREEN}${BOLD}✓ Running as dronepilot user${RESET}"
}

manual_install() {
    check_user
    
    echo -e "\n${YELLOW}${BOLD}********** STEP 1: Manual Installation: Setting up SITL, MAVProxy, ArduCopter build **********${RESET}"
    echo -e "${BOLD}Updating package list...${RESET}"
    sudo apt-get update -y
    echo -e "${BOLD}Upgrading packages...${RESET}"
    sudo DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" upgrade -y
    echo -e "${BOLD}Installing dependencies (git only)...${RESET}"
    sudo apt-get install git -y

    echo -e "${BOLD}Setting up ArduPilot environment...${RESET}"
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

    echo -e "\n${GREEN}${BOLD}Manual install complete!${RESET}"
    echo -e "${BOLD}To run SITL:${RESET}"
    echo "  cd ~/ardupilot/ArduCopter"
    echo "  sim_vehicle.py --console --map --osd --out=udp:127.0.0.1:14550 --custom-location=33.64586111,-117.84275,25,0"
    echo "(You may need to run '. ~/.profile' first)"
}

service_install() {
    echo -e "\n${YELLOW}${BOLD}********** STEP 2: Service Installation: Setting up systemd virtual drone service **********${RESET}"
    manual_install
    echo -e "${BOLD}Proceeding to systemd service setup...${RESET}"
    sudo bash "${SCRIPT_DIR}/install_drone_service.sh"
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
