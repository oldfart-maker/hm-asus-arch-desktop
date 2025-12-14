* INSTALL TEST SYTSTEM

a) After install:
	a.a) install foot, rofi, ttf-jetbrains-mono-2.304-2-any, emacs-nox,
		 qutebrowser mesa-utils
		 
	a.b) run tangel-sync.sh with the pi as target system
	
	a.c) copy from host:
		a.c.a) ~/.config/rofi
		a.c.b) ~/.config/niri/*
		a.c.c) ~/projects/hm-asus-arch-desktop... (niri config.kdl)
		
	a.d) remove reference to fish in foot.ini
	
	
***
* INSTALL VM ON TEST SYSTEM

a) base install
	NOTE: If you get a conflict error select Y.
	sudo pacman -S qemu-full virt-manager virt-viewer dnsmasq iptables-nft edk2-ovmf swtpm
	sudo systemctl enable --now libvirtd.service
	sudo usermod -aG libvirt username

b) sudo systemctl restart libvirtd

c) run: groups
	c.a) verify libvirt is shown with wheel

g) download virtio and windows .isos
	g.a) https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/latest-virtio/

e) when you get the emulator may not have search... message:
	sudo mv ~/Downloads/Win11_25H2_English_x64.iso /var/lib/libvirt/images/
	sudo mv ~/Downloads/virtio-win.iso /var/lib/libvirt/images/
	sudo chown root:root /var/lib/libvirt/images/*.iso
	sudo chmod 644 /var/lib/libvirt/images/*.iso

d) run virt-manager

f) look at each configuratin image in photos to reproduce

g) handle tpm 2.0
	g.a) swtpm should already be installed.
	g.b) add TPM through virt-manager (see photo)
	
h) NOTES ON SELECTING THE CORRECT DRIVER
	h.a) When windows asks where to install click on the Select Driver button and   go to the viostor/win11/amd and select okay. This will load the disk to be selected for the windows install. 
	
i) After windows installs go to device manager and look for the yellow triangles and install the correct drivers:
	i.a) Network driver: "E:\\NetKVM\\w11\amd64"
	i.c) Install client tools "E:\\virtio-win-guest-tools.exe"
	
j) During installation you will be prompted to load the network driver from:
	"E\\netkvm\\win11\\amd64". This may not work the first time. If it does not just   repeat the process and it will load the driver the second time.
	
	
Use this command to dump the xml to get the vm configs. They are way to involved to detail out:

	sudo virsh list --all
	sudo virsh dumpxml ANGEL-WIN > ANGEL-WIN.xml

Connect / Start VM with config:
	virsh --connect qemu:///system list --all
	virsh --connect qemu:///system dumpxml ANGEL-WIN > ANGEL-WIN.xml
	
Start / stop the vm
	sudo virsh shutdown ANGEL-WIN
	sudo virsh start ANGEL-WIN
	
For the graphics to work on windows you must use the driver:
	Red Hat VirtIO GPU DOD controller
	E:\viogpudo\w11\amd64\
	
To fix the font resolution issues select Scale - Never.

***
SETTING UP AVAHI SSH SERVER BROWSER
sudo pacman -S avahi nss-mdns
sudo systemctl enable --now avahi-daemon.service

copy: ~/projects/hm-asus-arch-desktop/home/data/apps/avahi/nsswitch.conf to target:
	/etc/
	
copy: ~/projects/hm-asus-arch-desktop/home/data/apps/avahi/ssh.service to target:
	/etc/avahi/services

copy: ~/projects/hm-asus-arch-desktop/home/data/apps/ssh/conf to target:
	~/.ssh

***
* OTHER

a) If you get the error when starting QEMU that the default network is not active:
	a.a) sudo virsh net-start default
	a.b) sudo virsh net-autostart default
	a.c) sudo virsh net-list --all
