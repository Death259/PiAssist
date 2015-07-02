#!/bin/bash

DIALOG_CANCEL=1
DIALOG_ESC=255
HEIGHT=0
WIDTH=0
emulationStationConfig='/etc/emulationstation/es_systems.cfg'

display_result() {
  whiptail --title "$1" \
	--backtitle "PiAssist" \
    --clear \
    --msgbox "$result" 0 0
}

showNetworkMenuOptions() {
	stayInNetworkMenu=true
	while $stayInNetworkMenu; do
		exec 3>&1
		networkMenuSeleciton=$(whiptail \
			--backtitle "PiAssist" \
			--title "System Information" \
			--clear \
			--cancel-button "Back" \
			--menu "Please select:" $HEIGHT $WIDTH 3 \
			"1" "Display Network Information" \
			"2" "Scan for WiFI Networks (Root Required)" \
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
				currentUser=$(whoami)
				if [ $currentUser == "root" ] ; then
					ifconfig wlan0 up
					result=$(iwlist wlan0 scan | grep ESSID | sed 's/ESSID://g;s/"//g;s/^ *//;s/ *$//')
					display_result "WiFi Networks"
				else
					result=$(echo "You have to be running the script as root in order to scan for WiFi networks. Please try using sudo.")
					display_result "WiFi Network"
				fi
				;;
			3 )
				currentUser=$(whoami)
				if [ $currentUser == "root" ] ; then
					ifconfig wlan0 up
					wifiNetworkList=$(iwlist wlan0 scan | grep ESSID | sed 's/ESSID://g;s/"//g;s/^ *//;s/ *$//')
					wifiSSID=$(whiptail --title "WiFi Network SSID" --backtitle "PiAssist" --inputbox "Network List: \n\n$wifiNetworkList \n\nEnter the SSID of the WiFi network you would like to connect to:" 0 0 2>&1 1>&3);
					if [ "$wifiSSID" != "" ] ; then
						actuallyConnectToWifi=false
						networkInterfacesConfigLocation="/etc/network/interfaces"
						
						if (whiptail --title "Create Backup?" --yesno "Would you like to create a backup of your current network interfaces config?" 0 0) then
							if [ ! -f $networkInterfacesConfigLocation"_bak" ] ; then
								cp $networkInterfacesConfigLocation $networkInterfacesConfigLocation"_bak"
							else
								if (whiptail --title "Overwrite Backup?" --yesno "A backup currently exists. Do you want to overwrite it?" 0 0) then
									cp $networkInterfacesConfigLocation $networkInterfacesConfigLocation"_bak"
								fi
								actuallyConnectToWifi=true
							fi		
						else
							actuallyConnectToWifi=true
						fi
						if [ $actuallyConnectToWifi == true ] ; then
							wifiPassword=$(whiptail --title "WiFi Network Password" --backtitle "PiAssist" --passwordbox "Enter the password of the WiFi network you would like to connect to:" 10 70 2>&1 1>&3);
							if [ ! "$wifiPassword" == "" ] ; then
								echo -e 'auto lo\n\niface lo inet loopback\niface eth0 inet dhcp\n\nallow-hotplug wlan0\nauto wlan0\niface wlan0 inet dhcp\n\twpa-ssid "'$wifiSSID'"\n\twpa-psk "'$wifiPassword'"' > $networkInterfacesConfigLocation
								ifdown wlan0 > /dev/null 2>&1
								ifup wlan0 > /dev/null 2>&1
								
								inetAddress=$(ifconfig wlan0 | grep "inet addr.*")
								if [ "$inetAddress" != "" ] ; then
									result=$(echo "You are now connected to $wifiSSID.")
									display_result "WiFi Network"
								else
									result=$(echo "There was an issue trying to connect to $wifiSSID. Please ensure you typed the SSID and password correctly.")
									display_result "WiFi Network"
								fi
							fi
						fi
					fi
				else
					result=$(echo "You have to be running the script as root in order to connect to a WiFi network. Please try using sudo.")
					display_result "WiFi Network"
				fi
			;;
		esac
	done
}

