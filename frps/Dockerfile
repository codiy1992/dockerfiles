
FROM alpine:latest

ARG FRP_VERSION
ENV FRP_VERSION ${FRP_VERSION:-0.37.1}

RUN cd /root \
    && arch=$(arch | sed s/aarch64/arm64/ | sed s/x86_64/amd64/) \
    &&  wget --no-check-certificate -c https://github.com/fatedier/frp/releases/download/v${FRP_VERSION}/frp_${FRP_VERSION}_linux_${arch}.tar.gz \
    &&  tar zxvf frp_${FRP_VERSION}_linux_${arch}.tar.gz  \
    &&  cd frp_${FRP_VERSION}_linux_${arch}/ \
    &&  cp frps /usr/bin/ \
    &&  mkdir -p /etc/frp \
    &&  cd /root \
    &&  rm frp_${FRP_VERSION}_linux_${arch}.tar.gz \
    &&  rm -rf frp_${FRP_VERSION}_linux_${arch}/

ENTRYPOINT /usr/bin/frps -c /etc/frp/frps.ini
