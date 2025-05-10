FROM alpine:latest

RUN apk add --no-cache \
    autoconf \
    automake \
    build-base \
    curl-dev \
    jansson-dev \
    gmp-dev \
    openssl-dev \
    git \
    supervisor \
    cpulimit

RUN git clone https://github.com/pooler/cpuminer.git /cpuminer \
    && cd /cpuminer \
    && ./autogen.sh \
    && ./configure \
    && make install

RUN apk del --no-cache build-base git \
    && rm -rf /cpuminer

COPY ./supervisor.d /etc/supervisor.d

ENTRYPOINT ["/usr/bin/supervisord", "--nodaemon"]