showBluetoothMenuOptions() {
	stayInBluetoothMenu=true
	while $stayInBluetoothMenu; do
		exec 3>&1
		bluetoothMenuSeleciton=$(whiptail \
			--backtitle "PiAssist" \
			--title "System Information" \
			--clear \
			--cancel-button "Back" \
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
					bluetoothInstalled=$(dpkg -l bluetooth 2>&1)
					if [ "$bluetoothInstalled" == 'dpkg-query: no packages found matching bluetooth' ] ; then
						packageInstalled=true
					fi
					bluezutilsInstalled=$(dpkg -l bluez-utils 2>&1)
					if [ "$bluezutilsInstalled" == "dpkg-query: no packages found matching bluez-utils" ] ; then
						packageInstalled=true
					fi
					bluemanInstalled=$(dpkg -l blueman 2>&1)
					if [ "$bluemanInstalled" == "dpkg-query: no packages found matching blueman" ] ; then
						packageInstalled=true
					fi
					if [ $packageInstalled == false ] ; then
						result=$(echo "You already have all of the necessary packages installed.")
						display_result "Bluetooth"
					else
						#install packages then ask to reboot
						apt-get -qq update > /dev/null && apt-get -qq install bluetooth bluez-utils blueman >/dev/null & # Run in background, with output redirected
						pid=$! # Get PID of background command
						
						i=1
						sp="/-\|"
						echo -n 'Installing Bluetooth Packages '
						while kill -0 $pid  # Signal 0 just tests whether the process exists
						do
							printf "\r${sp:i%${#sp}:1} Installing Bluetooth Packages ${sp:i++%${#sp}:1}"
							sleep 0.5
						done
						
						if (whiptail --title "Reboot?" --yesno "Missing packages were installed. Your Pi needs to be rebooted. Okay to Reboot?" 0 0) then
							clear
							shutdown -r now
							exit
						fi
					fi
				else
					result=$(echo "You have to be running the script as root in order to install packages. Please try using sudo.")
					display_result "Bluetooth"
				fi
				;;
			2 )
				echo "Scanning..."
				bluetoothDeviceList=$(hcitool scan --flush | sed -e 1d)
				if [ "$bluetoothDeviceList" == "" ] ; then
					result="No devices were found. Ensure device is on and try again."
					display_result "Connect Bluetooth Device"
				else
					result_file=$(mktemp)
					trap "rm $result_file" EXIT
					readarray devs < <(hcitool scan | tail -n +2 | awk '{print NR; print $0}')
					dialog --menu "Select device" 20 80 15 "${devs[@]}" 2> $result_file
					exit_status=$?
					deviceAcutallySelected=true
					case $exit_status in
						$DIALOG_CANCEL)
						  deviceAcutallySelected=false
						  ;;
						$DIALOG_ESC)
						  deviceAcutallySelected=false
						  ;;
					esac
					if [ $deviceAcutallySelected == true ] ; then
						arrayResult=$(<$result_file)
						#answer={devs[$((arrayResult+1))]}
						answer=${devs[$arrayResult+($arrayResult -1)]}
						
						bluetoothMacAddress=($answer)
						
						bluez-simple-agent hci0 "$bluetoothMacAddress"
						bluez-test-device trusted "$bluetoothMacAddress" yes
						bluez-test-input connect "$bluetoothMacAddress"
						
						result="Bluetooth device has been connected"
						display_result "Connect Bluetooth Device"
					fi
				fi
				;;
			3 )				
				bluetoothDeviceList=$(bluez-test-device list)
				if [ "$bluetoothDeviceList" == "" ] ; then
					result="There are no devices to remove."
					display_result "Remove Bluetooth Device"
				else
					result_file=$(mktemp)
					trap "rm $result_file" EXIT
					readarray devs < <(bluez-test-device list | awk '{print NR; print $0}')
					dialog --menu "Select device" 20 80 15 "${devs[@]}" 2> $result_file
					exit_status=$?
					deviceAcutallySelected=true
					case $exit_status in
						$DIALOG_CANCEL)
						  deviceAcutallySelected=false
						  ;;
						$DIALOG_ESC)
						  deviceAcutallySelected=false
						  ;;
					esac
					if [ $deviceAcutallySelected == true ] ; then
						arrayResult=$(<$result_file)
						#answer={devs[$((arrayResult+1))]}
						answer=${devs[$arrayResult+($arrayResult -1)]}
						bluetoothMacAddress=($answer)
						
						if [ "$bluetoothMacAddress" != "" ] ; then
							removeBluetoothDevice=$(bluez-test-device remove $bluetoothMacAddress)
							if [ "$removeBluetoothDevice" == "" ] ; then
								result="Device Removed"
								display_result "Removing Bluetooth Device"
							else
								result="An error occured removing the bluetooth device. Please ensure you typed the mac address correctly."
								display_result "Removing Bluetooth Device"
							fi
						fi
					fi
				fi
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
}

