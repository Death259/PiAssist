In a nutshell, this is a BASH script file that I hope will make configuring/using your raspberry pi that much easier. I'm testing this only with a RetroPIE install, but most if not all of the functionality should carry over to other linux distributions (Raspbian, OpenELEC, etc.) that can run on the Pi.

The planned functionality of this project is to provide general system information (network, remaining storage space, etc.), connecting/removing bluetooth devices, configuring game controllers (for use with emulators) and connecting to WiFi networks.

Here's the menu options currently available to let you know what the system is capable of:

    Network (WiFi/Ethernet)
        Display Network Information
        Scan for WiFi Networks
        Connect to WiFi network (Root Required)
    Bluetooth
        Install Bluetooth Packages (Root Required)
        Connect Bluetooth Device
        Remove Bluetooth Device
        Display Registered & Connected Bluetooth Devices
    Controller
        Configure Game Controller (Root Required)
    System Info
        Display System Information
        Display Disk Space
        Display Home Space Utilization
		

Please see the [Wiki](https://github.com/Death259/PiAssist/wiki/) for more detail explanations and instructions.
