FROM v2fly/v2fly-core

RUN apk add --no-cache supervisor

ENTRYPOINT ["/usr/bin/supervisord", "--nodaemon"]