showControllerMenuOptions() {
	stayInControllerMenu=true
	while $stayInControllerMenu; do
		exec 3>&1
		controllerMenuSeleciton=$(whiptail \
			--backtitle "PiAssist" \
			--title "Controller" \
			--clear \
			--cancel-button "Back" \
			--menu "Please select:" $HEIGHT $WIDTH 3 \
			"1" "Configure Game Controller for RetroArch Emulators (Root Required)" \
			"2" "Setup PS3 Controller over Bluetooth (Root Required) - Work in Progress" \
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
					if (whiptail --title "Create Backup?" --yesno "Would you like to create a backup of your current retroarch config?" 0 0) then
						if [ ! -f $joyconfigLocation"_bak" ] ; then
							cp $joyconfigLocation $joyconfigLocation"_bak"
						else
							if (whiptail --title "Overwrite Backup?" --yesno "A backup currently exists. Do you want to overwrite it?" 0 0) then
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
				;;
			2 )
				currentUser=$(whoami)
				if [ $currentUser == "root" ] ; then
					if [ command -v >/dev/null 2>&1 || ] ; then
						wget http://www.pabr.org/sixlinux/sixpair.c
						gcc -o sixpair sixpair.c -lusb
						
						wget http://sourceforge.net/projects/qtsixa/files/QtSixA%201.5.1/QtSixA-1.5.1-src.tar.gz
						tar xfvz QtSixA-1.5.1-src.tar.gz
						cd QtSixA-1.5.1/sixad
						make
						mkdir -p /var/lib/sixad/profiles
						checkinstall
						
						update-rc.d sixad defaults
						
						echo "enable_leds 1" >> /var/lib/sixad/profiles/default
						echo "enable_joystick 1" >> /var/lib/sixad/profiles/default
						echo "enable_input 0" >> /var/lib/sixad/profiles/default
						echo "enable_remote 0" >> /var/lib/sixad/profiles/default
						echo "enable_rumble 1" >> /var/lib/sixad/profiles/default
						echo "enable_timeout 0" >> /var/lib/sixad/profiles/default
						echo "led_n_auto 1" >> /var/lib/sixad/profiles/default
						echo "led_n_number 1" >> /var/lib/sixad/profiles/default
						echo "led_anim 1" >> /var/lib/sixad/profiles/default
						echo "enable_buttons 1" >> /var/lib/sixad/profiles/default
						echo "enable_sbuttons 1" >> /var/lib/sixad/profiles/default
						echo "enable_axis 1" >> /var/lib/sixad/profiles/default
						echo "enable_accel 0" >> /var/lib/sixad/profiles/default
						echo "enable_accon 0" >> /var/lib/sixad/profiles/default
						echo "enable_speed 0" >> /var/lib/sixad/profiles/default
						echo "enable_pos 0" >> /var/lib/sixad/profiles/default
						
						if (whiptail --title "Reboot?" --yesno "Missing prerequisites were installed. Your Pi needs to be rebooted. Okay to Reboot?" 0 0) then
							shutdown -r now
						fi
					fi
					
					result=$(echo "Please plugin the PS3 controller you would like to pair via USB.")
					display_result "PS3 Controller"
					
					./sixpair

					if [ status sixad ] ; then
						service sixad start
					fi
					
				else
					result=$(echo "You have to be running the script as root in order to install PS3 controller prerequisites. Please try using sudo.")
					display_result "Configure Controller"
				fi
				;;
		esac
	done
}

