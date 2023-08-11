.PHONY: check clean default fmt install

PACKERFILE=sisvm.pkr.hcl

default: ${PACKERFILE} http/ks.cfg
	PACKER_LOG=1 packer build $<

check:
	packer validate .

fmt:
	packer fmt .

clean:
	rm -rf out

out/scap/ssg-rhel8-ds.xml: /usr/share/xml/scap/ssg/content/ssg-rhel8-ds.xml
	mkdir -p $(dir $@)
	cp $< $@

out/scap/ssg-rhel8-ds-tailoring.xml: ../../scap/ssg-rhel8-ds-tailoring.xml
	mkdir -p $(dir $@)
	cp $< $@

out/scap.tar: out/scap/ssg-rhel8-ds.xml out/scap/ssg-rhel8-ds-tailoring.xml
	tar cf out/scap.tar -C out scap/ssg-rhel8-ds.xml scap/ssg-rhel8-ds-tailoring.xml

out/nginx.tar:
	podman pull docker.io/library/nginx:latest
	podman save docker.io/library/nginx:latest -o $@

# TODO: template these files
out/iso/user-data: src/user-data
	mkdir -p $(dir $@)
	cp $< $@

out/iso/meta-data: src/meta-data
	mkdir -p $(dir $@)
	cp $< $@

out/cidata.iso: out/iso/user-data out/iso/meta-data
	genisoimage -output $@ -V cidata -r -J out/iso

install: img/sisvm.qcow2 out/cidata.iso
	sudo cp $< /var/lib/libvirt/images/logvm.qcow2
	sudo cp out/cidata.iso /var/lib/libvirt/images/logvm-cidata.iso
	sudo restorecon -Fvvv /var/lib/libvirt/images/logvm.qcow2 /var/lib/libvirt/images/logvm-cidata.iso

create:
	sudo virt-install --name=logvm --ram=4096 --vcpus=2 --disk path=/var/lib/libvirt/images/logvm.qcow2,format=qcow2 --disk path=/var/lib/libvirt/images/logvm-cidata.iso,device=cdrom --os-variant=rhel8-unknown --network network=default,model=virtio --noautoconsole --import

destroy:
	sudo virsh destroy --domain logvm
	sudo virsh undefine --domain logvm
	sudo rm -rf /var/lib/libvirt/images/logvm.qcow2 /var/lib/libvirt/images/logvm-cidata.iso
