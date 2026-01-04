***
* INSTALL VM (QEMU/VIRT)

***
A) Base Install (MOVE THIS TO bootstrap.sh)
	
	a.a) sudo systemctl enable --now libvirtd.service
	a.b) sudo virsh net-start default
	a.c) sudo virsh net-autostart default

***
D) download / copy *.iso's to target location

NOTE: There is a version of the .iso's on the external drive that can be used initially. 

To get the latest virtio driver: https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/latest-virtio/

	d.a) sudo mkdir -p /var/lib/libvirt/images
	
	d.b) sudo cp --sparse=never --reflink=never \
		/mnt/backup/win-vm-isos/*.iso /var/lib/libvirt/images
		
	d.c) sudo chown root:root /var/lib/libvirt/images/*.iso
	
	d.d) sudo chmod 644 /var/lib/libvirt/images/*.iso

***
E) Run virt-manager to confgure

NOTE: Use google photos album (Windows VM 2.0) for configuration options

	e.a) virt-manager
	
	e.b) replicate each of the images shown here:
		https://photos.app.goo.gl/Cp31HZSZnJBuxyd18
***
F) Install windows

NOTE: When windows asks where it should be installed click on the select driver button and go to viostor/win11/amd and select ok. The screen will be refreshed with the disk that should be selected for where windows is to be installed.

NOTE: During windows installation you will be prompted to load the network driver from:	"E\\netkvm\\win11\\amd64". This may not work the first time. If it does not just repeat the process and it will load the driver the second time. There is a timing issue where it can take about 60 seconds to load the driver an connect to the network. It may say failed at first. This has worked each time. There is a compatability issue with the NIC in this box that can be fixed by using a backhaul device of a simple usb wifi dongle.


NOTE: After windows installs go to device manager and look for the yellow triangles and install the correct drivers:

Network driver location: "E:\\NetKVM\\w11\amd64"

***
G) Install guest tools

	g.a) Install client tools "E:\\virtio-win-guest-tools.exe"
	
	g.b) Ensure that the correct display driver is installed. It needs to be the virtio driver, not the windows driver or the resolution will not work:
			Red Hat VirtIO GPU DOD controller
			E:\viogpudo\\w11\amd64\

NOTE: I have found that the best way to address scaling issues on the monitor is to select the option Scale - Never. In addition, installing truetype on windows helps with the resolution.

NOTE: Ensure that you are connecting to the correct service so that QEMU can see the VM. (Need to clarity what the issue is here on the next install)
***
* TODO

1) Add to bootstrap.sh
	1.1) "setup virt in target()"
	1.2) sudo usermod -aG libvirt username	
	1.3) sudo systemctl enable --now libvirtd.service
	1.4) sudo virsh net-start default
	1.5) sudo virsh net-autostart default



