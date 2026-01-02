***
* INSTALL VM (QEMU/VIRT)

***
A) Base Install

NOTE: If you get a conflict error for iptables-nft select Y to replace.
	
	a.a) sudo pacman -S qemu-full virt-manager virt-viewer dnsmasq iptables-nft edk2-ovmf swtpm
	
	a.b) sudo usermod -aG libvirt username	
		a.b.a) run: groups
		a.b.b) verify libvirt is shown with wheel
		
	a.c) sudo systemctl enable --now libvirtd.service

***
D) download / copy *.iso's to target location

NOTE: There is a version of the .iso's on the external drive that can be used initially. 

To get the latest virtio driver: https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/latest-virtio/

external hard drive source
	d.a) sudo mkdir -p /var/lib/libvirt/images
	
	d.b) sudo cp --sparse=never --reflink=never \
		/mnt/backup/angel-win-vm/*.iso /var/lib/libvirt/images
		
	d.c) sudo chown root:root /var/lib/libvirt/images/*.iso
	
	d.d) sudo chmod 644 /var/lib/libvirt/images/*.iso

***
E) Run virt manager to confgure vm

NOTE: If TPM is not listed as a configuration option then it needs to be installed. To do this:
	1) Add Hardware
	2) Select TPM
	3) Use the google photo for configuration options

	e.a) virt-manager
	
	e.b) replicate each of the images shown here:
		https://photos.app.goo.gl/XpKW8A4EVhf8rvZh9
	
***
F) Install windows vm

NOTE: When windows asks where it should be installed click on the select driver button adn go to viostor/win11/amd and select ok. The screen will be refreshed with the disk that should be selected for where windows is to be installed.

NOTE: During windows installation you will be prompted to load the network driver from:	"E\\netkvm\\win11\\amd64". This may not work the first time. If it does not just repeat the process and it will load the driver the second time. There is a timing issue where it can take about 60 seconds to load the driver an connect to the network. It may say failed at first. This has worked each time. There is a compatability issue with the NIC in this box that can be fixed by using a backhaul device of a simple usb wifi dongle.


i) After windows installs go to device manager and look for the yellow triangles and install the correct drivers:

	i.a) Network driver: "E:\\NetKVM\\w11\amd64"
	
	i.b) Install client tools "E:\\virtio-win-guest-tools.exe"
	
	i.c) Ensure that the correct display driver is installed. It needs to be the virtio driver, not the windows driver or the resolution will not work:
			Red Hat VirtIO GPU DOD controller
			E:\viogpudo\\w11\amd64\

NOTE: I have found that the best way to address scaling issues on the monitor is to select the option Scale - Never. In addition, installing truetype on windows helps with the resolution.

NOTE: Ensure that you are connecting to the correct service so that QEMU can see the VM. (Need to clarity what the issue is here on the next install)
***
* OTHER

a) If you get the error when starting QEMU that the default network is not active:
	a.a) sudo virsh net-start default
	
	a.b) sudo virsh net-autostart default
	
	a.c) sudo virsh net-list --all
