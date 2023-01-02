#!/bin/bash
#remove x-c1 old installtion
sudo sed -i '/x-c1/d' /etc/rc.local
sudo sed -i '/pigpiod/d' /etc/rc.local

sudo sed -i '/x-c1/d' ~/.bashrc

sudo rm /usr/local/bin/x-c1-softsd.sh -f
sudo rm /etc/x-c1-pwr.sh -f

#new
sudo systemctl stop pigpiod
sudo systemctl stop x-c1-pwr
sudo systemctl stop x-c1-fan
sudo systemctl disable pigpiod
sudo systemctl disable x-c1-pwr
sudo systemctl disable x-c1-fan

sudo rm /etc/systemd/system/pigpiod.service -f
sudo rm /etc/systemd/system/x-c1-pwr.service -f
sudo rm /etc/systemd/system/x-c1-fan.service -f
sudo rm /usr/local/bin/fan.py -f

# remove fan patch for Raspberry Pi OS Lite
sed -i 's/ -n 127.0.0.1//' /lib/systemd/system/pigpiod.service
#new end
