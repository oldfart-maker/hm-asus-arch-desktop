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
	
D) copy the disk image (use d.b)
	d.a) sudo rsync -a --sparse \
		/var/lib/libvirt/images/ARCH-WIN11.qcow2 \.
		
******
IMPORT

A) Change to external HD dir
	a.a) cd /mnt/backup/angel-win11-exports
	
B) copy the disk image
 	b.a) sudo rsync -a --sparse ARCH-WIN11.qcow2 \
		/var/lib/libvirt/images

C) import configs
	c.a) sudo virsh define ANGEL-WIN11.xml
