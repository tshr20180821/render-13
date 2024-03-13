#!/bin/bash

set -x

export PS4='+(${BASH_SOURCE}:${LINENO}): '

curl -sSLO https://raw.githubusercontent.com/tshr20180821/render-13/main/distccd.sh?"$(date +%s)"

chmod +x distccd.sh

DISTCCD_HOST=${DISTCCD_HOST_01} SSH_PORT=8022 DISTCC_PORT=3632 ./distccd.sh &
DISTCCD_HOST=${DISTCCD_HOST_02} SSH_PORT=8023 DISTCC_PORT=3633 ./distccd.sh &

sleep 10s

DEBIAN_FRONTEND=noninteractive apt-get install -y libevent-dev >/dev/null 2>&1

gcc -### -E - -march=native 2>&1 | sed -r '/cc1/!d;s/(")|(^.* - )//g' >/tmp/cflags_option
cflags_option=$(cat /tmp/cflags_option)
export CFLAGS="-O2 ${cflags_option} -pipe -fomit-frame-pointer"
export CXXFLAGS="${CFLAGS}"
export LDFLAGS="-fuse-ld=gold"

pushd /tmp
curl -sSO https://memcached.org/files/memcached-1.6.22.tar.gz
tar xf memcached-1.6.22.tar.gz

export DISTCC_HOSTS="127.0.0.1:3632/4,127.0.0.1:3633/4"
# export DISTCC_HOSTS="127.0.0.1:3632/4"
export DISTCC_POTENTIAL_HOSTS="${DISTCC_HOSTS}"
export DISTCC_FALLBACK=0
export DISTCC_IO_TIMEOUT=600
export DISTCC_VERBOSE=1

pushd memcached-1.6.22

./configure --disable-docs >/dev/null

time HOME=/tmp MAKEFLAGS="CC=distcc\ gcc" make -j4

popd
popd
