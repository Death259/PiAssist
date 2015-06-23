In a nutshell, this is a BASH script file that I hope will make configuring/using your raspberry pi that much easier. I'm testing this only with a RetroPIE install, but most if not all of the functionality should carry over to other linux distributions (Raspbian, OpenELEC, etc.) that can run on the Pi.

The planned functionality of this project is to provide general system information (network, remaining storage space, etc.), connecting/removing bluetooth devices, configuring game controllers (for use with emulators), connecting to WiFi networks and whatever else I can come up with.

Here's the menu options currently available to let you know what the system is capable of:

1. Network (WiFi/Ethernet)
    1. Display Network Information
    2. Scan for WiFi Networks
    3. Connect to WiFi network (Root Required)
2. Bluetooth
    1. Install Bluetooth Packages (Root Required)
    2. Connect Bluetooth Device
    3. Remove Bluetooth Device
    4. Display Registered & Connected Bluetooth Devices
3. Controller
    1. Configure Game Controller (Root Required)
4. System Info
    1. Display System Information
    2. Display Disk Space
    3. Display Home Space Utilization
5. Add PiAssist to Emulation Station (Root Required)
6. Power Menu
    1. Shutdown
    2. Reboot
7. Update PiAssist
8. Miscellaneous (Root Required)
    1. Change Keyboard Language/Configuration
    2. ROM Scraper Created by SSELPH
    3. Search for File by File Name

Please see the [Wiki](https://github.com/Death259/PiAssist/wiki/) for more detail explanations and instructions.



***
***Libraries Used***

This project utilizes [scraper](https://github.com/sselph/scraper) which was created by [SSELPH](https://github.com/sselph/)
