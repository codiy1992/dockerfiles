FROM golang:1.17-alpine as builder

ARG CLOUDREVE_VERSION="3.4.2"

WORKDIR /ProjectCloudreve

RUN apk update \
    && apk add git yarn build-base gcc abuild binutils binutils-doc gcc-doc

RUN git clone --recurse-submodules https://github.com/cloudreve/Cloudreve.git

RUN cd ./Cloudreve/assets \
    && yarn cache clean \
    && yarn --update-checksums \
    && yarn install --network-timeout 1000000 \
    && yarn run build

RUN cd ./Cloudreve \
    && git checkout ${CLOUDREVE_VERSION} \
    && go get github.com/rakyll/statik \
    && statik -src=assets/build/ -include=*.html,*.js,*.json,*.css,*.png,*.svg,*.ico -f \
    && export COMMIT_SHA=$(git rev-parse --short HEAD) \
    && go build -a -o cloudreve-main -ldflags " -X 'github.com/cloudreve/Cloudreve/v3/pkg/conf.BackendVersion=$CLOUDREVE_VERSION' -X 'github.com/cloudreve/Cloudreve/v3/pkg/conf.LastCommit=$COMMIT_SHA'"

FROM alpine:latest

ENV PUID=1000
ENV PGID=1000
ENV TZ="Asia/Shanghai"

LABEL MAINTAINER="Codiy"

WORKDIR /data

COPY --from=builder /ProjectCloudreve/Cloudreve/cloudreve-main /data/cloudreve

RUN apk update \
    && apk add tzdata \
    && cp /usr/share/zoneinfo/${TZ} /etc/localtime \
    && echo ${TZ} > /etc/timezone \
    && chmod +x /data/cloudreve

EXPOSE 5212

ENTRYPOINT ["./cloudreve", "-c", "/data/config/conf.ini"]
