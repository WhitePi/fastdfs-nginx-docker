# Docker for fastdfs
基于

[fastdfs](https://github.com/happyfish100/fastdfs)

[fastdfs-nginx](https://github.com/ygqygq2/fastdfs-nginx)

调整了原fastdfs-nginx的Dockerfile：
修复原使用docker compose创建后，docker start/stop/restart指令导致容器异常问题（CMD指令引发）；
修复原storage启动时storaged.log创建异常问题；
storage默认启动nginx（fastdfs-nginx-module）
tracker默认关闭nginx，如需启动nginx进行负载均衡等，可通过- NGINX_START=true进行启动

## docker run

```
docker run -dit --net=host --name tracker -v /var/fastdfs/tracker:/var/fdfs xutj/fastdfs-tracker-nginx fastdfs-tracker
docker run -dit --net=host --name storage -e TRACKER_SERVER=tracker:22122 -v /var/fastdfs/storage:/var/fdfs xutj/fastdfs-tracker-nginx fastdfs-storage
```

## docker compose

```
docker-compose -f docker-compose.yaml up -d
```

