#!/bin/bash

set -x

export PS4='+(${BASH_SOURCE}:${LINENO}): '

curl -sSLO https://raw.githubusercontent.com/tshr20180821/render-13/main/distccd.sh?"$(date +%s)"

chmod +x distccd.sh

BASE_SSH_PORT=7000
BASE_DISTCC_PORT=7100

for ((i=0; i < "${DISTCCD_HOST_COUNT}"; i++)); do \
  var_name="DISTCCD_HOST_0""${i}"
  DISTCCD_HOST="${!var_name}" SSH_PORT=$(("${BASE_SSH_PORT}"+"${i}")) DISTCC_PORT=$(("${BASE_DISTCC_PORT}"+"${i}")) ./distccd.sh &
  DISTCC_HOSTS="${DISTCC_HOSTS} 127.0.0.1:$(("${BASE_DISTCC_PORT}"+"${i}"))/3"
done
export DISTCC_HOSTS

export DISTCC_POTENTIAL_HOSTS="${DISTCC_HOSTS}"
export DISTCC_FALLBACK=0
export DISTCC_IO_TIMEOUT=600
# export DISTCC_VERBOSE=1

gcc -### -E - -march=native 2>&1 | sed -r '/cc1/!d;s/(")|(^.* - )//g' >/tmp/cflags_option
cflags_option=$(cat /tmp/cflags_option)
export CFLAGS="-O2 ${cflags_option} -pipe -fomit-frame-pointer"
export CXXFLAGS="${CFLAGS}"
export LDFLAGS="-fuse-ld=gold"

wait

DEBIAN_FRONTEND=noninteractive apt-get install -y libevent-dev >/dev/null 2>&1

pushd /tmp
curl -sSO https://memcached.org/files/memcached-1.6.22.tar.gz
tar xf memcached-1.6.22.tar.gz

pushd memcached-1.6.22

./configure --disable-docs >/dev/null

time HOME=/tmp MAKEFLAGS="CC=distcc\ gcc" make -j$((DISTCCD_HOST_COUNT*2))

popd
popd
