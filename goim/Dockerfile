FROM golang:1.9.4-stretch

# 安装编译工具
# RUN apt install build-essential -y

# 编译protobuf
RUN cd /tmp && wget https://github.com/google/protobuf/releases/download/v3.6.1/protobuf-all-3.6.1.tar.gz && tar -zxvf protobuf-all-3.6.1.tar.gz
RUN cd /tmp/protobuf-3.6.1 && ./configure --prefix=/usr/local/protobuf-3.6.1/
RUN cd /tmp/protobuf-3.6.1 && make && make install
RUN export PATH=/usr/local/protobuf-3.6.1/bin:$PATH

# 安装依赖安装工具
RUN go get -u github.com/golang/dep/cmd/dep

# 拷贝本地代码到容器内
ADD src /go/src/habibi_im

# 编译goim
RUN cd /go/src/habibi_im && mkdir bin && dep ensure && make install

# 复制可执行文件到GOPATH/bin目录
RUN cp /go/src/habibi_im/bin/* /go/bin/
COPY docker-entrypoint.sh /go/docker-entrypoint.sh

# 安装网络工具
RUN apt update && apt install net-tools

# 开启IM的3大模块程序
RUN chmod +x /go/docker-entrypoint.sh
ENTRYPOINT ["/go/docker-entrypoint.sh"]