# Secure Internet Surfing (SIS)

# Status: Ansible Roles

| Role | Playbook (in project tree) | Description | Status |
|---|---|---|---|
| Setup Build Server | `/00-setup-build-servers.yml` | Install dependencies for building browser etc | Done |
| Setup Container Server | `/setup_container_server.yml` | Install dependencies for container building | Done |
| Build Browser | `/10-build-browser.yml` | Performs actual build of web browser | Done |

# Design

## Components

* Build Server: CI/CD to:
    * Pull and build Chromium
    * Build containers
* Container Server
    * Host browser containers
    * Provide VNC connections out
* Logging Server

## Sprints

| Sprint | Component | Implementation |
|---|---|---|
| 1a | Browser Build Server | VMware VM |
| 1b | Container Server | VMware VM |

## Notes: Sprint 1(a)

* Notes:
    * Each of the "Ansible:" items should have a stand-alone Ansible script, so that the playbook can be repeated on a separate machine for later sprints, e.g., for separation
    * Use custom host inventory file; specify with `-i <inventory>` on Ansible command line
    * Can use custom Ansible configuration file, `ansible.cfg` in project folder
    * See [sample directory layout for Ansible projects](https://docs.ansible.com/ansible/latest/user_guide/sample_setup.html)
        * A role = One functionality
* Challenge:
    * ```apt``` daemons may be running (e.g. auto-update), which then prevent the Ansible remote user from running `apt-get update` etc. - disable auto-update?

* Runtimes
    * browser fetch: ~ 1h (but only needs to be run once)
    * browser sync: ~ 10 mins
    * browser fetch tags: ~ 5 mins

* Preamble
    * See [Official instructions for Chromium checkout and build](https://chromium.googlesource.com/chromium/src/+/main/docs/linux/build_instructions.md)
* Install Ubuntu 20.04
    * Snapshot: "Clean Ubuntu install"
    * Note: This could be replaced later with OpenStack Ironic for bare metal, or QEMU/KVM for virtualized node
    * Pw: (1)(2) *(usual password)*
* Setup VM: Prepare manually for Ansible
    * (Manually) Install Ansible (and pre-requisites)
    * Snapshot: "Manual Install Completed"
    * Copy SSH credentials: `ssh-copy-id`
```
apt-get install net-tools openssh-server openssh-sftp-server
```
* Setup Build Server (Chromium)
    * ~~Ansible: Set up GitLab?~~
    * Ansible: Set up Chromium build environment
        * Install Python packages
        * Fetch and install `depot_tools`
    * Ansible: CI for Chromium: Use Jenkins
        * Download and install Jenkins?
        * Push Jenkins configs?
    * Pull Chromium sources
    * Build Chromium (Should this be done over Ansible? Any way to *"fire and forget"*?)
* Setup Build Server (Containers - Podman)
    * Ansible: Fetch / Install Podman


### Servers and Roles

| Server | Role |
|---|---|
| Browser Build Server | ```browser_build```, ```browser_build_setup```, ```ci_cd_server``` |
| Browser Container Server | ```container_server``` |

### Ansible Notes

* Ansible order of config file (```ansible.cfg```) selection:
    * env var, current directory, home directory, global (```/etc/ansible/ansible.cfg```)
* Ansible command-line options:
    * `-i` for inventory file (```hosts``` file) manual selection
* "Hello World" test:
    * In ```ansible-playbooks/``` directory, run command ```ansible -i inventories/staging_local/hosts build_servers -m ping```
* Running playbook:
    * Run command ```ansible-playbook -i inventories/staging_local.ini build_servers site.yml```
* Writing tasks:
    * ```roles/X/tasks/main.yml```: List of tasks (no need to explicitly write a "-tasks:" up front at the top)
* Become: 
    * use ```-K``` at command-line?
    * long-term: use Ansible Vault to store and encrypt password? store password in inventories?

###

* Final workflow:
    * Setup Browser Build Server: ```time ansible-playbook -K -i inventories/staging_local.ini 00-setup-build-servers.yml```
    * Build Browser: ```time ansible-playbook -K -i inventories/staging_local.ini 10-build-browser.yml```


## Notes: Sprint 1(b)

* Goals:
  * Setup container server (install dependencies needed to create containers)
  * Build browser container
* Preliminaries
    * Use podman
    * Tools (See [RHEL](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux_atomic_host/7/html/managing_containers/finding_running_and_building_containers_with_podman_skopeo_and_buildah))
        * podman: Run and manage containers and container images (~ docker)
        * buildah: Build container images either from `Dockerfile`s or command-line; Note that `podman` uses `buildah` under-the-hood for container creaetion
        * skopeo: Copy containers and images between different types of container storage
    * Which Linux distribution to use?
        * RedHat (RHEL / Fedora / CentOS) - podman/buildah etc. designed for RedHat ecosystem, and RedHat-based distributions use SELinux
        * Alpine Linux?
        * Ubuntu - uses AppArmor instead of SELinux

* Approximate workflow:
  * Install podman/buildah/skopeo
  * Create Dockerfile (use `podman build` instead of `buildah` for compatibility with Kubernetes/Docker)
* Base container image choice?
  * Alpine - missing too many dependencies for running Chrome? + We built Chrome on Ubuntu
* Container (image) build
  * Dependencies for running Chromium - what packages needed?
    * Run `ldd chrome | grep "not found"` to see what's missing
  * XVFB



### Scratch: Commands:

* Running locally: Setup container server (Install podman/buildah/skopeo)
```
ansible-playbook -K --connection=local --inventory container_servers=127.0.0.1,limit=127.0.0.1 20-setup-container-servers.yml -i inventories/staging_local.ini

```

* (Note: Some of these steps we will eventually place in an Ansible playbook)
* Building the container image : `podman image build -t <tag name> [context = dir with Dockerfile]`
  * `podman image build -t alpine_chromium_1 ../sis/ansible-playbooks/images/chromium1/`
  * `podman image build -t ubuntu_chromium_1 ../sis/ansible-playbooks/images/chromium1/`
  * Note: You can run one or more containers based on the same image
* Checking local registry for image: `podman images`
* Running container: `podman run -ti <image id> /bin/bash`
  * Must have installed `bash` first
  * `-i` = interactive
* Deleting container: `podman rm <imaage name>`
  * Deleting running images quickly: `podman ps -a | tail -n +2 | awk -F " " '{print $1}' | xargs podman rm`
* Deleting container image: `podman rmi <image ID>`
