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

out/iso/user-data: src/user-data.j2
	mkdir -p $(dir $@)
	@echo "suppressing jinja2 src/user-data.j2 ..."
	@jinja2 src/user-data.j2 -D "GUAC_ENCRYPTED_JSON_SECRET=$(shell od -vN 16 -An -tx1 /dev/urandom | tr -d " \n")" -D "GUAC_HOST=${GUAC_HOST}" > $@

out/iso/meta-data: src/meta-data.j2
	mkdir -p $(dir $@)
	jinja2 src/meta-data.j2 -D "hostname=${VAS_HOSTNAME}" > $@

out/cidata.iso: out/iso/user-data out/iso/meta-data
	genisoimage -output $@ -V cidata -r -J out/iso

install: img/sisvm.qcow2 out/cidata.iso
	sudo cp $< /var/lib/libvirt/images/sisvm.qcow2
	sudo cp out/cidata.iso /var/lib/libvirt/images/cidata.iso
	sudo restorecon -Fvvv /var/lib/libvirt/images/sisvm.qcow2 /var/lib/libvirt/images/cidata.iso

create:
	sudo virt-install --name=sistest --ram=65536 --vcpus=48 --disk path=/var/lib/libvirt/images/sisvm.qcow2,format=qcow2 --disk path=/var/lib/libvirt/images/cidata.iso,device=cdrom --os-variant=rhel8-unknown --network network=default,model=virtio --noautoconsole --import

destroy:
	-sudo virsh destroy --domain sistest
	sudo virsh undefine --domain sistest
	sudo rm -rf /var/lib/libvirt/images/sisvm.qcow2 /var/lib/libvirt/images/cidata.iso