showSystemInfoOptions() {
	stayInSystemInfoMenu=true
	while $stayInSystemInfoMenu; do
		exec 3>&1
		systemInfoMenuSeleciton=$(whiptail \
			--backtitle "PiAssist" \
			--title "System Information" \
			--clear \
			--cancel-button "Back" \
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
				result=$(echo "Hostname:  $HOSTNAME\n"; echo "Uptime:"; uptime | sed 's/,.*//'; echo "\nLoad Average: "; uptime | grep -o "load.*" | cut -c 15-; echo "\nTemperature: "; vcgencmd measure_temp | cut -c 6-)
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
}

addAndUpdateEmulationStationEntries() {
	#Download Theme from GitHub and place it in the emulation station themes directory (/etc/emulationstation/themes/simple)
	piassitThemeLocation="/etc/emulationstation/themes/simple/piassist/"
	mkdir "$piassitThemeLocation" > /dev/null 2>&1
	mkdir "$piassitThemeLocation"art/ > /dev/null 2>&1
	wget https://raw.githubusercontent.com/Death259/PiAssist/master/Emulation%20Station%20Theme/piassist/theme.xml -q -O "$piassitThemeLocation"/theme.xml
	wget https://raw.githubusercontent.com/Death259/PiAssist/master/Emulation%20Station%20Theme/piassist/art/piassist.png -q -O "$piassitThemeLocation"/art/piassist.png
	wget https://raw.githubusercontent.com/Death259/PiAssist/master/Emulation%20Station%20Theme/piassist/art/piassist_pixelated.png -q -O "$piassitThemeLocation"/art/piassist_pixelated.png

	mkdir /home/pi/PiAssist/ > /dev/null 2>&1
	find /home/pi/PiAssist/ -name "*.sh" -delete
	touch "/home/pi/PiAssist/Launch PiAssist.sh"
	touch "/home/pi/PiAssist/Update PiAssist.sh"
	touch "/home/pi/PiAssist/Backup Save Files to Dropbox.sh"

	chown -R pi:pi /home/pi/PiAssist/
}

addPiAssistToEmulationStation() {
	currentUser=$(whoami)
	if [ $currentUser == "root" ] ; then
		if grep -q piassist "$emulationStationConfig"; then
			result="PiAssist has already been added to Emulation Station"
			display_result "Add PiAssist to Emulation Station"
		else
			piassistConfigLocation="/home/pi/piassist_es.cfg"
			cat > "$piassistConfigLocation" << EOF
  </system>
  <system>
    <name>piassist</name>
    <fullname>PiAssist</fullname>
    <path>~/PiAssist/</path>
    <extension>.sh</extension>
    <command>sudo /home/pi/PiAssist.sh %ROM%</command>
    <platform/>
    <theme>piassist</theme>
EOF
			sed -i "/<theme>pcengine<\/theme>/r $piassistConfigLocation" "$emulationStationConfig"
			rm "$piassistConfigLocation"
			
			addAndUpdateEmulationStationEntries

			result=$(echo "PiAssist has been added to the Emulation Station menu")
			display_result "Add PiAssist to Emulation Station"				
		fi
	else
		result=$(echo "You have to be running the script as root in order to add PiAssist to emulation station. Please try using sudo.")
		display_result "Add PiAssist to Emulation Station"
	fi
}

showPowerMenuOptions() {
	currentUser=$(whoami)
	if [ "$currentUser" == "root" ] ; then
		stayInPowerOptionsMenu=true
		while $stayInPowerOptionsMenu; do
			exec 3>&1
			systemInfoMenuSeleciton=$(whiptail \
				--backtitle "PiAssist" \
				--title "Power Menu" \
				--clear \
				--cancel-button "Back" \
				--menu "Please select:" $HEIGHT $WIDTH 2 \
				"1" "Shutdown" \
				"2" "Reboot" \
				2>&1 1>&3)
			exit_status=$?
			case $exit_status in
				$DIALOG_CANCEL)
				  stayInPowerOptionsMenu=false
				  ;;
				$DIALOG_ESC)
				  stayInPowerOptionsMenu=false
				  ;;
			esac
			case $systemInfoMenuSeleciton in
				0 )
				  stayInPowerOptionsMenu=false
				  ;;
				1 )
					shutdown -h now
					;;
				2 )
					shutdown -r now
					;;
			esac
		done
	else
		result=$(echo "You have to be running the script as root in order to access the power menu. Please try using sudo.")
		display_result "Configure Controller"
	fi
}

