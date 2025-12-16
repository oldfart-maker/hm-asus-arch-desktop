SYSTEM INSTALL

* Step 0 - Tangle emacs/niri configs
a) cd ~/projects/hm-asus-arch-desktop/home/scripts
b) ./tangle-synch.sh

***
* Step 1 - Create archlinux iso

Creat archlinux iso using balena (Download from archlinux.org/downloads)

***
* Step 2 - Start network

a) iwctl
b) device list
c) station wlan0 scan
d) station wlan0 get-networks
e) station wlan0 connect MySSID (Hangout)

***
* Step 2.5 - Install git
a) sudo pacman -Sy
b) sudo pacman -S git

***
* Step 3 - Boostrap archlinux

# a) mkdir -p ~/projects
b) cd ~/projects
c) git clone https://github.com/oldfart-maker/hm-asus-arch-desktop.git
d) cd /projects/hm-asus-arch-desktop/tools
e) ./bootstrap.sh
f) reboot (remove usb drive)
# 

***
* Step 4 - Run setup

a) Connect to network
a.a) ssh into target system if possible
b) mkdir -p ~/projects
c) cd ~/projects
d) git clone https://github.com/oldfart-maker/hm-asus-arch-desktop.git
e) git clone https://github.com/oldfart-maker/sys-secrets.git
f) cd ~/projects/hm-asus-arch-desktop/tools
g) chmod +x target-setup.sh
h) ./target-setup.sh
i) rm -rf hm-asus-arch-desktop

***
* Step 5 - Mount the external drive (TODO: Automate This!!0

a) sudo mkdir -p /mnt/timeshift
b) sudo mkdir -p /mnt/backup
c) sudo mount /dev/sdc1 /mnt/timeshift
d) sudo mount /dev/sdc2 /mnt/backup

