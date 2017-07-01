#!/bin/bash

#saveFileExtensions=(srm bsv sav state stat fs nv rtc)
gameSavesFileName="GameSaves.tar.gz"

display_result() {
  whiptail --title "$1" \
	--backtitle "PiAssist - Save File Manager" \
    --clear \
    --msgbox "$result" 0 0
}

#########
#Synchronize save files and save states with a dropbox account
#########

synchronizeSaveFilesWithDropBox() {
	rm -f "$gameSavesFileName"

	#Download dropbox_uploader.bsh and make it executable
	wget https://raw.githubusercontent.com/andreafabrizi/Dropbox-Uploader/master/dropbox_uploader.sh -q -O /home/pi/dropbox_uploader.bsh
	chmod +x /home/pi/dropbox_uploader.bsh
	
	#Download latest backup
	/home/pi/dropbox_uploader.bsh download /"$gameSavesFileName"
	
	#Extract everything from the backup but only overwrite the older files
	if [[ -e "$gameSavesFileName" ]]; then
		tar -zxvf "$gameSavesFileName" -C / --keep-newer-files #--strip-components=2 -C /home/pi/
		rm "$gameSavesFileName"
		
		#Archive all save files and upload to dropbox
		romLocations=$(grep "<path>" /etc/emulationstation/es_systems.cfg | sed "s/<path>//g" | sed "s/<\/path>//g" | sed "s/~/\/home\/pi/g")
		find $romLocations \( -iname '*.srm' -o -iname '*.bsv' -o -iname '*.sav' -o -iname '*.rtc' -o -iname '*.nv' -o -iname '*.fs' -o -iname '*.stat' -o -iname '*.state' \) -print0 | tar -czvf "$gameSavesFileName" --null -T -
		/home/pi/dropbox_uploader.bsh upload "$gameSavesFileName" "$gameSavesFileName"
		
		result="The save files and save states have been synchronized."
		display_result "Synchornization Complete"
	else
		result="Unable to locate the save file backup. Please ensure that the backup name matches $gameSavesFileName."
		display_result "Synchronizing Save Files"
	fi
	
	rm -f "dropbox_uploader.bsh"
	rm -f "$gameSavesFileName"
}

wget -q --tries=10 --timeout=20 --spider http://google.com
if [[ $? -eq 0 ]]; then
		synchronizeSaveFilesWithDropBox
else
		wget -q --tries=10 --timeout=20 --spider http://amazon.com
		if [[ $? -eq 0 ]]; then
				synchronizeSaveFilesWithDropBox
		else
			result="Google and Amazon are unreachable so we are assuming the internet as a whole is unreachable. Please connect to either a WiFi network or local area network."
			display_result "Unable to Connect to the Internet"
		fi
fi
