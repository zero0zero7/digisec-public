.PHONY: browser-builder

browser-builder: install-build-deps.sh
	podman build -t browser-builder .

install-build-deps.sh:
	curl -L https://chromium.googlesource.com/chromium/src.git/+/refs/heads/main/build/install-build-deps.sh?format=TEXT | base64 -d > $@
