# browser-builder

An OCI image to build Chromium.

## Usage

```sh
make browser-builder
./run-builder /path/to/crbuild 105.0.5195.101
```

substituting the path and version number accordingly.
This script will start a `browser-builder` container and attempt to build chromium.

### Full instructions

#### Clone chromium

You should consider running the `fetch` commands within the browser-builder container, as it contains `depot_tools` and the SELinux labeling will be correct.

----

Note: if you clone Chromium sources outside the browser-builder container, they will probably not be labeled with the `container_file_t` SELinux context.
You may encounter the following error when building (#28) -- specifically this occurs during a file extraction stage.
To fix this, run `podman unshare restorecon -RF /path/to/chromium/sources/on/the/host`

```text
Unable to change ownership to uid 366730, gid 89939
```

----

#### Manual build procedure

Mount your `chromium` directory at `/crbuild`:

```sh
podman run -ti --rm -v /path/to/chromium/source:/crbuild:z --tmpfs=/tmp:rw,nosuid,nodev,mode=1777 browser-builder bash
```

And in the container:

```sh
cd /crbuild/src

# !!! Ensure install-sysroot.py has been updated with tar ... --no-same-owner
#
# To do this, edit install-sysroot.py, search for 'tar', and append the --no-same-owner parameter.
# This is needed as you are building as root within the container.
# A future version of browser-builder may change this.

# Assume correct commit has been checked out
gclient runhooks
gclient sync

# Ensure that the deps of the current version are installed
./build/install-build-deps.sh
chmod +x third_party/node/linux/node-linux-x64/bin/node
mkdir -p /tmp/out
ln -s /tmp/out /crbuild/src/out/Default

# either gn gen or gn args
gn gen out/Default --args="is_official_build=true chrome_pgo_phase=0 is_debug=false symbol_level=0 v8_symbol_level=0 blink_symbol_level=0"
autoninja -C out/Default chrome
```

The symlink is necessary as the build process will attempt to link to a file in the output directory from `/tmp`, but this is not possible using a volume mount.
