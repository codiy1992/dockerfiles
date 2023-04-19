FROM teddysun/v2ray:v5.3.0 AS v2fly
FROM teddysun/xray:1.7.5 AS xray
FROM ghcr.io/shadowsocks/ssserver-rust:v1.15.3 AS shadowsocks

# @link https://github.com/teddysun/v2ray-plugin/releases
FROM golang:1.20-alpine AS go1.19.1-builder

RUN set -ex && apk update && apk add --no-cache make git gcc libc-dev curl

ARG V2RAY_PLUGIN_VERSION=5.3.0
RUN curl -skLO https://github.com/teddysun/v2ray-plugin/archive/refs/tags/v${V2RAY_PLUGIN_VERSION}.tar.gz


RUN mkdir -p /go/src/github.com && \
    tar xzf v${V2RAY_PLUGIN_VERSION}.tar.gz && \
    mv v2ray-plugin-${V2RAY_PLUGIN_VERSION} /go/src/github.com/v2ray-plugin && \
    cd /go/src/github.com/v2ray-plugin && \
    go build

# @link https://github.com/teddysun/xray-plugin/releases
FROM golang:1.20-alpine AS go1.19.4-builder

RUN set -ex && apk update && apk add --no-cache make git gcc libc-dev curl

ARG XRAY_PLUGIN_VERSION=1.7.5
RUN curl -skLO https://github.com/teddysun/xray-plugin/archive/refs/tags/v${XRAY_PLUGIN_VERSION}.tar.gz

RUN mkdir -p /go/src/github.com && \
    tar xzf v${XRAY_PLUGIN_VERSION}.tar.gz && \
    mv xray-plugin-${XRAY_PLUGIN_VERSION} /go/src/github.com/xray-plugin && \
    cd /go/src/github.com/xray-plugin && \
    go build

FROM caddy:builder AS builder

RUN xcaddy build \
    --with github.com/caddy-dns/alidns \
    --with github.com/caddy-dns/route53 \
    --with github.com/caddy-dns/cloudflare


FROM caddy

# @link https://github.com/v2fly/docker/blob/master/v2ray.sh
COPY --from=v2fly /usr/bin/v2ray /usr/bin/v2ray
COPY --from=v2fly /etc/v2ray/config.json /etc/v2ray/config.json
COPY --from=v2fly /usr/local/share/v2ray/geoip.dat /usr/local/share/v2ray/geoip.dat
COPY --from=v2fly /usr/local/share/v2ray/geosite.dat /usr/local/share/v2ray/geosite.dat

# @link https://github.com/teddysun/across/blob/master/docker/xray/Dockerfile.architecture
COPY --from=xray /usr/bin/xray /usr/bin/xray
COPY --from=xray /etc/xray/config.json /etc/xray/config.json
COPY --from=xray /usr/share/xray/geoip.dat /usr/share/xray/geoip.dat
COPY --from=xray /usr/share/xray/geosite.dat /usr/share/xray/geosite.dat

COPY --from=shadowsocks /usr/local/bin/ssserver /usr/bin/ssserver

COPY --from=go1.19.1-builder /go/src/github.com/v2ray-plugin/v2ray-plugin /usr/bin/v2ray-plugin
COPY --from=go1.19.4-builder /go/src/github.com/xray-plugin/xray-plugin /usr/bin/xray-plugin


COPY --from=builder /usr/bin/caddy /usr/bin/caddy

RUN apk add --no-cache curl tzdata openssl supervisor ca-certificates aws-cli jq

COPY supervisor.d/crazy.ini /etc/supervisor.d/crazy.ini
COPY v2ray.json /etc/crazy/v2ray.json
COPY xray.json /etc/crazy/xray.json
COPY hooks /etc/crazy/hooks
COPY scripts /etc/crazy/scripts
COPY shadowsocks.json /etc/crazy/shadowsocks.json
COPY shadowsocks.json /etc/shadowsocks-rust/config.json

COPY boot.sh /etc/crazy/boot.sh
COPY v2ray.sh /etc/crazy/v2ray.sh
COPY xray.sh /etc/crazy/xray.sh
COPY ssserver.sh /etc/crazy/ssserver.sh

ENV AWS_DEFAULT_OUTPUT=json
ENV AWS_DEFAULT_REGION=us-east-1

WORKDIR /etc/crazy

ENTRYPOINT ["/usr/bin/supervisord", "--nodaemon"]
