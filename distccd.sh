#!/bin/bash

set -x

export PS4='+(${BASH_SOURCE}:${DISTCCD_HOST}:${LINENO}): '

curl -sSm 3 https://"${DISTCCD_HOST}"/ >/dev/null 2>&1 &

# PASSWORD="$(echo -n "${DISTCCD_HOST}""${DUMMY_STRING_1}""$(date +%Y/%m/%d)" | base64 -w 0 | sed 's/[+\/=]//g')"

KEYWORD_FILENAME="$(echo "${KEYWORD_FILENAME}""${DISTCCD_HOST}""${DUMMY_STRING_2}""$(date +%Y/%m/%d)" | base64 -w 0 | sed 's/[+\/=]//g')"
SSH_USER_FILENAME="$(echo "${SSH_USER_FILENAME}""${DISTCCD_HOST}""${DUMMY_STRING_3}""$(date +%Y/%m/%d)" | base64 -w 0 | sed 's/[+\/=]//g')"
SSH_KEY_FILENAME="$(echo "${SSH_KEY_FILENAME}""${DISTCCD_HOST}""${DUMMY_STRING_4}""$(date +%Y/%m/%d)" | base64 -w 0 | sed 's/[+\/=]//g')"

while [ "200" != "$(curl -sSu "${BASIC_USER}":"${BASIC_PASSWORD}" -o /dev/null -w '%{http_code}' https://"${DISTCCD_HOST}"/auth/"${SSH_KEY_FILENAME}")" ]; do
  sleep 3s
done

KEYWORD="$(curl -sSu "${BASIC_USER}":"${BASIC_PASSWORD}" https://"${DISTCCD_HOST}"/auth/"${KEYWORD_FILENAME}")"
SSH_USER="$(curl -sSu "${BASIC_USER}":"${BASIC_PASSWORD}" https://"${DISTCCD_HOST}"/auth/"${SSH_USER_FILENAME}")"

curl -sSu "${BASIC_USER}":"${BASIC_PASSWORD}" -O https://"${DISTCCD_HOST}"/auth/"${SSH_KEY_FILENAME}"
chmod 600 ./"${SSH_KEY_FILENAME}"

CURL_OPT="${CURL_OPT} -m 3600 -sSN"

# curl ${CURL_OPT} ${PIPING_SERVER}/${KEYWORD}res \
#   | stdbuf -i0 -o0 openssl aes-128-ctr -d -pass "pass:${PASSWORD}" -bufsize 1 -pbkdf2 -iter 1 -md md5 \
#   | nc -lp ${SSH_PORT} -s 127.0.0.1 \
#   | stdbuf -i0 -o0 openssl aes-128-ctr -pass "pass:${PASSWORD}" -bufsize 1 -pbkdf2 -iter 1 -md md5 \
#   | curl ${CURL_OPT} -T - ${PIPING_SERVER}/${KEYWORD}req &

BASE_CONNECT_PORT=5000
for ((i=0; i < 10; i++)); do \
  CONNECT_PORT="$(("${BASE_CONNECT_PORT}"+"${i}"))"
  curl ${CURL_OPT} "${PIPING_SERVER}"/"${KEYWORD}""${CONNECT_PORT}"res \
    | nc -lp "${SSH_PORT}" -s 127.0.0.1 \
    | curl ${CURL_OPT} -T - "${PIPING_SERVER}"/"${KEYWORD}""${CONNECT_PORT}"req &

  ssh -v -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    -o ServerAliveInterval=60 -o ServerAliveCountMax=60 \
    -p "${SSH_PORT}" \
    -i ./"${SSH_KEY_FILENAME}" \
    -4fNL "${DISTCC_PORT}":127.0.0.1:3632 "${SSH_USER}"@127.0.0.1 &

  sleep 3s

  ss -4antp
  ss -4antp | grep ESTAB | grep -v grep
  break
done
