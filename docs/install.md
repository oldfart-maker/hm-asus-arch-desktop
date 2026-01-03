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

a) timedatectl set-ntp true
b) sleep 16
c) timedatectl status
d) sudo pacman -Sy archlinux-keyring
e) sudo pacman -S git

***
* Step 3 - Boostrap archlinux

NOTE: The disk partitioning may not be correct causing a full disk. The best way to do this is after performing step d, do:

1) archinstall --config user___configuration.json --creds user___credentials.json
2) update the disk partitioning / ext4
3) save the *.json files to /
4) mv /**.json ~/projects/hm-asus-arch-desktop/tools
5) start step e

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
	a.b) ssh angel
b) mkdir -p ~/projects
c) cd ~/projects
d) git clone https://github.com/oldfart-maker/hm-asus-arch-desktop.git
e) git clone https://github.com/oldfart-maker/sys-secrets.git
f) cd ~/projects/hm-asus-arch-desktop/tools
g) ./target-setup.sh

***
* Step 4.1 - Install dankmaterialshell (if this is the shell you wish to use)

NOTE: The case must be correct: DankMaterialShell

a) ssh into angel
b) dankmaterialshell (walk through prompts)
c) mkdir ~/config/DankMaterialShell
d) cp ~/projects/hm-asus-arch-desktop/home/data/apps/dankmaterialshell/* \
	~/.config/DankMaterialShell

***
* Step 5 - Mount the external drive

NOTE: make sure that the external drive is sdc and change accordingly.

sudo mkdir -p /mnt/timeshift
sudo mkdir -p /mnt/backup
sudo mount /dev/sdc1 /mnt/timeshift
sudo mount /dev/sdc2 /mnt/backup

***
***
* Step 5 - Configure samba

NOTE: Step 5 must be completed before starting the services

a) copy config from repo
	a.a) sudo cp ~/projects/hm-asus-arch-desktop/home/data/apps/smb/smb.conf /etc/smb

NOTE: If step b gives an error add the user to linux first
	b.a) sudo useradd -m username
	b.b) sudo passwd username

b) create samba password
	b.a) sudo smbpasswd -a username
	b.b) sudo smbpasswd -e username
	
c) restart samba
	c.a) sudo systemctl restart nmb,smb

NOTE: to access this drive from windows vm:
1) map network drive in windows:
	1.1) "\\\\\192.168.122.1\\share"

TODO
1) Add samba install to archinstall
2) Setup smb install in boostrap.sh
