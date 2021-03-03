### 查看帮助
> bash ceph_install.sh  
Usage:bash ceph_install.sh [master|slave] [NetMask] [ClusterIp] [ClusterIp]    
  --[master|slave]:当前节点集群角色  
  --[NetMask]:网段及掩码，示例：10.36.3.0/24  
  --[ClusterIp]:集群其他节点IP地址  
  
### 默认基础目录
> /etc/ceph  
/var/lib/ceph  
/var/log/ceph  

### 默认镜像版本
> ceph/daemon:v3.0.5-stable-3.0-luminous-centos-7

### 修改镜像
> sed -i "s|ceph/daemon:v3.0.5-stable-3.0-luminous-centos-7|你的镜像地址|g" ./ceph_install.sh

### 注意事项
* 集群默认三节点  
* 集群节点之间需要提前做ssh免密钥，脚本需要先在master节点执行生成配置文件并将配置文件打包通过ssh发送给集群其他节点，确保集群配置一致；  
* master节点执行脚本时需要传递四个参数，最后两个参数为集群其他节点IP地址，用于ssh发送配置文件；  
* slave节点执行脚本时只需要传递两个参数。