updatePiAssist() {
	echo "Updating PiAssist..."
	homeDirectory="/home/pi"
	if ! wget -q https://raw.githubusercontent.com/Death259/PiAssist/master/PiAssist.sh -O "$homeDirectory/PiAssist.sh.new" ; then
		result="An error occurred downloading the update."
		display_result "Update PiAssist"
	else
		chmod +x "$homeDirectory/PiAssist.sh.new"
		cat > "$homeDirectory/updateScript.sh" << EOF
#!/bin/bash
if mv "PiAssist.sh.new" "PiAssist.sh"; then
  rm -- \$0
  chown -R pi:pi PiAssist.sh
  ./PiAssist.sh "Update Emulation Station Entries"
  whiptail --title "Update Completed" --msgbox "Update Completed. You need to restart the script." 0 0
  clear
else
  whiptail --title "Update Failed!" --msgbox "There was an issue updating the script" 0 0
  clear
fi
EOF
		exec /bin/bash "$homeDirectory/updateScript.sh"
		exit
	fi
}

backupEmulatorSaveFilesToDropBox() {
	wget https://raw.githubusercontent.com/andreafabrizi/Dropbox-Uploader/master/dropbox_uploader.sh -q -O /home/pi/PiAssist/dropbox_uploader.bsh
	chmod +x /home/pi/PiAssist/dropbox_uploader.bsh

	if [[ -e /home/pi/.dropbox_uploader ]]; then
		/home/pi/PiAssist/dropbox_uploader.bsh
	fi

	#find /home/pi/RetroPie/roms/ -iname '*.srm' -o -iname '*.bsv' -o -iname '*.sav' | while read line; do
	#	remotePath="$(basename "$(dirname "$line")")"/"${line##*/}"
	#	/home/pi/PiAssist/dropbox_uploader.bsh upload "$line" "$remotePath"
	#done
	
	gameSavesFileName="GameSaves.tar.gz"
	find /home/pi/RetroPie/roms/ \( -iname '*.srm' -o -iname '*.bsv' -o -iname '*.sav' \) -print0 | tar -czvf "$gameSavesFileName" --null -T -
	/home/pi/PiAssist/dropbox_uploader.bsh upload "$gameSavesFileName" "$gameSavesFileName"
	rm "$gameSavesFileName"

	result="All known saved files have been backed up."
	display_result "Saved Files Backed Up"
}

