.PHONY: index.html install clean

clean:
	rm -f index.html

index.html: index.html.j2
	jinja2 index.html.j2 -D environment="${SIS_ENV}" -D status="${OP_STATUS}" -D sis_url="${SIS_URL}" -D dts_contact="${DTS_CONTACT}" -D csog_contact="${CSOG_CONTACT}" > $@

install: index.html
	sudo install -m644 -t /usr/share/nginx/html $<
