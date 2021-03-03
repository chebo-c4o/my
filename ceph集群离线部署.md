# ceph集群离线部署文档

## 资源清单
* 172.16.0.111
* 172.16.1.1
* 172.16.0.143

系统版本：centos7  
docker版本 Docker version 18.03.1-ce, build 9ee9f40


## 准备工作

下载镜像
> docker pull ceph/daemon:v3.2.12-stable-3.2-luminous-centos-7
> 
> 没有公网的时候，在自己的环境下好，然后打成tar包方式上传到目标主机  
官方镜像ceph/daemon:latest有很多问题，不要用 /var/lib/ceph/bootstarp-*/里面不会生成key文件，安装osd的时候没有ceph-disk工具

创建目录
> mkdir -p  /etc/ceph/  /var/lib/ceph/  /var/log/ceph/  
chmod 777 -R /var/log/ceph/
三台服务器均需要创建

## 部署mon

先在 172.16.0.111部署

> docker run -d --net=host  --restart=always --name=mon -v /var/log/ceph:/var/log/ceph -v /etc/ceph:/etc/ceph -v /var/lib/ceph/:/var/lib/ceph  -v /etc/localtime:/etc/localtime -e MON_IP=192.168.255.14  -e CEPH_PUBLIC_NETWORK=192.168.255.0/24  ceph/daemon:v3.2.12-stable-3.2-luminous-centos-7  mon

> MON_IP=172.16.1.1 这个IP改为各物理机的IP

