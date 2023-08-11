#!/bin/bash

set -e

git clone git@git.dts.dsonet.corp.root:dts/firecracker.git $1
cd $1
git checkout cpu_string

tools/devtool build
toolchain="$(uname -m)-unknown-linux-musl"
