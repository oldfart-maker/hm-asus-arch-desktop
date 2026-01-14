SYSTEM INSTALL

GIT REBASE (magit)
	a) M-x magit-status
	b) press f
	c) press p - Fetch from origin
	d) press r then p

* Step 0 - Tangle emacs/niri configs
a) cd ~/projects/hm-asus-arch-desktop/home/scripts
b) ./tangle-synch.sh
	NOTE: running ./tangle-synch.sh will generate both the niri config.kdl and all of the emacs.el modules.

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

NOTE: Ensure the disk partitioning is correct. If it is not correct perform the step 1-4, otherwise go to step a.

1) cd ~/projects/hm-asus-arch-desktop/tools
2) ./run-config.sh
3) update the disk partitioning / ext4
4) go to step e

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
* Step 5 - Install dankmaterialshell (if this is the shell you wish to use)

NOTE: The case must be correct: DankMaterialShell

a) ssh ixnto angel
b) dankmaterialshell (walk through prompts)
c) mkdir ~/config/DankMaterialShell
d) cp ~/projects/hm-asus-arch-desktop/home/data/apps/dankmaterialshell/* \
	~/.config/DankMaterialShell
	
***
* Step 6 - github configuration

TODO: If you decide to remove git.nix from home manager then run steps a-e, otherwise skitp to step 1.

a) git config --global user.name "oldfart-maker"
b) git config --global user.email "mkburns61@yahoo.com"
c) git config --global init.defaultBranch main
d) git config --global pull.rebase true
e) git config --global push.autoSetupRemote true


1) print and copy this key:
	1.1) cat ~/.ssh/id_ed25519.pub
2) github.com -> SSH and GPG keys -> New SSH key
	2.1) copy the full string
3) Switch repo remote to ssh
	3.1) cd /path/to/hm-asus-arch-desktop
	3.2) git remote -v
	3.3) git remote set-url origin 
	3.4) git@github.com:oldfart-maker/hm-asus-arch-desktop.git
	3.5) git remote -v
4) git push
