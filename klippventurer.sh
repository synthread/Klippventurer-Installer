#!/bin/bash

# Define log file path
LOGFILE="$HOME/klippventurer-installation.log"

# Update package lists
sudo apt update

# Install git
sudo apt install -y git

# Check if git is installed successfully
if [ $(dpkg-query -W -f='${Status}' git 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
    echo "Git is installed successfully."
else
    echo "Git installation failed. Check your conntection, then try again."
    exit 1
fi

# Install stm32flash
sudo apt install -y stm32flash

# Check if stm32flash is installed successfully
if [ $(dpkg-query -W -f='${Status}' stm32flash 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
    echo "stm32flash is installed successfully."
else
    echo "stm32flash installation failed. Please install it manually, then run this script again."
    exit 1
fi

# Clone the kiauh repository into the ~ directory
cd ~
git clone https://github.com/th33xitus/kiauh.git

# Check if cloning is successful
if [ -d ~/kiauh ]; then
    echo "Cloning is successful."
else
    echo "Cloning failed. Please clone https://github.com/th33xitus/kiauh.git into your home folder, then run this script again."
    exit 1
fi

echo "Attempting to configure UART for Raspberry Pi models 3B, 3B+, 3A+, 4B or Zero W"

# Setup the UART port every boot
sudo sh -c "echo '# Enable UART port' >> /boot/config.txt"
sudo sh -c "echo 'enable_uart=1' >> /boot/config.txt"
sudo sh -c "echo 'dtoverlay=miniuart-bt' >> /boot/config.txt"
sudo sh -c "echo 'dtoverlay=disable-bt' >> /boot/config.txt"

echo "/boot/config.txt has been changed"

# Disable kernel boot console
echo "Disabling kernel serial console to keep our port clean"

sudo sed -i 's/console=tty1 //' /boot/cmdline.txt

echo "Kernel cmdline has been changed"

# Disable modem to prevent it from stealing our port

echo "Subsequent boots should have working UART on ttyAMA0"

echo "Prepping UART serial port for Klipper.bin installation"

# Our port should work after a reboot, but it's my port and I need it now!
sudo raspi-config nonint do_serial 2
sudo dtoverlay miniuart-bt
sudo dtoverlay disable-bt

# The above section needs more error checking
# The above section needs more error checking
# The above section needs more error checking
# The above section needs more error checking
# The above section needs more error checking
# Actually, this ALL needs more error checking...

echo "Serial should be good to go. Preparing to install Klipper and Mainsail."

# Change directory to ~/kiauh/scripts
cd ~/kiauh/scripts

# Execute klipper.sh
sudo ./klipper.sh

# Execute mainsail.sh
sudo ./mainsail.sh

# Execute fluidd.sh
sudo ./fluidd.sh

# Change directory to home and copy Klipper config into place
cd ~
cp ~/klippventurer-installer/configs/adventurer3.cfg ~/printer_data/config/printer.cfg

# Change directory to ~/klipper and build klipper firmware
cd ~/klipper
make clean
cp ./klippventurer-installer/configs/adventurer3.config ~/klipper/.config
make
cp ~/klipper/out/klipper.bin ~/

# Backup FlashForge firmware before installing Klipper
echo "backing up FlashForge firmware to ~/finder_rush.bak.bin" 

sudo stm32flash -k -i -18,23,18 /dev/ttyAMA0
sudo stm32flash -r ~/finder_rush.bak.bin -i -18,23,18 /dev/ttyAMA0

echo "Backup may have completed, trying to flash"


sudo stm32flash -u -i -18,23,18 /dev/ttyAMA0
sudo stm32flash -w ~/klipper.bin -R -i -18,23,18:-18,-23,18 /dev/ttyAMA0

read -p "flashed Klipper, press Enter to restart."
  sudo reboot
fi
