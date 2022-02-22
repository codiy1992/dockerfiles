ARG GOVERSION=1.17
FROM golang:$GOVERSION-alpine AS builder

RUN apk add --no-cache git build-base

RUN git clone --recurse-submodules https://github.com/syncthing/syncthing.git /src

WORKDIR /src

ENV CGO_ENABLED=0
ENV BUILD_HOST=syncthing.net
ENV BUILD_USER=docker
RUN rm -f syncthing && go run build.go -no-upgrade build syncthing
RUN rm -f stdiscosrv && go run build.go -no-upgrade build stdiscosrv
RUN rm -f strelaysrv && go run build.go -no-upgrade build strelaysrv

FROM alpine

# syncthing
EXPOSE 8384 22000/tcp 22000/udp 21027/udp
# stdiscosrv
EXPOSE 19200 8443
# strelaysrv
EXPOSE 22067 22070

VOLUME ["/var/syncthing", "/var/stdiscosrv", "/var/strelaysrv"]

RUN apk add --no-cache ca-certificates su-exec tzdata supervisor

COPY --from=builder /src/syncthing /bin/syncthing
COPY --from=builder /src/stdiscosrv /bin/stdiscosrv
COPY --from=builder /src/strelaysrv /bin/strelaysrv
# COPY --from=builder /src/script/docker-entrypoint.sh /bin/entrypoint.sh

ENV PUID=1000 PGID=1000 HOME=/data DATA_PATH=/data \
    SYNCTHING_PATH=/var/syncthing \
    STDISCOSRV_PATH=/var/stdiscosrv \
    STRELAYSRV_PATH=/var/strelaysrv

WORKDIR /data

# HEALTHCHECK --interval=1m --timeout=10s \
  # CMD (nc -z 127.0.0.1 8384 && nc -z 127.0.0.1 8443 && nc -z 127.0.0.1 22067) || exit 1

ENV STGUIADDRESS=0.0.0.0:8384

COPY ./entrypoint.sh /bin/entrypoint.sh
RUN chmod +x /bin/entrypoint.sh
COPY ./supervisor.d /etc/supervisor.d

ENTRYPOINT ["/usr/bin/supervisord", "--nodaemon"]
