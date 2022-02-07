FROM dreamacro/clash:latest

RUN apk add --no-cache curl supervisor

COPY ./supervisor.d /etc/supervisor.d

ENTRYPOINT ["/usr/bin/supervisord", "--nodaemon"]
