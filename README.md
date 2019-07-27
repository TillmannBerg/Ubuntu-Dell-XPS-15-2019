# Ubuntu-Dell-XPS-15-2019
How to install Ubuntu on a Dell XPS 15 model from 2019?

This page will explain how to fix a number of issues with the latest Ubuntu 19.04 running on said laptop. Problems addressed are:

- CPU power management
- Changing brightness of OLED screen with brightness keys

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
