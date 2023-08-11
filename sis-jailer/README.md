# SIS

## How to use this repository

For SIS maintainers, see [ansible](ansible/).

The remainder of this README summarises the overall build and operation procedure for SIS.

## Builds

This section discusses how builds should work.
All builds should be executed using [the Ansible playbooks](ansible/).
However, you may want to read this guide if you run into issues.

There are two major components which should be traceable (reproducibility is not possible with Chromium at this time).

- The SIS host image
- The SIS browser container

To achieve this, images will be built using continuous integration.

### Building the host image

This VM image will be built with Packer, based on a base RHEL 8 image.
The base image should have the following configuration:

-   Up-to-date RHEL 8
-   SELinux enforcing
-   Beyond the above, apply the locally-customised CIS Benchmark for RHEL 8 Server L2.
-   Pre-installed rsyslog

The following components will be added using cloud-init:

-   nginx container image
-   spawner container image
-   browser container image
-   Relevant systemd units to spawn the above containers
-   Log forwarding configuration

### Building the browser container

We need to:

- Build chromium
- Bundle it into a container

#### Building the browser-builder

As it is impractical to pull the chromium sources (> 30 GB) from scratch every time, the SIS buildbot will cache a copy of the chromium sources, i.e. on a machine with persistent state.
Alternatively, we can pull a mostly-up-to-date archive of the sources from local storage.
A fresh pull with no commit history is 21GB as of September 2022. With history, this is about 65GB.
The browser-builder image itself will not contain a copy of the sources, but it will contain a copy of `depot_tools`, and be built using a (possibly out-of-date) `install-build-deps.sh`.

A possible solution is as follows:

- A dedicated VM (or user on a machine) as the CI runner user (ks + ansible)
- Some systemd services to do the initial pull, using containers, if not already complete
- A systemd service to start the runner which depends on the previous service
- At this point, our CI specification can assume that a cached copy of the sources exists and build the browser-builder from there

#### Building the browser

Note: there are known quirks when building Chromium.
**Read the linked README if you encounter any errors!!!**

The browser-builder component has [its own README outlining the build process](img/browser-builder).
It is strongly recommended to build chromium on a `tmpfs` as the container overlay filesystem is very slow, at least for rootless containers.

#### Building the actual browser container

Policies and other dependencies must be inserted here.


## Operation

SIS VMs are built with public keys preinstalled using cloud-init.
For example, if the VM is on 192.168.122.68 and hosted on `sis2` and your username is `sweishen`, you might run:

```sh
ssh -J sis2 sweishen-ladmin@192.168.122.68
```

from the machine holding the relevant SSH private key.

As SIS VMs are transient, you will find that host keys change daily.
If SSH host keys are not installed in the DNS, you may encounter the key change warning banner.
It is advisable to have the VM auto-update host keys as part of provisioning.
