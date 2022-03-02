FROM restic/restic:latest

RUN apk add --no-cache supervisor

ENV TZ="Asia/Shanghai"

RUN cp /usr/share/zoneinfo/${TZ} /etc/localtime \
    && echo ${TZ} > /etc/timezone

COPY ./supervisor.d /etc/supervisor.d

ENTRYPOINT ["/usr/bin/supervisord", "--nodaemon"]
