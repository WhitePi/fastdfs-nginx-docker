# Docker for fastdfs
base on

[fastdfs](https://github.com/happyfish100/fastdfs)

[fastdfs-nginx](https://github.com/ygqygq2/fastdfs-nginx)

## docker run

```
docker run -dit --net=host --name tracker -v /var/fastdfs/tracker:/var/fdfs xutj/fastdfs-tracker-nginx:latest tracker
docker run -dit --net=host --name storage -e TRACKER_SERVER=tracker:22122 -v /var/fastdfs/storage:/var/fdfs xutj/fastdfs-tracker-nginx:latest storage
```

## docker compose

```
docker-compose -f docker-compose.yml up -d
```

