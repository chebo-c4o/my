# k8s集群部署

``` 
安装部署docker，k8s
准备工作
 安装依赖包
yum install -y yum-utils   device-mapper-persistent-data   lvm2
设置Docker源
yum-config-manager     --add-repo     https://download.docker.com/linux/centos/docker-ce.repo
安装Docker CE
docker安装版本查看
yum list docker-ce --showduplicates | sort -r
安装docker
yum install -y docker-ce-18.06.2.ce-3.el7 docker-ce-cli-18.06.2.ce-3.el7 containerd.io
启动Docker
systemctl start docker
systemctl enable docker
命令补全
yum -y install bash-completion
source /etc/profile.d/bash_completion.sh
镜像加速
/etc/docker/daemon.json
{
"registry-mirrors": ["https://baydy5cf.mirror.aliyuncs.com"]
}
systemctl daemon-reload
systemctl restart docker
验证
 docker --version
docker run hello-world
k8s安装准备工作
修改hosts文件
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
192.168.122.207 k8s-node1.linux.com
192.168.122.208 k8s-node2.linux.com
192.168.122.209 k8s-node3.linux.com
禁用swap，修改配置文件/etc/fstab，注释swap。
修改内核参数
/etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
sysctl -p /etc/sysctl.d/k8s.conf
修改Cgroup Driver
[root@master ~]# more /etc/docker/daemon.json 
{
 "registry-mirrors": ["https://baydy5cf.mirror.aliyuncs.com"],
  "exec-opts": ["native.cgroupdriver=systemd"]，
"insecure-registries":["192.168.255.13:5000", "registry:5000"]
}

$ cat > /etc/sysctl.d/kubernetes.conf <<EOF
net.bridge.bridge-nf-call-iptables=1
net.bridge.bridge-nf-call-ip6tables=1
net.ipv4.ip_forward=1
vm.swappiness=0
vm.overcommit_memory=1
vm.panic_on_oom=0
fs.inotify.max_user_watches=89100
EOF
重新加载docker
systemctl daemon-reload
systemctl restart docker
设置kubernetes源
vim /etc/yum.repos.d/k8s.repo
[k8s]
name=k8s
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=0
更新缓存
yum clean all
yum -y makecache
版本查看
yum list kubelet --showduplicates | sort -r 
安装kubelet、kubeadm和kubectl
yum install -y kubelet-1.14.1 kubeadm-1.14.1 kubectl-1.14.1 kubernetes-cni-0.7.5
启动kubelet并设置开机启动
systemctl enable kubelet && systemctl start kubelet
kubelet命令补全
echo "source <(kubectl completion bash)" >> ~/.bash_profile
source .bash_profile 
Kubernetes几乎所有的安装组件和Docker镜像都放在goolge自己的网站上,直接访问可能会有网络问题，这里的解决办法是从阿里云镜像仓库下载镜像，拉取到本地以后改回默认的镜像tag。
[root@master ~]# more image.sh 
#!/bin/bash
url=registry.cn-hangzhou.aliyuncs.com/google_containers
version=v1.14.2
images=(`kubeadm config images list --kubernetes-version=$version|awk -F '/' '{print $2}'`)
for imagename in ${images[@]} ; do
  docker pull $url/$imagename
  docker tag $url/$imagename k8s.gcr.io/$imagename
  docker rmi -f $url/$imagename
done

初始化Master(作为master节点加入只需要拷贝证书然后加入即可，作为node加入直接加入即可)
[root@master ~]#kubeadm init --image-repository=registry.aliyuncs.com/google_containers --apiserver-advertise-address 10.36.3.155  --pod-network-cidr=172.31.0.0/16 --kubernetes-version=v1.14.1
加载环境变量
 [root@master ~]# echo "export KUBECONFIG=/etc/kubernetes/admin.conf" >> ~/.bash_profile
[root@master ~]# source .bash_profile 
本文所有操作都在root用户下执行，若为非root用户，则执行如下操作：
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config
安装pod网络
wget https://docs.projectcalico.org/v3.5/getting-started/kubernetes/installation/hosted/kubernetes-datastore/calico-networking/1.7/calico.yaml   

进入calico.yaml文件
kind: DaemonSet
apiVersion: apps/v1    #将yml配置文件内的api接口修改为 apps/v1 ，导致原因为之间使用的kubernetes 版本是1.14.x版本，1.16.x 版本放弃部分API支持
镜像地址改为可用的，或是本地镜像仓库
- name: CALICO_IPV4POOL_CIDR
  value: "172.31.0.0/16"    #改为初始化时的pod网段
  
污点
删除master节点默认污点
查看污点：
[root@master ~]# kubectl describe node master|grep -i taints
Taints:             node-role.kubernetes.io/master:NoSchedule
删除默认污点：
[root@master ~]# kubectl taint nodes k8s-node1.linux.com node-role.kubernetes.io/master-
node/master untainted
加污点
kubectl taint nodes k8s-master(节点名称) node-role.kubernetes.io/master=true:NoSchedule


污点
删除master节点默认污点
查看污点：
[root@master ~]# kubectl describe node master|grep -i taints
Taints:             node-role.kubernetes.io/master:NoSchedule
删除默认污点：
[root@master ~]# kubectl taint nodes k8s-node1.linux.com node-role.kubernetes.io/master-
node/master untainted
加污点
kubectl taint nodes k8s-master(节点名称) node-role.kubernetes.io/master=true:NoSchedule


3master
实时修改kubeadm-config配置文件
kubectl -n kube-system edit cm kubeadm-config
kubeadm.yaml
# Please edit the object below. Lines beginning with a '#' will be ignored,
# reopened with the relevant failures.
#
apiVersion: v1
data:
  ClusterConfiguration: |
    apiServer:
      extraArgs:
        authorization-mode: Node,RBAC
      timeoutForControlPlane: 4m0s
    apiVersion: kubeadm.k8s.io/v1beta1
    certificatesDir: /etc/kubernetes/pki
    clusterName: kubernetes
    controlPlaneEndpoint: "192.168.122.207:6443" ##如果要创建三master这里不能为空
    controllerManager: {}
    dns:
      type: CoreDNS
    etcd:
      local:
        dataDir: /var/lib/etcd
    imageRepository: k8s.gcr.io
    kind: ClusterConfiguration
    kubernetesVersion: v1.14.1
    networking:
      dnsDomain: cluster.local
      podSubnet: 10.1.0.0/16
      serviceSubnet: 10.96.0.0/12
    scheduler: {}
  ClusterStatus: |
    apiEndpoints:
      k8s-node1.linux.com:
        advertiseAddress: 192.168.122.207
        bindPort: 6443
    apiVersion: kubeadm.k8s.io/v1beta1
    kind: ClusterStatus
kind: ConfigMap


#################################################################
如果要在其他的master节点上能执行kubectl 需要执行以下操作
To start administering your cluster from this node, you need to run the following as a regular user:

	mkdir -p $HOME/.kube
	sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
	sudo chown $(id -u):$(id -g) $HOME/.kube/config

Run 'kubectl get nodes' to see this node join the cluster.

在master上生成新的token
kubeadm token create --print-join-command
在master上生成用于新master加入的证书
kubeadm init phase upload-certs --expe-upload-certs #v1.15以上版本选项为--upload-certs
添加新master（以master的身份加入集群）
kubeadm join 172.31.182.156:6443  --token ortvag.ra0654faci8y8903 \
  --discovery-token-ca-cert-hash sha256:04755ff1aa88e7db283c85589bee31fabb7d32186612778e53a536a297fc9010 \
 --experimental-control-plane --certificate-key      #v1.15以上版本选项为--control-plane   f8d1c027c01baef6985ddf24266641b7c64f9fd922b15a32fce40b6b4b21e47d
添加新node
kubeadm join 172.31.182.156:6443 --token ortvag.ra0654faci8y8903     --discovery-	token-ca-cert-hash sha256:04755ff1aa88e7db283c85589bee31fabb7d32186612778e53a536a297fc9010
```

 