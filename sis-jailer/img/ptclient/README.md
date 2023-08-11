# sis-ptclient

## Uploading this image

On the local machine (e.g. sis1):

```sh
make container
podman save -o sis-ptclient.tar localhost/sis-ptclient
scp sis-ptclient detritus:~
ssh detritus install -m644 ~/sis-ptclient /var/lib/mirror/repos/sis/sis-ptclient.tar
```
