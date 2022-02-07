FROM p4gefau1t/trojan-go

RUN apk add --no-cache nginx supervisor

ENTRYPOINT ["/usr/bin/supervisord", "--nodaemon"]
