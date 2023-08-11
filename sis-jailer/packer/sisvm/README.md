# Generating SIS VM images

## Cloud-init

For dev (TN):

```
make install GUAC_HOST=https://dev.sis.dsonet.corp.root/guacamole VAS_HOSTNAME=sis1-vas
```

For prod (DSN):

```
make out/cidata.iso GUAC_HOST=https://staging.sis.dsnet.dso.root/guacamole VAS_HOSTNAME=sis2-vas
```
