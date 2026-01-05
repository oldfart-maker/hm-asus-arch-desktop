* EXPORT / IMPORT VM

***
EXPORT

A) check if vm is running
	a.a) sudo virsh list --all
	
B) shutdown vm
	b.a) sudo virsh shutdown ANGEL-WIN11
	b.b) sudo virsh list -all (until state is shut off)
	
C) Change to external HD dir
	c.a) cd /mnt/backup/angel-win11-exports

C) dump configs
	c.a) sudo virsh dumpxml ANGEL-WIN11 > ANGEL-WIN11.xml
	
d) copy the disk image
	d.a) sudo rsync -a --sparse \
		/var/lib/libvirt/images/ANGEL-WIN11.qcow2 \.
		
******
IMPORT

A) Change to external HD dir
	a.a) cd /mnt/backup/angel-win11-exports
	
B) copy the disk image
 	b.a) sudo rsync -a --sparse ANGEL-WIN11.qcow2 \
		/var/lib/libvirt/images

C) copy .isos
NOTE: The vm will not start correctly without previously mounted .isos. Once the .isos are unmounted do not perform this step as part of the import.
	c.a) sudo cp --sparse=never --reflink=never \
		/mnt/backup/win-vm-isos/*.iso /var/lib/libvirt/images

D) import configs
	d.a) sudo virsh define ANGEL-WIN11.xml
	
E) Start the vm from the CLI to check for any errors:
	e.a) sudo virsh start ANGEL-WIN11
	e.b) sudo virsh list --all
