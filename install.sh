#IMPORTANT! This script is only for the x-c1 on Raspberry Pi OS
#x-c1 Powering on /reboot /full shutdown through hardware
# "new" changes according to https://github.com/geekworm-com/x-c1/pull/2
#!/bin/bash

echo '#!/bin/bash

SHUTDOWN=4
REBOOTPULSEMINIMUM=200
REBOOTPULSEMAXIMUM=600
# echo "$SHUTDOWN" > /sys/class/gpio/export		# old
# echo "in" > /sys/class/gpio/gpio$SHUTDOWN/direction	# old

# new
if [ ! -d /sys/class/gpio/gpio$SHUTDOWN ]
then
  echo "$SHUTDOWN" > /sys/class/gpio/export
  sleep 1 ;# Short delay while GPIO permissions are set up
  echo "in" > /sys/class/gpio/gpio$SHUTDOWN/direction
fi
# new end

BOOT=17
# echo "$BOOT" > /sys/class/gpio/export 		# old
# echo "out" > /sys/class/gpio/gpio$BOOT/direction	# old
# echo "1" > /sys/class/gpio/gpio$BOOT/value		# old

# new
if [ ! -d /sys/class/gpio/gpio$BOOT ]
then
  echo "$BOOT" > /sys/class/gpio/export
  sleep 1 ;# Short delay while GPIO permissions are set up
  echo "out" > /sys/class/gpio/gpio$BOOT/direction
  echo "1" > /sys/class/gpio/gpio$BOOT/value
fi
# new end

# echo "Your device are shutting down..."		# old
# new
echo "Watching gpio for changes, to clean shutdown/reboot..."
# new end

while [ 1 ]; do
  shutdownSignal=$(cat /sys/class/gpio/gpio$SHUTDOWN/value)
  if [ $shutdownSignal = 0 ]; then
    /bin/sleep 0.2
  else
    pulseStart=$(date +%s%N | cut -b1-13)
    while [ $shutdownSignal = 1 ]; do
      /bin/sleep 0.02
      if [ $(($(date +%s%N | cut -b1-13)-$pulseStart)) -gt $REBOOTPULSEMAXIMUM ]; then
        echo "Your device are shutting down", SHUTDOWN, ", halting Rpi ..."
        sudo poweroff
        exit
      fi
      shutdownSignal=$(cat /sys/class/gpio/gpio$SHUTDOWN/value)
    done
    if [ $(($(date +%s%N | cut -b1-13)-$pulseStart)) -gt $REBOOTPULSEMINIMUM ]; then
      echo "Your device is rebooting", SHUTDOWN, ", recycling Rpi ..."
      sudo reboot
      exit
    fi
  fi
done' > /etc/x-c1-pwr.sh
sudo chmod +x /etc/x-c1-pwr.sh
# sudo sed -i '$ i /etc/x-c1-pwr.sh &' /etc/rc.local		# old


#x-c1 full shutdown through Software
#!/bin/bash

echo '#!/bin/bash

BUTTON=27

echo "$BUTTON" > /sys/class/gpio/export;
echo "out" > /sys/class/gpio/gpio$BUTTON/direction
echo "1" > /sys/class/gpio/gpio$BUTTON/value

SLEEP=${1:-4}

re='^[0-9\.]+$'
if ! [[ $SLEEP =~ $re ]] ; then
   echo "error: sleep time not a number" >&2; exit 1
fi

echo "Your device will shutting down in 4 seconds..."
/bin/sleep $SLEEP

echo "0" > /sys/class/gpio/gpio$BUTTON/value
' > /usr/local/bin/x-c1-softsd.sh
sudo chmod +x /usr/local/bin/x-c1-softsd.sh

# Fix for fan not working after reboot on Raspberry Pi OS Lite
sed -i '/ExecStart/ s/$/  -n 127.0.0.1/' /lib/systemd/system/pigpiod.service
sudo systemctl enable pigpiod

CUR_DIR=$(pwd)
# sudo sed -i "$ i python3 ${CUR_DIR}/fan.py &" /etc/rc.local	# old
# new
cp ${CUR_DIR}/fan.py /usr/local/bin/
chmod +x /usr/local/bin/fan.py
cp ${CUR_DIR}/x-c1-fan.service /etc/systemd/system/
cp ${CUR_DIR}/x-c1-pwr.service /etc/systemd/system/
sudo systemctl enable x-c1-fan
sudo systemctl enable x-c1-pwr
# new end


#sudo echo "alias xoff='sudo x-c1-softsd.sh'" >> /home/pi/.bashrc
sudo pigpiod
python3 /usr/local/bin/fan.py &

echo "The installation is complete."
echo "Please run 'sudo reboot' to reboot the device."
echo "NOTE:"
#echo "1. DON'T modify the name fold: $(basename ${CUR_DIR}), or the PWM fan will not work after reboot."
echo "1. fan.py is python file to control fan speed according temperature of CPU, you can modify it according your needs."
echo "2. PWM fan needs a PWM signal to start working. If fan doesn't work in third-party OS afer reboot only remove the YELLOW wire of fan to let the fan run immediately or contact us: info@geekworm.com."
