# Deployment playbooks for SIS

To use these playbooks, you will likely need SSH keys to be enrolled on the relevant machines.
Additionally, due to the nature of the SIS deployment, some hosts are ephemeral and require unusual configurations, at least until we embed cloud-init scripts to update SSHKEY DNS records.
Check each playbook for the lists of hosts touched.

For example, for the (pilot) production SIS VM, one might use the following `ssh_config`:

```
Host sis2-vm
    UserKnownHostsFile /dev/null
    StrictHostKeyChecking no
    ProxyJump sis2
    HostName 192.168.122.98
    User YOURNAME-ladmin
```

## Building

In the following example, this repository has been cloned to `$HOME/work/sis`, and the chromium sources have been cloned to `$HOME/work/sis/img/browser-builder/crbuild`.
Additionally, do check the `guac_host` and `vas_hostname` variables.

Chromium sources are found here: <https://chromium.googlesource.com/chromium/src.git>.
Chromium release info can be found here: <https://chromiumdash.appspot.com/releases?platform=Linux>. You will want the version number of the latest stable Linux release.

Here are some sample commands:

```sh
ansible-playbook -i hosts.yml -v -e sis_src=$HOME/work/sis -e crbuild_dir=$HOME/work/sis/img/browser-builder/crbuild -e chromium_version=109.0.5414.119 -e menlo_proxy=proxy0-418f1090cac5bb897d919b628e87950c.menlosecurity.com:3129 -K 21-generate-sisclient.yml
ansible-playbook -i hosts.yml -v -e sis_src=$HOME/work/sis -K 23-upload-guac.yml
ansible-playbook -i hosts.yml -v -e sis_src=$HOME/work/sis -e guac_host=https://staging.sis.dsnet.dso.root/guacamole -e vas_hostname=sis2-vas 24-build-sisvm.yml
```

## Deploying

For the next day:

```sh
ansible-playbook -i hosts.yml -e sis_src=$HOME/work/sis 03a-delay-deploy-sisvm.yml -K
ansible-playbook -i hosts.yml -v -e sis_env="" -e op_status=Operational -e sis_url="/login" -e 'dts_contact="Nicholas Sim / SIS Team (1150 / dso_dts@)"' -e 'csog_contact="Benjamin Chua (4793; cruihern@)"' -K 04-deploy-statuspage.yml
```

Immediately:

```sh
ansible-playbook -i hosts.yml 03b-deploy-sisclient-live.yml -K --diff
```

## Enrolling PT users

```
ansible-playbook -i hosts.yml -l sis2 -K -e ssh_key_dir=sshkeys2 --diff site.yml
```

The SSH keys will be saved to `sshkeys2` (or wherever you specify). Ensure that these are copied to the cloud-init sources.
