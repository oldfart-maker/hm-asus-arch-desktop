* INSTALL QEMU/VIRT

***
* Copy *.iso files to target location
a.a) sudo mkdir -p /var/lib/libvirt/images
a.b) sudo cp --sparse=never --reflink=never \
	/mnt/backup/angel-win-vm/*.iso /var/lib/libvirt/images
	
* Enable the libvirtd service
a) sudo systemctl enable --now libvirtd

* Run virt-manager
a) virt-manager

* Add user to the correct groups
a) sudo usermod -aG libnvirt,kvm $USER

* Verify
a) virsh -c qemu:///system list --all

* Walthrough the config screens (view photo library) then select install:
Additions to photo catalog:
1. Change SATA Disk to virtio
2. Add a second CD-ROM that points to the virtio drivers

a) If you recieve a boot selection screen, select the first DVD.

b) When prompted where to install windows:
	b.a) Select: Load Driver
	b.b) Browse to: viostor/win11/amd64
	b.c) Select yes to the driver and the disk should show up
	
c) During installation you will be prompted to load the network driver (E:\netkvm\\win11\\amd64)  . You may need to repeat this several times before the network connects (likely due to network issue I am having).

d) After windows installs, install:
	d.a) E:\\virtio-win-guest-tools.exe
	
