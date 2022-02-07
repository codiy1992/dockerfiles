#!/bin/bash

# ims/imr 两个服务默认后台去年，im默认前台运行防止docker开启后直接关闭

nohup /go/bin/ims -log_dir=/data/logs/ims /data/config/ims.cfg >/data/logs/ims/ims.log 2>&1 &
nohup /go/bin/imr -log_dir=/data/logs/imr /data/config/imr.cfg >/data/logs/imr/imr.log 2>&1 &
exec /go/bin/im  -log_dir=/data/logs/im  /data/config/im.cfg  >/data/logs/im/im.log