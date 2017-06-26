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