# Status page

See [this ansible playbook](../ansible/04-deploy-statuspage.yml) for instructions on deployment to SIS production.

Local instructions:

```sh
jinja2 index.html.j2 -D status=Operational -D sis_url="/login" -D dts_contact="Nicholas Sim (sweishen@; 1150)" -D csog_contact="Benjamin Chua (cruihern@; 4793)"
```
