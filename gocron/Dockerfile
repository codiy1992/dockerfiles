FROM golang:1.15-alpine as gocron-builder

# @link https://github.com/ouqiang/gocron
RUN set -ex && apk update && apk add --no-cache make git gcc libc-dev curl bash zip yarn nodejs

RUN go env -w GO111MODULE=on

ARG GOCRON_VERSION=1.5.3
RUN curl -skLO https://github.com/ouqiang/gocron/archive/refs/tags/v${GOCRON_VERSION}.tar.gz

RUN mkdir -p /go/src/github.com && \
    tar xzf v${GOCRON_VERSION}.tar.gz && \
    mv gocron-${GOCRON_VERSION} /go/src/github.com/gocron && \
    cd /go/src/github.com/gocron && \
    yarn config set ignore-engines true && \
    make install-vue && \
    make build-vue && \
    make statik && \
    CGO_ENABLED=0 make gocron

FROM alpine:latest

RUN apk add --no-cache ca-certificates tzdata \
    && addgroup -S app \
    && adduser -S -g app app

# RUN cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

WORKDIR /app

COPY --from=gocron-builder /go/src/github.com/gocron/bin/gocron .

RUN chown -R app:app ./

EXPOSE 5920

USER app

ENTRYPOINT ["/app/gocron", "web"]
