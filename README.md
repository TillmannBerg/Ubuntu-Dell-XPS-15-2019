# Ubuntu-Dell-XPS-15-2019
How to install Ubuntu on a Dell XPS 15 model from 2019?

This page will explain how to fix a number of issues with the latest **Ubuntu 19.04** running on said laptop. Older Ubuntu versions will not work. Problems addressed are:

- CPU power management
- Changing brightness of OLED screen with brightness keys
- Enabling hardware acceleration for video decoding in Chrome
- Keyboard backlight

## Installation

The most recent version of Dell notebooks only works with the latest Ubuntu version. Only *Ubuntu 19.04* or later can be successfully run on these machines. While it is possible to install Ubuntu 18.04 LTS, the power management for the latest CPU generation does not work leading to very high power consumption and a CPUpermanently at the thermal limit.  

To install Ubuntu on a Dell XPS 15 you need to set your _Sata Operation_ in the laptops BIOS from _Raid_ to _AHCI_. Plugin a USB stick with the image of the latest Ubuntu and install from the stick.

It is recommended to also install 3rd party software for which one needs to connect the laptop to the internet. *Note:* The internal wifi card does not work during the installation process. To connect to the internet an external WiFi adapter or some other network connection is required.

After the installation is complete, run
```
sudo apt update
sudo apt dist-upgrade -y
```
to update the system to the latest versions.

## CPU power management
Without further configuration the CPU will run quite hot and will quickly drain the battery. Install `powertop` and `thermald` to fix this.
```
sudo apt install -y powertop thermald
```
You can start powertop with `sudo powertop`, navigate to the _Tunables_ section and switch all _Bad_ points to _Good_. Probably not all of them have a big effect, I have not tried, but the processor related points are absolutely required. However, these changes are not permanent and will be reset at reboot. Instead let us create a service that will change these settings at boot time.

The script and setup are taken from [here](https://blog.sleeplessbeastie.eu/2015/08/10/how-to-set-all-tunable-powertop-options-at-system-boot/).

First, create a service with
```
cat << EOF | sudo tee /etc/systemd/system/powertop.service
[Unit]
Description=PowerTOP auto tune

[Service]
Type=idle
Environment="TERM=dumb"
ExecStart=/usr/sbin/powertop --auto-tune

[Install]
WantedBy=multi-user.target
EOF
```
and then enable this service to run at boot time with
```
sudo systemctl daemon-reload
sudo systemctl enable powertop.service
```

Voila, this should give you a laptop using around 7 W of power in idle (with a black screen).

Note: I also tried running with the energy management tool _TLP_ but found it ineffective.

## Screen Brightness (OLED)
When pressing the function keys to change the screen brightness, you will see the Ubuntu brightness icon and its brightness bar changing. However, the brightness of the screen will not change. Apparently, Ubuntu tries to change the background brightness of the screen. Since OLED screens do not have a background illumination, nothing happens.

This is undesirable. Not only will the screen often be too bright, it will also age the display faster. It is possible to change the brightness of the screen from the command line via
```
xrandr --output eDP-1 --brightness 0.6
```
to 60 % in this case. The output display `eDP-1` might change, if you should use the Nvidia instead of the Intel graphics card. Careful: 0 is black and black on OLED displays is really all black.

The function keys can be mapped to use this command to change the brightness. ([Source for Lenovo Thinkpad](https://askubuntu.com/questions/824949/lenovo-thinkpad-x1-yoga-oled-brightness))

We first create two files that are triggered by the button presses. You need to create a file `/etc/acpi/events/dell-brightness-up` with the content
```
event=video/brightnessup BRTUP 00000086 00000000
action=/etc/acpi/dell-brightness.sh up
```
and a file `/etc/acpi/events/dell-brightness-down` with the content
```
event=video/brightnessdown BRTDN 00000087 00000000
action=/etc/acpi/dell-brightness.sh down
```

Finally, we need a script executing the required `xrandr` command. Copy [this script](dell-brightness.sh) to `/etc/acpi/dell-brightness.sh` and grand it execution rights with `sudo chmod u+x /etc/acpi/dell-brightness.sh`.

After all scripts have been added reload the acpi daemon so that they can have an effect, `sudo acpid reload`. If the behavior is unexpected, a machine reboot may help.

Note that OLED displays only consume energy and age when the individual pixels are emitting light. Hence, it is advisable to choose dark background colors and install a dark scheme in your browser.

## Hardware Acceleration in Chromium
To be able to watch Youtube and other videos from a browser without draining the battery very quickly hardware acceleration for video decoding is required. Unfortunately, neither Googles Chrome(ium) nor Firefox offer hardware acceleration for Linux. There is a private Chromium package on offer that has hardware acceleration enabled, though. Beware that adding private package repositories introduces a security risk and that the following Chromium is based on the less stable beta version. Use at own risk.

Add the private repository and install Chromium via:
```
sudo add-apt-repository ppa:saiarcot895/chromium-beta
sudo apt update
sudo apt install chromium-browser
```
For more details and instructions on possibly required driver updates see [here](https://www.linuxuprising.com/2018/08/how-to-enable-hardware-accelerated.html).

## Keyboard backlight
Keyboard backlight can be properly enable changing in `/etc/default/grub` then GRUB_CMDLINE_LINUX_DEFAULT setting to:

    GRUB_CMDLINE_LINUX_DEFAULT="quiet splash acpi_osi"

Adding `acpi_osi=` instructs the kernel to reply with an empty string (instead of 'Linux') when the BIOS queries about the running OS.

Remember to run `sudo update-grub; sudo reboot` to make the changes effective.