showMiscellaneousMenuOptions() {
	currentUser=$(whoami)
	if [ "$currentUser" == "root" ] ; then
		stayInMiscellaneousOptionsMenu=true
		while $stayInMiscellaneousOptionsMenu; do
			exec 3>&1
			miscellaneousMenuSeleciton=$(whiptail \
				--backtitle "PiAssist" \
				--title "Miscellaneous" \
				--clear \
				--cancel-button "Back" \
				--menu "Please select:" $HEIGHT $WIDTH 3 \
				"1" "Change Keyboard Language/Configuration" \
				"2" "ROM Scraper Created by SSELPH" \
				"3" "Search for File by File Name" \
				"4" "Backup Emulator Save files to DropBox (Thanks to andreafabrizi)" \
				2>&1 1>&3)
			exit_status=$?
			case $exit_status in
				$DIALOG_CANCEL)
				  stayInMiscellaneousOptionsMenu=false
				  ;;
				$DIALOG_ESC)
				  stayInMiscellaneousOptionsMenu=false
				  ;;
			esac
			case $miscellaneousMenuSeleciton in
				0 )
					stayInMiscellaneousOptionsMenu=false
					;;
				1 )
					dpkg-reconfigure keyboard-configuration
					;;					
				2 )
					
					# Check if emulationstation is running
					if pgrep -f "emulationstation" > /dev/null
					then
						result="Emulation Station cannot be running while scraping roms. Please quit Emulation station and run PiAssist from command line."
						display_result "Rom Scraper"
					else
						scraperVersion=$(wget -qO- https://api.github.com/repos/sselph/scraper/releases/latest | grep tag_name | sed -e 's/.*"tag_name": "\(.*\)".*/\1/')
						#if scraper doesn't exist then download it
						updateScraper=false
						if [ -f /usr/local/bin/scraper ] ; then
							oldVersion=$(scraper -version 2> /dev/null)
							if [ $? -ne 0 ] || [ "$scraperVersion" != "$oldVersion" ] ; then
								if (whiptail --title "Update Scraper?" --yesno "Would you like to update the scraper script?" 0 0) then
									updateScraper=true
								fi
							fi
						fi
						if [ ! -f /usr/local/bin/scraper ] || [ $updateScraper == true ] ; then
							echo "Downloading and Installing Scraper created by SSELPH..."
							#if raspberrypi1 then download the build for raspberrypi1
							if grep -q ARMv7 /proc/cpuinfo ; then
								wget https://github.com/sselph/scraper/releases/download/$scraperVersion/scraper_rpi2.zip -q
								unzip scraper_rpi2.zip scraper -d /usr/local/bin/
								rm scraper_rpi2.zip
							else
								wget https://github.com/sselph/scraper/releases/download/$scraperVersion/scraper_rpi.zip -q
								unzip scraper_rpi.zip scraper -d /usr/local/bin/
								rm scraper_rpi.zip
							fi
						fi
						
						#show scraper menu - ask user which console they would like to scrape					
						romFolderList=$(ls -d /home/pi/RetroPie/roms/*/)
						if [ "$romFolderList" == "" ] ; then
							result="No rom folders were found. Not quite sure how that's possible..."
							display_result "ROM Scraper"
						else
							result_file=$(mktemp)
							trap "rm $result_file" EXIT
							readarray devs < <(ls -d /home/pi/RetroPie/roms/*/ | awk '{print NR; print $0}')
							dialog --menu "Select ROM Folder" 20 80 15 "${devs[@]}" 2> $result_file
							exit_status=$?
							romFolderAcutallySelected=true
							case $exit_status in
								$DIALOG_CANCEL)
								  romFolderAcutallySelected=false
								  ;;
								$DIALOG_ESC)
								  romFolderAcutallySelected=false
								  ;;
							esac
							if [ $romFolderAcutallySelected == true ] ; then
								arrayResult=$(<$result_file)
								#answer={devs[$((arrayResult+1))]}
								answer=${devs[$arrayResult+($arrayResult -1)]}
								
								romFolder=($answer)
								
								gameListXMLLocation="/home/pi/.emulationstation/gamelists/$(basename $romFolder)/gamelist.xml"
								scraper -image_dir="/home/pi/.emulationstation/downloaded_images/$(basename $romFolder)" -image_path="~/.emulationstation/downloaded_images/$(basename $romFolder)" -output_file="$gameListXMLLocation" -rom_dir="$romFolder"
								
								chown pi:pi "/home/pi/.emulationstation/downloaded_images/$(basename $romFolder)"
								
								#the scraper doesn't include the opening XML tag that is required
								if grep -q "<?xml" "$gameListXMLLocation" ; then
									#no action needs to occur
									echo "" > /dev/null
								else
									echo '<?xml version="1.0"?>' | cat - "$gameListXMLLocation" > temp && mv temp "$gameListXMLLocation"
								fi
								
								chown pi:pi "$gameListXMLLocation"
								
								find "/home/pi/.emulationstation/downloaded_images/$(basename $romFolder)" -exec chown pi:pi {} +
								
								result="ROMS have been scraped. You can  now get back into Emulation Station."
								display_result "ROM Scraper Created by SSELPH"
							fi
						fi
					fi
					;;
					3 )
						fileNameToSearchFor=$(whiptail --title "Search for File by File Name" --backtitle "PiAssist" --inputbox "Enter the file name you would like to search for:" 0 0 2>&1 1>&3);
						#searchOptions=$(dialog --backtitle "PiAssist" --checklist "Search Options:" "Match Whole Words Only" off 2 "Match Case" off 3 Slackware off 0 0 2>&1 1>&3);
						
						#searchOptions=$(dialog --checklist "Choose toppings:" 10 40 3 1 Cheese on 2 "Tomato Sauce" on 3 Anchovies off);
						#dialog --backtitle "PiAssist" --checklist "Select CPU type:" 10 40 4 1 "Match Case" off 2 "Match Whole Words Only" off
						searchOptions=$(whiptail --backtitle "PiAssist" --title "Search Options" --checklist \
						"Choose search options:" 0 0 2 \
						"1" "Match Case" OFF \
						"2" "Match Whole Words Only" OFF \
						3>&1 1>&2 2>&3)
						
						findCommand="find /"
						
						if [[ $searchOptions == *"1"* ]] ; then
							findCommand="$findCommand -name "
						else
							findCommand="$findCommand -iname"
						fi
												
						if [[ $searchOptions == *"2"* ]] ; then
							findCommand="$findCommand '$fileNameToSearchFor'"
						else
							findCommand="$findCommand '*$fileNameToSearchFor*'"
						fi
						
						result=$(eval "$findCommand")
						display_result "Search Results"
					;;
					4 )
						backupEmulatorSaveFilesToDropBox
					;;
			esac
		done
	else
		result=$(echo "You have to be running the script as root in order to access the miscellaneous menu. Please try using sudo.")
		display_result "Miscellaneous"
	fi
}


