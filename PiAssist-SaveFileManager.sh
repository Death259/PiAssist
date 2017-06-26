#!/bin/bash

DIALOG_CANCEL=1
DIALOG_ESC=255
HEIGHT=0
WIDTH=0
emulationStationConfig='/etc/emulationstation/es_systems.cfg'

display_result() {
  whiptail --title "$1" \
	--backtitle "PiAssist - Save File Manager" \
    --clear \
    --msgbox "$result" 0 0
}

#########
#Backup game saves and save states to dropbox
##Take all save files and save states and tar them and gzip them up
##Upload zip file to dropbox
#########

gameSavesFileName="GameSaves.tar.gz"
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
	
	romLocations=$(grep "<path>" /etc/emulationstation/es_systems.cfg | sed "s/<path>//g" | sed "s/<\/path>//g" | sed "s/~/\/home\/pi/g")
	
	find $romLocations \( -iname '*.srm' -o -iname '*.bsv' -o -iname '*.sav' -o -iname '*.state' \) -print0 | tar -czvf "$gameSavesFileName" --null -T -
	#find /home/pi/RetroPie/roms/ \( -iname '*.srm' -o -iname '*.bsv' -o -iname '*.sav' -o -iname '*.state' \) -print0 | tar -czvf "$gameSavesFileName" --null -T -
	/home/pi/PiAssist/dropbox_uploader.bsh upload "$gameSavesFileName" "$gameSavesFileName"
	rm "$gameSavesFileName"

	result="All known saved files have been backed up."
	display_result "Saved Files Backed Up"
}

#########
#Restore save files and save states from a dropbox backup
#########

restoreFromBackupOfEmulatorSaveFilesFromDropBox() {
	wget https://raw.githubusercontent.com/andreafabrizi/Dropbox-Uploader/master/dropbox_uploader.sh -q -O /home/pi/PiAssist/dropbox_uploader.bsh
	chmod +x /home/pi/PiAssist/dropbox_uploader.bsh

	if [[ -e /home/pi/.dropbox_uploader ]]; then
		/home/pi/PiAssist/dropbox_uploader.bsh
	fi
	
	/home/pi/PiAssist/dropbox_uploader.bsh download /"$gameSavesFileName"
	if [[ -e "$gameSavesFileName" ]]; then
		tar -zxvf "$gameSavesFileName" -C / #--strip-components=2 -C /home/pi/
		rm "$gameSavesFileName"
		
		result="All save files have been restored from backup."
		display_result "Restoring Save Files"
	else
		result="Unable to locate the save file backup. Please ensure that the backup name matches $gameSavesFileName."
		display_result "Restoring Save Files"
	fi
}

#########
#Perform actions based on parameters provided to the script. This should generally be from Emulation Station as the %ROM% gets passed in as a parameter.
#########

commandToRun="${1##*/}"
commandToRun="${commandToRun%.*}"
case "$commandToRun" in
	"Backup Save Files to Dropbox" )
		backupEmulatorSaveFilesToDropBox;
		exit
	;;
	"Restore Save Files from Backup" )
		restoreFromBackupOfEmulatorSaveFilesFromDropBox;
		exit
	;;
esac

#########
#Perform dialog functions to present users the GUI
#########

currentUser=$(whoami)
if [ "$currentUser" == "root" ] ; then
	while true; do
	  exec 3>&1
	  maineMenuSelection=$(whiptail \
		--backtitle "PiAssist - Save File Manager" \
		--clear \
		--title "Main Menu" \
		--cancel-button "Exit" \
		--menu "Please select:" $HEIGHT $WIDTH 8 \
		"1" "Backup Emulator Save files to DropBox (Thanks andreafabrizi)" \
		"2" "Restore Save files from Backup on DropBox (Thanks andreafabrizi)" \
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
			backupEmulatorSaveFilesToDropBox
			;;
		2 )
			restoreFromBackupOfEmulatorSaveFilesFromDropBox
			;;
		esac
	done
else
		result=$(echo "PiAssist - Save File Manager has to be running as root. Please try using sudo.")
		display_result "PiAssist"
fi
