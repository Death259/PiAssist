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

