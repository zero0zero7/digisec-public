# guacamole pod

```sh
podman pod create -n guac -p 127.0.0.1:8080:8080
podman run --pod guac --name guacd guacamole/guacd
podman run --pod guac --name guacamole -e "GUACD_HOSTNAME=127.0.0.1" -e "GUAC_JSON_KEY=secret here" this-guacamole-image
