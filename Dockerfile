FROM abiosoft/caddy:1.0.3
COPY ./public /srv

ENV ACME_AGREE=true

ARG CADDYFILE=Caddyfile
COPY ./${CADDYFILE} /etc/Caddyfile

