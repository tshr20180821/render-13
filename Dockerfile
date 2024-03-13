FROM debian:stable-slim

EXPOSE 80

SHELL ["/bin/bash", "-c"]

WORKDIR /app

ENV DEBIAN_FRONTEND=noninteractive
ENV DISTCCD_LOG_FILE=/var/www/html/auth/distccd_log.txt

RUN set -x \
 && time apt-get -qq update \
 && time apt-get -q -y --no-install-recommends install \
  apache2 \
  build-essential \
  ca-certificates \
  curl \
  distcc \
  dnsutils \
  gcc-x86-64-linux-gnu \
  iproute2 \
  netcat-openbsd \
  openssh-client \
  openssl \
 && mkdir /var/run/apache2 \
 && a2dissite -q 000-default.conf \
 && mkdir -p /var/www/html/auth \
 && chown www-data:www-data /var/www/html/auth -R \
 && echo '<HTML />' >/var/www/html/index.html \
 && \
  { \
    echo 'User-agent: *'; \
    echo 'Disallow: /'; \
  } >/var/www/html/robots.txt \
 && a2enmod \
  authz_groupfile \
  proxy \
  proxy_http

COPY ./apache.conf /etc/apache2/sites-enabled/
COPY --chmod=755 ./*.sh ./

STOPSIGNAL SIGWINCH

ENTRYPOINT ["/bin/bash","/app/start.sh"]
