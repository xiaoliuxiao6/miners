使用国内服务器下载 Docker 镜像的时候会经常出现下载缓慢甚至无法下载的问题，搭建本地镜像缓存服务器可以方便的解决这个问题。

另外在跑 io.net 项目的时候，大部分的流量其实都是被下载镜像使用了，采用此方法可以大大减少外网流量使用。

进行以下设置后，局域网所有机器拉取镜像的时候，会先检测本地缓存服务器是否有缓存镜像

- 如果本地缓存有此镜像，则直接从本地缓存拉取，不需要走外网流量来拉取
- 如果本地缓存没有此镜像，则缓存服务器会想将镜像缓存，然后供内网机器拉取
- 如果缓存服务器由于各种原因时效或者无法连接，则会直接通过外网拉取，不会造成镜像拉取失败

## 第一步：首选需要在内网找一台机器做为缓存服务器
1. `http://10.1.7.28:7890` 将其替换为内网代理服务器地址，可以解决国内 IP 下载镜像慢的问题
2. `/var/lib/registry` 存储缓存镜像的位置

```sh
## 删除现有容器
docker rm -f registry-proxy

## 启动新容器
docker run \
-it \
-d \
--name registry-proxy \
--restart=always \
-p 0.0.0.0:5000:5000 \
-v /var/lib/registry:/var/lib/registry \
--env http_proxy=http://10.1.7.28:7890 \
--env https_proxy=http://10.1.7.28:7890 \
--env REGISTRY_PROXY_REMOTEURL=https://registry-1.docker.io \
registry:2

## 查看日志
docker logs -f registry-proxy
```

## 第二步：在内网其他机器上做以下设置
- 将 10.1.7.25:5000 替换为第一步选定机器的内网 IP

```sh
## 修改 Docker 配置文件
cat <<\EOF > /etc/docker/daemon.json 
{
    "insecure-registries": [
        "10.1.7.25:5000",
    ]
    "registry-mirrors": [
        "http://10.1.7.25:5000",
    ]
}

## 重启 Docker 服务让其生效
sudo systemctl daemon-reload
sudo systemctl restart docker.service

## 确认 Docker 服务运行是否正常
sudo systemctl status docker.service

## 确认配置生效
docker info
## 执行此命令后应该可以看到类似以下内容
 Insecure Registries:
  10.1.7.25:5000
 Registry Mirrors:
  http://10.1.7.25:5000/
```

