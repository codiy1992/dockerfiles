FROM v2fly/v2fly-core

RUN apk add --no-cache supervisor

COPY supervisor.d/v2ray.ini /etc/supervisor.d/v2ray.ini

ENTRYPOINT ["/usr/bin/supervisord", "--nodaemon"]