#########
#Perform actions based on parameters provided to the script. This should generally be from Emulation Station as the %ROM% gets passed in as a parameter.
#########

commandToRun="${1##*/}"
commandToRun="${commandToRun%.*}"
case "$commandToRun" in
	"Update PiAssist" )
		updatePiAssist
	;;
	"Backup Save Files to Dropbox" )
		backupEmulatorSaveFilesToDropBox;
		exit
	;;
	"Update Emulation Station Entries" )
		addAndUpdateEmulationStationEntries;
		exit
	;;
esac

#########
#Perform dialog functions to present users the GUI
#########


while true; do
  exec 3>&1
  maineMenuSelection=$(whiptail \
	--backtitle "PiAssist" \
	--clear \
    --title "Main Menu" \
	--cancel-button "Exit" \
    --menu "Please select:" $HEIGHT $WIDTH 8 \
    "1" "Network (WiFi/Ethernet)" \
    "2" "Bluetooth" \
	"3" "Controller (Retropie Only Currently)" \
    "4" "System Info" \
	"5" "Add PiAssist to Emulation Station (Root Required)" \
	"6" "Power Menu (Root Required)" \
	"7" "Update PiAssist" \
	"8" "Miscellaneous (Root Required)" \
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
		showNetworkMenuOptions
		;;
	2 )
		showBluetoothMenuOptions
		;;
	3 )
		showControllerMenuOptions
		;;
	4 )
		showSystemInfoOptions
		;;
	5 )
		addPiAssistToEmulationStation
		;;
	6 )
		showPowerMenuOptions
		;;
	7 )
		updatePiAssist
		;;
	8 )
		showMiscellaneousMenuOptions
		;;
	esac
done
