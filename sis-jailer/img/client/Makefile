.PHONY: clean container

clean:
	rm -rf menlo-chain.pem menlo-ca.pem nssdb test_policy.json newtab.html

menlo-chain.pem:
	openssl s_client -connect www.google.com:443 -showcerts -servername www.google.com -proxy ${MENLO_PROXY} < /dev/null > $@

menlo-ca.pem: menlo-chain.pem
	grep -A999 "s:C = US, ST = California, O = Menlo Security Inc., OU = Production, CN = Menlo Security Intermediate CA" $< > $@

nssdb: nssdb/cert9.db

nssdb/cert9.db: MenloSecurityCustomerRootCA.crt
	mkdir -p $(dir $@)
	certutil -N -d sql:nssdb --empty-password
	certutil -d sql:nssdb -A -t "C,," -n "Menlo Root CA" -i $<

test_policy.json: approved_sites.txt test_policy_base.json
	./make_test_policy.py > $@

newtab.html: newtab.html.j2 approved_sites.txt
	jinja2 $< > $@

container: nssdb chromium.tar test_policy.json newtab.html
	podman build -t sisclient .
