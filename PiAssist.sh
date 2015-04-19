#!/bin/bash

DIALOG_CANCEL=1
DIALOG_ESC=255
HEIGHT=0
WIDTH=0

display_result() {
  dialog --title "$1" \
    --no-collapse \
    --msgbox "$result" 0 0
}

while true; do
  exec 3>&1
  maineMenuSelection=$(dialog \
    --backtitle "Pi Assist" \
    --title "Main Menu" \
    --clear \
    --cancel-label "Exit" \
    --menu "Please select:" $HEIGHT $WIDTH 4 \
    "1" "Network (WiFi/Ethernet)" \
    "2" "Bluetooth" \
	"3" "Controller (Retropie only currently)" \
    "4" "System Info" \
    2>&1 1>&3)
  exit_status=$?
  exec 3>&-
  case $exit_status in
    $DIALOG_CANCEL)
      clear
      #echo "Program terminated."
      exit
      ;;
    $DIALOG_ESC)
      clear
      #echo "Program aborted." >&2
      exit 1
      ;;
  esac
  case $maineMenuSelection in
	0 )
		clear
		;;
	1 )
		stayInNetworkMenu=true
		while $stayInNetworkMenu; do
			exec 3>&1
			networkMenuSeleciton=$(dialog \
				--backtitle "Pi Assist" \
				--title "System Information" \
				--clear \
				--cancel-label "Back" \
				--menu "Please select:" $HEIGHT $WIDTH 3 \
				"1" "Display Network Information" \
				"2" "Scan for WiFI Networks" \
				"3" "Connect to WiFi Network (Root Required)" \
				2>&1 1>&3)
			exit_status=$?
			case $exit_status in
				$DIALOG_CANCEL)
				  stayInNetworkMenu=false
				  ;;
				$DIALOG_ESC)
				  stayInNetworkMenu=false
				  ;;
			esac
			case $networkMenuSeleciton in
				0 )
				  stayInNetworkMenu=false
				  ;;
				1 )
					result=$(ifconfig)
					display_result "Network Information"
					;;
				2 )
					result=$(iwlist wlan0 scan | grep ESSID | sed 's/ESSID://g;s/"//g;s/^ *//;s/ *$//')
					display_result "WiFi Networks"
					;;
				3 )
					wifiNetworkList=$(iwlist wlan0 scan | grep ESSID | sed 's/ESSID://g;s/"//g;s/^ *//;s/ *$//')
					wifiSSID=$(dialog --title "WiFi Network SSID" --backtitle "Pi Assist" --inputbox "Network List: \n\n$wifiNetworkList \n\nEnter the SSID of the WiFi network you would like to connect to:" 0 0 2>&1 1>&3);
					if [ $wifiSSID != "" ] ; then
						wifiPassword=$(dialog --title "WiFi Network Password" --backtitle "Pi Assist" --passwordbox "Enter the password of the WiFi network you would like to connect to:" 0 0 2>&1 1>&3);
						turnOnWifiResult=$(ifconfig wlan0 up)
						connectionResults=$(iwconfig wlan0 essid $wifiSSID key s:$wifiPassword)
						dhcpResult=$(dhclient wlan0)
						result=$(echo $turnOnWifiResult $connectionResults $dhcpResult)
						display_result "WiFi Network Connection"
						if [ $turnOnWifiResult == "" ] && [ $connectionResults == "" ] && [ $dhcpResult == "" ] ; then
							result=$(echo "You are now connected to the $wifiSSID network")
							display_result "WiFi Network Connection"
						else
							result=$(echo "An issue occurred connecting to the WiFi network. ")
							display_result "WiFi Network Connection"
						fi
					fi
				;;
			esac
		done
		;;
	2 )
		stayInBluetoothMenu=true
		while $stayInBluetoothMenu; do
			exec 3>&1
			bluetoothMenuSeleciton=$(dialog \
				--backtitle "Pi Assist" \
				--title "System Information" \
				--clear \
				--cancel-label "Back" \
				--menu "Please select:" $HEIGHT $WIDTH 4 \
				"1" "Install Bluetooth Packages (Root Required)" \
				"2" "Connect Bluetooth Device" \
				"3" "Remove Bluetooth Device" \
				"4" "Display Registered & Connected Bluetooth Devices" \
				2>&1 1>&3)
			exit_status=$?
			case $exit_status in
				$DIALOG_CANCEL)
				  stayInBluetoothMenu=false
				  ;;
				$DIALOG_ESC)
				  stayInBluetoothMenu=false
				  ;;
			esac
			case $bluetoothMenuSeleciton in
				0 )
					stayInBluetoothMenu=false
					;;
				1 )
					currentUser=$(whoami)
					if [ $currentUser == "root" ] ; then
						packageInstalled=false
						bluetoothInstalled=$(dpkg -s bluetooth | sed -n 2p)
						if [ "$bluetoothInstalled" != 'Status: install ok installed' ] ; then
							packageInstalled=true
						fi
						bluezutilsInstalled=$(dpkg -s bluez-utils | sed -n 2p)
						if [ "$bluezutilsInstalled" != "Status: install ok installed" ] ; then
							packageInstalled=true
						fi
						bluemanInstalled=$(dpkg -s blueman | sed -n 2p)
						if [ "$bluemanInstalled" != "Status: install ok installed" ] ; then
							packageInstalled=true
						fi
						if [ $packageInstalled == false ] ; then
							result=$(echo "You already have all of the necessary packages installed.")
							display_result "Bluetooth"
						else
							#install packages then ask to reboot
							apt-get install bluetooth bluez-utils blueman
							askToRebootMenuSelection=$(dialog \
								--title "Reboot?" --clear \
								--yesno "Missing packages were installed. Your Pi needs to be rebooted. Okay to Reboot?" $HEIGHT $WIDTH \
								2>&1 1>&3)
							if [ "$askToRebootMenuSelection" == 0 ] ; then
								shutdown -r now
							fi
						fi
					else
						result=$(echo "You have to be running the script as root in order to install packages. Please try using sudo.")
						display_result "Bluetooth"
					fi
					;;
				2 )
					bluetoothDeviceList=$(hcitool scan | sed -e 1d)
					if [ "$bluetoothDeviceList" == "" ] ; then
						result="No devices were found. Ensure device is on and try again."
						display_result "Connect Bluetooth Device"
					else
						bluetoothMacAddress=$(dialog --title "Connect Bluetooth Device" --backtitle "Pi Assist" --inputbox "Device List: \n\n$bluetoothDeviceList \n\nEnter the mac address of the device you would like to conect to:" 0 0 2>&1 1>&3);
						if [ $bluetoothMacAddress != "" ] ; then
							bluez-simple-agent hci0 $bluetoothMacAddress
							bluez-test-device trusted $bluetoothMacAddress yes
							bluez-test-input connect $bluetoothMacAddress
						fi
					fi
					;;
				3 )
					bluetoothDeviceList=$(bluez-test-device list)
					bluetoothMacAddress=$(dialog --title "Remove Bluetooth Device" --backtitle "Pi Assist" --inputbox "Device List: \n\n$bluetoothDeviceList \n\nEnter the mac address of the device you would like to remove:" 0 0 2>&1 1>&3);
					removeBluetoothDevice=$(bluez-test-device remove $bluetoothMacAddress)
					if [ $removeBluetoothDevice == "" ] ; then
						removeBluetoothDevice="Device Removed"
					fi
					result=$removeBluetoothDevice
					display_result "Removing Bluetooth Device"
					;;
				4 )
					registeredDevices="There are no registered devices"
					if [ "$(bluez-test-device list)" != "" ] ; then
						registeredDevices=$(bluez-test-device list)
					fi
					activeConnections="There are no active connections"
					if [ "$(hcitool con)" != "Connections:" ] ; then
						activeConnections=$(hcitool con | sed -e 1d)
					fi
										
					result=$(echo ""; echo "Registered Devices:"; echo ""; echo "$registeredDevices"; echo ""; echo ""; echo "Active Connections:"; echo ""; echo "$activeConnections")
					display_result "Registered Devices & Active Connections"
					;;
			esac
		done
		;;
	3 )
		stayInControllerMenu=true
		while $stayInControllerMenu; do
			exec 3>&1
			controllerMenuSeleciton=$(dialog \
				--backtitle "Pi Assist" \
				--title "Controller" \
				--clear \
				--cancel-label "Back" \
				--menu "Please select:" $HEIGHT $WIDTH 3 \
				"1" "Configure Game Controller (Root Required)" \
				2>&1 1>&3)
			exit_status=$?
			case $exit_status in
				$DIALOG_CANCEL)
				  stayInControllerMenu=false
				  ;;
				$DIALOG_ESC)
				  stayInControllerMenu=false
				  ;;
			esac
			case $controllerMenuSeleciton in
				0 )
				  stayInControllerMenu=false
				  ;;
				1 )
					currentUser=$(whoami)
					if [ $currentUser == "root" ] ; then
						joyconfigLocation="/opt/retropie/configs/all/retroarch.cfg"
						response=$(dialog --title "Create Backup?" --inputbox "Would you like to create a backup of your current retroarch config?" 0 0 2>&1 1>&3)
						response=${response,,}    # tolower
						if [[ $response =~ ^(yes|y)$ ]] ; then
							if [ ! -f $joyconfigLocation"_bak" ] ; then
								cp $joyconfigLocation $joyconfigLocation"_bak"
							else
								backupExistsResponse=$(dialog --title "Overwrite Backup?" --inputbox "A backup currently exists. Do you want to overwrite it?" 0 0 2>&1 1>&3)
								backupExistsResponse=${backupExistsResponse,,}    # tolower
								if [[ $backupExistsResponse =~ ^(yes|y)$ ]] ; then
									cp $joyconfigLocation $joyconfigLocation"_bak"
								fi
								/opt/retropie/emulators/retroarch/retroarch-joyconfig -o $joyconfigLocation
							fi		
						else
							/opt/retropie/emulators/retroarch/retroarch-joyconfig -o $joyconfigLocation
						fi
					else
						result=$(echo "You have to be running the script as root in order to configure controllers. Please try using sudo.")
						display_result "Configure Controller"
					fi
			esac
		done
		;;
	4 )
		stayInSystemInfoMenu=true
		while $stayInSystemInfoMenu; do
			exec 3>&1
			systemInfoMenuSeleciton=$(dialog \
				--backtitle "Pi Assist" \
				--title "System Information" \
				--clear \
				--cancel-label "Back" \
				--menu "Please select:" $HEIGHT $WIDTH 3 \
				"1" "Display System Information" \
				"2" "Display Disk Space" \
				"3" "Display Home Space Utilization" \
				2>&1 1>&3)
			exit_status=$?
			case $exit_status in
				$DIALOG_CANCEL)
				  stayInSystemInfoMenu=false
				  ;;
				$DIALOG_ESC)
				  stayInSystemInfoMenu=false
				  ;;
			esac
			case $systemInfoMenuSeleciton in
				0 )
				  stayInSystemInfoMenu=false
				  ;;
				1 )
				  result=$(echo "Hostname: $HOSTNAME"; uptime)
				  display_result "System Information"
				  ;;
				2 )
				  result=$(df -h)
				  display_result "Disk Space"
				  ;;
				3 )
				  if [[ $(id -u) -eq 0 ]]; then
					result=$(du -sh /home/* 2> /dev/null)
					display_result "Home Space Utilization (All Users)"
				  else
					result=$(du -sh $HOME 2> /dev/null)
					display_result "Home Space Utilization ($USER)"
				  fi
				  ;;
			esac
		done
		;;
	esac
done