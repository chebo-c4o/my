```
docker 部署postgresql主从

创建镜像仓库
docker run -d -p 5000:5000 --restart always --name registry --privileged -v /mnt/registry:/var/lib/registry registry:2
镜像打标
docker tag acf5fb8bfd76 192.168.122.101:5000/postgresql:v1
上传镜像
docker push 192.168.122.101:5000/postgresql:v1
使用仓库需要修改daemon文件并重启docker
vim /etc/docker/daemon.json  
{
"registry-mirrors": ["https://baydy5cf.mirror.aliyuncs.com"],
"insecure-registries": ["192.168.122.101:5000"]
}
创建容器
docker run -tid --privileged --name postgres -e POSTGRES_PASSWORD=postgres -p 15432:5432 -v /data:/var/lib/postgresql/data postgres
主库查看主从状态
select * from pg_stat_replication;
同步主库数据（也可以用其他方法）
新建一个容器又来同步主库的数据
docker run -tid --privileged --name postgres_test -e POSTGRES_PASSWORD=postgres -p 25432:5432 -v /data:/data postgres
进入test容器执行
pg_basebackup -h 192.168.122.101 -p 15432 -U postgres -F p -P -R -D /data 
新建容器，此时的容器已经成为从库
docker run -tid --privileged --name postgres -e POSTGRES_PASSWORD=postgres -p 15432:5432 -v /data:/var/lib/postgresql/data postgres
从库查看receiver进程状态
select * from pg_stat_wal_receiver;

```

