# 编译步骤

### 下载GoBelieveIO源码
http://git.wangle.ltd/habibi/GoBelieveIO 代码到src目录, 仅源码不要有子目录

### 编译容器
docker build -t goim .

### 修改配置文件
导入Mysql表结构: habibi_im/db.sql
修改configs目录下配置文件的redis/mysql服务器配置

### 运行容器
docker run -it --rm -v "$PWD/data":/data goim

### 查看运行情况

```
root@e0f033f20371:/go# netstat -lntp
Active Internet connections (only servers)
Proto Recv-Q Send-Q Local Address           Foreign Address         State       PID/Program name
tcp6       0      0 :::3334                 :::*                    LISTEN      7/ims
tcp6       0      0 :::6666                 :::*                    LISTEN      1/im
tcp6       0      0 :::13333                :::*                    LISTEN      7/ims
tcp6       0      0 :::23000                :::*                    LISTEN      1/im
tcp6       0      0 :::16666                :::*                    LISTEN      8/imr
tcp6       0      0 :::4444                 :::*                    LISTEN      8/imr
tcp6       0      0 :::13890                :::*                    LISTEN      1/im
```