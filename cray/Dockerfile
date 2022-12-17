FROM v2fly/v2fly-core AS v2fly
FROM teddysun/xray AS xray

FROM codiy/caddy:latest

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

RUN apk add --no-cache tzdata openssl supervisor ca-certificates

COPY supervisor.d/cray.ini /etc/supervisor.d/cray.ini
COPY v2ray.json /etc/cray/v2ray.json
COPY xray.json /etc/cray/xray.json

COPY boot.sh /etc/cray/boot.sh
COPY v2ray.sh /etc/cray/v2ray.sh
COPY xray.sh /etc/cray/xray.sh

ENTRYPOINT ["/usr/bin/supervisord", "--nodaemon"]