同步配置文件
> scp -r /etc/ceph/*  root@192.168.255.15:/etc/ceph/   
scp -r /etc/ceph/*  root@192.168.255.16:/etc/ceph/   
scp -r /var/lib/ceph/bootstrap-*  root@192.168.255.15:/var/lib/ceph/  
scp -r /var/lib/ceph/bootstrap-*  root@192.168.255.16:/var/lib/ceph/

> 再在172.16.1.1、172.16.0.143同样方法部署mon

> 检查mon日志  
> creating /etc/ceph/ceph.client.admin.keyring  
creating /etc/ceph/ceph.mon.keyring  
creating /var/lib/ceph/bootstrap-osd/ceph.keyring  
creating /var/lib/ceph/bootstrap-mds/ceph.keyring  
creating /var/lib/ceph/bootstrap-rgw/ceph.keyring  
检查这些关键日志信息是否存在  


如果想要设置ceph开机自启动，要在docker run的时候加--restart=always

## 部署osd

三台服务器分别执行  

用裸磁盘方式启动

> docker run -d --net=host  --restart=always  --name=myosd2 --privileged=true -v /etc/ceph:/etc/ceph -v /var/lib/ceph/:/var/lib/ceph -v /dev/:/dev/ -v /etc/localtime:/etc/localtime  -e OSD_DEVICE=/dev/sdb   172.16.203.83:5000/ceph:v3.2.12-stable-3.2-luminous-centos-7  osd_ceph_disk

用本地目录方式
> docker run -d --net=host --restart=always --name=osd --privileged=true --pid=host  -v /etc/ceph:/etc/ceph -v /etc/localtime:/etc/localtime  -v /var/lib/ceph:/var/lib/ceph -v /dev/:/dev/ -v /app:/var/lib/ceph/osd   ceph/daemon:v3.2.12-stable-3.2-luminous-centos-7  osd_directory   #k8s映射目录用该方式


## 部署rgw

三台服务器分别执行

> docker run -d --net=host --restart=always   --name=rgw -v /etc/ceph:/etc/ceph -v /etc/localtime:/etc/localtime  -v /var/lib/ceph/:/var/lib/ceph   172.16.203.83:5000/ceph:v3.2.12-stable-3.2-luminous-centos-7  rgw 


## 部署mgr

三台服务器分别执行

> docker run -d --net=host --restart=always  --name=mgr -v /etc/localtime:/etc/localtime -v /etc/ceph:/etc/ceph -v /var/lib/ceph/:/var/lib/ceph  172.16.203.83:5000/ceph:v3.2.12-stable-3.2-luminous-centos-7  mgr


## 使用对象存储

创建用户，获得AK SK

> docker exec mon radosgw-admin user create --uid="rgwuser" --display-name="This is first rgw test user"  --access-key="0OGXRYVJCW6OMA0870HZ"  --secret="b1ugFAghCeCc4XO5P48A8nKpY7WxHZUg1hc18lVn"     #使用指定的ack和sk使用对象存储

创建

> ceph osd pool create cticloud 128  
ceph osd pool application enable cticloud rbd


查看集群状态
> docker exec mon ceph -s



[root@ceph-68 ~]# docker exec mon radosgw-admin user create --uid="rgwuser" --display-name="This is first rgw test user"
{
    "user_id": "rgwuser",
    "display_name": "This is first rgw test user",
    "email": "",
    "suspended": 0,
    "max_buckets": 1000,
    "auid": 0,
    "subusers": [],
    "keys": [
        {
            "user": "rgwuser",
            "access_key": "OK61A8STST3DYW9ABV8F",
            "secret_key": "co6WoqumvOYBB5WdMDZgHzYXDOf6stCqj13cBsFA"
        }
    ],
    "swift_keys": [],
    "caps": [],
    "op_mask": "read, write, delete",
    "default_placement": "",
    "placement_tags": [],
    "bucket_quota": {
        "enabled": false,
        "check_on_raw": false,
        "max_size": -1,
        "max_size_kb": 0,
        "max_objects": -1
    },
    "user_quota": {
        "enabled": false,
        "check_on_raw": false,
        "max_size": -1,
        "max_size_kb": 0,
        "max_objects": -1
    },
    "temp_url_keys": [],
    "type": "rgw"
}

## 测试对象存储

1.安装s3cmd： 	pip install s3cmd 

2.创建配置文件：

 [root@hu230 ~]# cat /root/.s3cfg 

 [default] 

access_key = CH9Q9868NK96G2V3FYXW 

secret_key = TbRFPS3DXV53zwWkwEhGJ9OwX2zk9FCTdMwZ3cit 

host_base = xxx.xxx.10.203:7480 

host_bucket = xxx.xxx.10.203:7480

signature_v2=True

use_https = False 

3.测试：

 s3cmd ls  #查看可用的bucket 

s3cmd mb s3://xxx_bucket  #创建bucket，且bucket名字是唯一的，不能重复 

s3cmd ls s3://xxx_bucket #列出bucket内容 

s3cmd put xx.txt s3://xxx_bucket  #上传本地file到指定的bucket 

s3cmd put --acl-public xx.txt s3://xxx_bucket  #上传公开访问权限的文件 

s3cmd get s3://xxx_bucket  /xx.txt  #下载file到本地 

s3cmd rb s3://my-bucket-name删除空 bucket 

s3cmd du -H s3://my-bucket-namebucket所占用的空间大小

```bash
1、配置，主要是 Access Key ID 和 Secret Access Key
s3cmd --configure

2、列举所有 Buckets。（bucket 相当于根文件夹）
s3cmd ls

3、创建 bucket，且 bucket 名称是唯一的，不能重复，默认创建的 bucket 是公开的。
s3cmd mb s3://my-bucket-name

4、删除空 bucket
s3cmd rb s3://my-bucket-name

5、列举 Bucket 中的内容
s3cmd ls s3://my-bucket-name

6、上传
s3cmd put file.txt s3://my-bucket-name/file.txt

支持批量上传，直接指定多个文件，如
s3cmd put t.py s3://tccpoc/t.py up.py s3://tccpoc/up.py

如果上传终断，比如ctrl+c，会显示upload-id，按照指示，带上`--upload-id`就可以实现断点上传

7、上传并将权限设置为所有人可读
s3cmd put --acl-public file.txt s3://my-bucket-name/file.txt
--acl-private，也可以是私有

8、批量上传文件
s3cmd put ./* s3://my-bucket-name/

9、下载文件
s3cmd get s3://my-bucket-name/file.txt file.txt

支持批量下载，直接指定多个文件，如
s3cmd get s3://tccpoc/t.py s3://tccpoc/up.py

如果下载终断，比如ctrl+c，带上参数`--continue`,可以实现断点下载

10、批量下载
s3cmd get s3://my-bucket-name/* ./

11、删除文件，
s3cmd del s3://my-bucket-name/file.txt

支持批量删除，直接指定多个 bucket 对象，如
s3cmd del s3://my-bucket-name/file.txt s3://my-bucket-name/file2.txt

12、来获得对应的bucket所占用的空间大小
s3cmd du -H s3://my-bucket-name
```

> 上传大文件时，使用 --multipart-chunk-size-mb=size 指定的分片大小必须是4的倍数，否则上传会报 400（InvalidPartOrder）

其他常用参数

```bash
复制  --list-md5                 结合list一起使用，打印md5
  -H, --human-readable-sizes 人性化文件大小
  -v, --verbose              显示详细的输出
  -d, --debug                调试信息
  --limit-rate=LIMITRATE     限速
```

文件同步相关

```bash
复制  --exclude=GLOB				通配
  --exclude-from=FILE   从文件读取排除列表
  --rexclude=REGEXP     正则形式的匹配排除
  --rexclude-from=FILE  从文件读取正则形式的匹配排除
  
  --include=GLOB        通配
  --include-from=FILE   从文件读取文件列表
  --rinclude=REGEXP     正则匹配
  --rinclude-from=FILE  从文件读取正则匹配
# 示例
# s3cmd sync --exclude '*' --include 'link*' images/ s3://files
upload: 'images/link.png' -> 's3://files/link.png'  [1 of 1]
 8094 of 8094   100% in    0s   206.34 kB/s  done

# s3cmd sync --exclude '*' --include 'link*' s3://files images2
download: 's3://files/link.png' -> 'images2/link.png'  [1 of 1]
 8094 of 8094   100% in    0s   323.87 kB/s  done
Done. Downloaded 8094 bytes in 1.0 seconds, 7.90 kB/s.
```

ACL

```bash
复制# s3cmd modify s3://files/link.png --acl-private
# s3cmd modify s3://files/link.png --acl-public
```

