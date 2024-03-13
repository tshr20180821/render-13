#!/bin/bash

set -x

export PS4='+(${BASH_SOURCE}:${LINENO}): '

sed -i s/__RENDER_EXTERNAL_HOSTNAME__/"${RENDER_EXTERNAL_HOSTNAME}"/g /etc/apache2/sites-enabled/apache.conf

. /etc/apache2/envvars

htpasswd -c -b /var/www/html/.htpasswd "${BASIC_USER}" "${BASIC_PASSWORD}"
chmod 644 /var/www/html/.htpasswd

curl -sSLO https://raw.githubusercontent.com/tshr20180821/render-13/main/start_after.sh?"$(date +%s)"

chmod +x ./start_after.sh

sleep 5s && ./start_after.sh &

for i in {1..20}; do \
  sleep 60s \
   && ps aux \
   && curl -sS -A "${i}" -u "${BASIC_USER}":"${BASIC_PASSWORD}" https://"${RENDER_EXTERNAL_HOSTNAME}"/?"$(date +%s)"; \
done &

exec /usr/sbin/apache2 -DFOREGROUND
