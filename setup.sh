#!/bin/bash 

# Script to create SITL envirnonment on a Linux machine or instance
# Peter Burke 12/30/2023
# tested on AWS E2C Ubuntu 22.04
# works also on Linux Mint

echo "######### Setting up server #########"
echo "For Amazon Web Services (AWS) Amazon Machine Image (AMI) Linux Ubuntu Server 22.04 LTS (HVM)"

echo "Updating Ubuntu"
# Update package database
sudo apt-get update -y

# Configure needrestart to automatically restart services
sudo sed -i 's/^#\$nrconf{restart}.*$/$nrconf{restart} = '\''a'\'';/' /etc/needrestart/needrestart.conf

# Upgrade packages
sudo apt-get upgrade -y

# Install EMACS, Professor Burke's favorite text editor
sudo apt-get install emacs -y


echo "Setting up Ardupilot build envirnoment"
# https://ardupilot.org/dev/docs/building-setup-linux.html#building-setup-linux

sudo apt-get install git -y
sudo apt-get install gitk git-gui -y
#git clone https://github.com/ArduPilot/ardupilot.git
git clone https://github.com/uci-overRID/ardupilot
git checkout v2.2.1
cd ~/ardupilot
git submodule update --init --recursive
Tools/environment_install/install-prereqs-ubuntu.sh -y
. ~/.profile

echo "Found these are needed"
# see https://discuss.ardupilot.org/t/failed-to-load-module-no-module-named-console/111125/5
sudo apt-get install python3-wxgtk4.0 -y --no-install-recommends
# see https://stackoverflow.com/questions/3655306/ubuntu-usr-bin-env-python-no-such-file-or-directory
sudo apt install python-is-python3

echo "Finished setting up server!"
echo "For help see:"
echo "https://ardupilot.org/dev/docs/setting-up-sitl-on-linux.html"
echo "https://ardupilot.org/mavproxy/docs/getting_started/quickstart.html"

echo "To run SITL:"
echo "Either logout and log back and to run these commands, or run manualy..."
echo ". ~/.profile"
echo " an example commmand:"
echo "cd ~/ardupilot/ArduCopter;  sim_vehicle.py "
echo " and "
echo "cd ~/ardupilot/ArduCopter;  sim_vehicle.py --console --map --osd --out=udp:35.94.121.200:14550 --custom-location=33.64586111,-117.84275,25,0"


