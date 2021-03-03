#!/bin/bash
#written by panf

#若命令失败让脚本退出
set -o errexit
#若未设置的变量被使用让脚本退出
set -o nounset

workdir=`pwd`
HostIp=`hostname -I | awk '{print $1}'`

if [[ $# -ne 2 && $# -ne 4 ]];then
    echo && echo -e "Usage:bash ceph_install.sh [master|slave] [NetMask] [ClusterIp] [ClusterIp]
  --[master|slave]:当前节点集群角色
  --[NetMask]:网段及掩码，示例：10.36.3.0/24
  --[ClusterIp]:集群其他节点IP地址" && echo && exit
fi

## 判断docker是否部署启动
command docker &> /dev/bull

## 创建基础目录
if [ ! -d /etc/ceph ];then
    mkdir -p /etc/ceph
fi

if [ ! -d /var/lib/ceph ];then
    mkdir -p /var/lib/ceph
fi

if [ ! -d /var/log/ceph ];then
    mkdir -p /var/log/ceph
    chmod -R 777 /var/log/ceph
fi

check_cont_up(){
for i in `docker ps -a | grep Exited | grep -w mon | awk '{print $1}'`
do
    echo -e "mon容器异常，ContainerId:$i"  && exit
done
}

mon_install(){
num=`docker ps -a | grep -w mon | wc -l`
ContainerId=`docker ps -a | grep -w mon | awk '{print $1}'`
if [ $num -ne 0 ];then
    docker stop $ContainerId
	docker rm $ContainerId
fi
docker run -d --net=host --name=mon  \
           -v /var/log/ceph:/var/log/ceph \
	   -v /etc/ceph:/etc/ceph \
           -v /var/lib/ceph/:/var/lib/ceph \
	   -v /etc/localtime:/etc/localtime \
           -e MON_IP=$HostIp \
           -e CEPH_PUBLIC_NETWORK=$1 \
           ceph/daemon:v3.2.12-stable-3.2-luminous-centos-7 mon
}

osd_install(){
num=`docker ps -a | grep -w osd | wc -l`
ContainerId=`docker ps -a | grep -w osd | awk '{print $1}'`
if [ $num -ne 0 ];then
    docker stop $ContainerId
	docker rm $ContainerId
fi
docker run -d --net=host --name=osd --pid=host \
           --privileged=true \
           -v /etc/ceph:/etc/ceph \
           -v /etc/localtime:/etc/localtime \
           -v /var/lib/ceph:/var/lib/ceph \
           -v /dev/:/dev/ \
           -v /app:/var/lib/ceph/osd \
           ceph/daemon:v3.2.12-stable-3.2-luminous-centos-7 osd_directory
}

rgw_install(){
num=`docker ps -a | grep -w rgw | wc -l`
ContainerId=`docker ps -a | grep -w rgw | awk '{print $1}'`
if [ $num -ne 0 ];then
    docker stop $ContainerId
	docker rm $ContainerId
fi
docker run -d --net=host --name=rgw  \
           -v /etc/ceph:/etc/ceph \
           -v /etc/localtime:/etc/localtime \
           -v /var/lib/ceph/:/var/lib/ceph \
           ceph/daemon:v3.2.12-stable-3.2-luminous-centos-7 rgw
}

mgr_install(){
num=`docker ps -a | grep -w mgr | wc -l`
ContainerId=`docker ps -a | grep -w mgr | awk '{print $1}'`
if [ $num -ne 0 ];then
    docker stop $ContainerId
	docker rm $ContainerId
fi
docker run -d --net=host --name=mgr  \
           -v /etc/localtime:/etc/localtime \
           -v /etc/ceph:/etc/ceph \
           -v /var/lib/ceph/:/var/lib/ceph \
           ceph/daemon:v3.2.12-stable-3.2-luminous-centos-7 mgr
}

if [ $1 = "master" ];then

mon_install $2

sleep 10

echo "osd pool default size = 2
rgw_frontends = "civetweb port=8080"
mon clock drift allowed = 2
mon clock drift warn backoff = 30
" >> /etc/ceph/ceph.conf
docker restart mon

sleep 5 && check_cont_up
docker exec mon ceph osd pool create cticloud 128 && check_cont_up
docker exec mon ceph osd pool application enable cticloud rbd && check_cont_up

tar -cvf etc_ceph.tar /etc/ceph  &> /dev/null
tar -cvf var_lib_ceph.tar /var/lib/ceph/bootstrap* &> /dev/null

scp ./etc_ceph.tar root@$4:/tmp &> /dev/null
scp ./etc_ceph.tar root@$3:/tmp &> /dev/null

scp ./var_lib_ceph.tar root@$4:/tmp &> /dev/null
scp ./var_lib_ceph.tar root@$3:/tmp &> /dev/null

elif [ $1 = "slave" ];then
tar -xf /tmp/etc_ceph.tar -C / &> /dev/null
tar -xf /tmp/var_lib_ceph.tar -C / &> /dev/null

mon_install $2
sleep 5 && check_cont_up

else
echo -e "参数输入有误，请检查..." && echo
fi

sleep 5
osd_install
rgw_install
mgr_install

#创建用户获取集群aksk，
#docker exec mon radosgw-admin user create --uid="rgwuser" --display-name="This is first rgw test user" 

