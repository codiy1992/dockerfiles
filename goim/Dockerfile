FROM golang:1.15-alpine AS builder

# 安装编译工具
RUN set -ex && apk update && apk add --no-cache make git gcc libc-dev curl
RUN apk add --no-cache g++ build-base

# 编译protobuf
RUN cd /tmp && wget https://github.com/google/protobuf/releases/download/v3.6.1/protobuf-all-3.6.1.tar.gz && tar -zxvf protobuf-all-3.6.1.tar.gz
RUN cd /tmp/protobuf-3.6.1 && ./configure --prefix=/usr/local/protobuf-3.6.1/
RUN cd /tmp/protobuf-3.6.1 && make && make install

# 拷贝本地代码到容器内
ENV PROJECT_PATH=/data/gopath/src/github.com/GoBelieveIO/im_service
COPY src ${PROJECT_PATH}

# Fix bugs
RUN sed -i '529s/Infof/Fatal/' ${PROJECT_PATH}/ims/peer_storage.go
RUN sed -i '339s/Infof/Fatal/' ${PROJECT_PATH}/ims/group_storage.go
RUN sed -i '15s/bin/bin\//' ${PROJECT_PATH}/Makefile
RUN sed -i '16s/bin/bin\//' ${PROJECT_PATH}/Makefile
RUN sed -i '17s/bin/bin\//' ${PROJECT_PATH}/Makefile
RUN sed -i '50,52d' ${PROJECT_PATH}/Gopkg.toml

# install some packages
RUN go get -u github.com/gorilla/mux
RUN go get -u github.com/golang/dep/cmd/dep

# make project
RUN mkdir -p ${PROJECT_PATH}/bin
RUN export GOPATH=/data/gopath/ && \
    export GOROOT=/usr/local/go && \
    export PATH=$PATH:$GOROOT/bin:$GOPATH/bin && \
    export PATH=/usr/local/protobuf-3.6.1/bin:$PATH && \
    cd ${PROJECT_PATH} && dep ensure && make install

FROM alpine:3.17

RUN apk add --no-cache curl supervisor

WORKDIR /data

RUN mkdir -p /data/bin

COPY --from=builder /data/gopath/src/github.com/GoBelieveIO/im_service/bin/i* /data/bin/

ENTRYPOINT ["/usr/bin/supervisord", "--nodaemon"]
