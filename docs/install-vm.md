* INSTALL QEMU/VIRT

***
* Copy *.iso files

a.a) sudo mkdir -p /var/lib/libvirt/images
a.b) sudo cp --sparse=never -reflink=never \
	/mnt/backup/angel-win-vm/*.iso /var/lib/libvirt/images
	
* Run virt-manager


