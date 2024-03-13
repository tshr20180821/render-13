#!/bin/bash

set -x

export PS4='+(${BASH_SOURCE}:${DISTCCD_HOST}:${LINENO}): '

PASSWORD="$(echo -n "${DISTCCD_HOST}""${DUMMY_STRING_1}""$(date +%Y/%m/%d)" | base64 -w 0 | sed 's/[+\/=]//g')"

KEYWORD_FILENAME="$(echo "${KEYWORD_FILENAME}""${DUMMY_STRING_2}""$(date +%Y/%m/%d)" | base64 -w 0 | sed 's/[+\/=]//g')"
SSH_USER_FILENAME="$(echo "${SSH_USER_FILENAME}""${DUMMY_STRING_3}""$(date +%Y/%m/%d)" | base64 -w 0 | sed 's/[+\/=]//g')"
SSH_KEY_FILENAME="$(echo "${SSH_KEY_FILENAME}""${DUMMY_STRING_4}""$(date +%Y/%m/%d)" | base64 -w 0 | sed 's/[+\/=]//g')"

KEYWORD=$(curl -sSu ${BASIC_USER}:${BASIC_SERVER} https://${DISTCCD_HOST}/auth/${KEYWORD_FILENAME})
SSH_USER=$(curl -sSu ${BASIC_USER}:${BASIC_SERVER} https://${DISTCCD_HOST}/auth/${SSH_USER_FILENAME})

curl -sSu ${BASIC_USER}:${BASIC_SERVER} -o ./rsa_key01.txt https://${DISTCCD_HOST}/auth/${SSH_KEY_FILENAME}
chmod 600 ./rsa_key01.txt

CURL_OPT="${CURL_OPT} -m 3600 -sSN"

curl ${CURL_OPT} ${PIPING_SERVER}/${KEYWORD}res \
  | stdbuf -i0 -o0 openssl aes-128-ctr -d -pass "pass:${PASSWORD}" -bufsize 1 -pbkdf2 -iter 1 -md md5 \
  | nc -lp ${SSH_PORT} -s 127.0.0.1 \
  | stdbuf -i0 -o0 openssl aes-128-ctr -pass "pass:${PASSWORD}" -bufsize 1 -pbkdf2 -iter 1 -md md5 \
  | curl ${CURL_OPT} -T - ${PIPING_SERVER}/${KEYWORD}req &

ssh -v -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
  -o ServerAliveInterval=60 -o ServerAliveCountMax=60 \
  -p ${SSH_PORT} \
  -i ./rsa_key01.txt \
  -4fNL ${DISTCC_PORT}:127.0.0.1:3632 ${SSH_USER}@127.0.0.1 &
