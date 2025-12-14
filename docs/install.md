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
b) mkdir -p ~/projects
c) cd ~/projects
d) git clone https://github.com/oldfart-maker/hm-asus-arch-desktop.git
e) git clone https://github.com/oldfart-maker/sys-secrets.git
f) cd ~/projects/hm-asus-arch-desktop/tools
g) chmod +x target-setup.sh
h) ./target-setup.sh
i) rm -rf hm-asus-arch-desktop

***
* TODO - Install Avahi and nss-mdns services

Set up avahi naming / lookup services on each machine. This needs become part of the core OS install in Step 3. Assuming this should be added to bootstrap.sh.

# core-os-setup-avahi.sh
set -euo pipefail
sudo pacman -S --needed avahi nss-mdns
sudo systemctl enable --now avahi-daemon.service

# remind yourself about nsswitch
automate pulling / move the nsswith.conf file from git to the target location. DO NOT MANUALLY EDIT ANY LOCAL FILE!!! NEEDS TO BE IDEMPOTENT.

***
* TODO - Copy ssh config from git to target location. This holds links to private keys and convenience names for ssh, emacs, scp, etc. For example the name services allow for <ssh dell>, scp dell.

copy to ~/.ssh/

***
* TODO - TP-LINK INSTALL -  Add tplink wireless USB wifi 6 installation. This has to be run after every kernel update. DO NOT USE THIS APPROACH. IT IS JUST A FALL BACK IN CASE WE NEED TO DEBUG THE tplink device.

Ensure device is seen
a) lsusb

Install arch dependent arch bits
x.a) sudo pacman -S --needed base-devl git linux-headers

Build from source
b) cd ~/projects
b.a) git clone https://github.com/morrownr/rtw89
b.b) cd ~/projects/rtw89
b.c) make clean modules
b.d) sudo make install
b.e) sudo make install_fw
b.f) sudo depmod -a
b.g) reboot
	
Connect to tplink (it may be different than wlan3)
c.a) Find the adapter interface (wlan1, wlan2, wlanX)
c.b) iw dev
c.c) nmcli device wifi connect "Hangout" password "gulfshores" ifname wlanX

***
* TODO - TP-LINK INSTALL - DKMS automated approach (DO THIS)

a) build + install
a.b) cd ~/projects/hm-asus-arch-desktop/tools/tp-link/rtw89-morrownr-dkms-git
a.c) makepkg -si
a.d) copy 10-wlantplink.link to /etc/systemd/network/10-wlantplink.link
a.e) reboot

b) Verify DKMS
a.b) sudo dkms status | grep rtw89

c) Plug in adapter
c.a) iw dev
c.b) sudo ip link set wlanX up
c.c) nmcli device wifi connect "Hangout" password "gulfshores" ifname wlanX
c.d) nmcli connection modify "Hangout" connection.autoconnect yes
c.e) nmcli connection up "Hangout"

***
* TODO - INSTALL QEMU

a) These will go into boostrap.sh as part of core:
a.a) sudo pacman -S --needed qemu-full libvirt virt-manager dnsmasq swtpm edk2-ovmf
a.b) sudo systemctl enable --now libvirtd.service
a.c) sudo usermod -aG libvirt "$USER"

