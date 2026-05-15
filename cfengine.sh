#!/bin/sh -ae
set -o noglob -o nounset
trap 'sudo find "${workdir?}"/ -type f -exec shred -vu {} +; rmdir -- "$workdir"' EXIT
workdir="$(mktemp -d /tmp/SHREDME-XXXXXX.tmp)"

. /etc/os-release

cd -- "$workdir" || exit

if [ -d /etc/yum.repos.d ]; then
    if ! [ -x "$(command -v curl)" ]; then
        sudo yum makecache
        sudo yum install --assumeyes curl
    fi
    sudo install -DTv /dev/stdin /etc/yum.repos.d/cfengine-community.repo <<'EOF'
[cfengine-repository]
name=CFEngine
baseurl=https://cfengine-package-repos.s3.amazonaws.com/pub/yum/\$basearch
enabled=1
gpgcheck=1
gpgkey=https://cfengine-package-repos.s3.amazonaws.com/pub/gpg.key
EOF
    sudo yum makecache
    sudo yum install --assumeyes cfengine-community
    sudo yum install --assumeyes pipx
    sudo yum install --assumeyes shred
elif [ -d /etc/apt.sources.d ]; then
    export DEBIAN_FRONTEND=noninteractive
    if ! [ -x "$(command -v wget)" ]; then
        sudo apt update
        sudo apt-get install -qqy wget
    fi
    wget -q -O cfengine.asc https://cfengine-package-repos.s3.amazonaws.com/pub/gpg.key
    sudo mv ./cfengine.asc /etc/apt/trusted.gpg.d/
    echo "deb https://cfengine-package-repos.s3.amazonaws.com/pub/apt/packages stable main" > \
        /etc/apt/sources.list/cfengine-community.list
    sudo apt update
    sudo apt-get install -qqy cfengine-community
    sudo apt-get install -qqy pipx
    sudo apt-get install -qqy shred

else
    exit
fi

sudo pipx install cf-remote
