# SIS Client

To build the CA files, you will need to set `MENLO_PROXY`:

```sh
export MENLO_PROXY=proxy0-abcdef.menlosecurity.com:3129
```

```sh
podman run --rm --read-only -e VNCPASSWD=password-of-your-choice -p 127.0.0.1::5920 sisclient
```
