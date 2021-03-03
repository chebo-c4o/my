# elasticsearch集群离线部署文档

## 资源  
三台服务器：
* 192.168.255.101
* 192.168.255.102
* 192.168.255.103

## 安装elasticsearch集群
> * 有网环境下下载镜像  
docker pull elasticsearch:5.6.8  
然后通过docker save/load方法将es镜像导入指定环境
> * 创建目录及权限  
mkdir /data ; chmod 777 /data
> * 调高JVM线程数限制数量  
echo "vm.max_map_count=262144" >> /etc/sysctl.conf ; sysctl -p

### 配置文件

/usr/local/esconfig/es.yml   

192.168.255.101

> cluster.name: elasticsearch-cluster  
node.name: es-node1  
network.bind_host: 0.0.0.0  
network.publish_host: 192.168.255.101   #本机ip
http.port: 9200  
transport.tcp.port: 9300  
http.cors.enabled: true  
http.cors.allow-origin: "*"  
node.master: true   
node.data: true    
discovery.zen.ping.unicast.hosts: ["192.168.255.101:9300","192.168.255.102:9300","192.168.255.103:9300"]  
discovery.zen.minimum_master_nodes: 2  

192.168.255.102

> cluster.name: elasticsearch-cluster  
node.name: es-node2  
network.bind_host: 0.0.0.0  
network.publish_host: 192.168.255.102  
http.port: 9200 
transport.tcp.port: 9300  
http.cors.enabled: true  
http.cors.allow-origin: "*"  
node.master: true   
node.data: true    
discovery.zen.ping.unicast.hosts: ["192.168.255.101:9300","192.168.255.102:9300","192.168.255.103:9300"]  
discovery.zen.minimum_master_nodes: 2  

192.168.255.103

> cluster.name: elasticsearch-cluster  
node.name: es-node3    
network.bind_host: 0.0.0.0  
network.publish_host: 192.168.255.103  
http.port: 9200  
transport.tcp.port: 9300  
http.cors.enabled: true  
http.cors.allow-origin: "*"  
node.master: true   
node.data: true    
discovery.zen.ping.unicast.hosts: ["192.168.255.101:9300","192.168.255.102:9300","192.168.255.103:9300"]  
discovery.zen.minimum_master_nodes: 2  

### 启动

三台服务器分别执行
> docker run -e ES_JAVA_OPTS="-Xms256m -Xmx256m" --restart=always -d -p 9200:9200 -p 9300:9300 -v /usr/local/esconfig/es.yml:/usr/share/elasticsearch/config/elasticsearch.yml -v /data:/usr/share/elasticsearch/data --name elasticsearch elasticsearch:5.6.8

> 如果报错：  
  OpenJDK 64-Bit Server VM warning: UseAVX=2 is not supported on this CPU, setting it to UseAVX=1  
  解决方法：  
  ES_JAVA_OPTS="-Xms256m -Xmx256m -XX:UseAVX=1"


### 测试
> curl http://136.96.63.68:9200/_cat/nodes?pretty


## 安装elasticsearch-head插件  

挑选2台服务器执行，安装head（跟logstash共用一个vip）

> docker run --restart=always -d -p 9100:9100 --name es-manager  136.96.63.80:5000/elasticsearch-head:5

### 检查
> 页面访问http://136.96.63.68:9100  
将连接地址改为http://136.96.63.68:9200/  
即可看到node状态


## 部署logstash

下载镜像

> docker pull registry.cn-beijing.aliyuncs.com/tinet-hub/cti-link-logstash:v5.6.3
通过docker save/load方法导入指定物理机

创建配置文件目录，并上传配置文件
> mkdir /usr/local/logstash  
> 上传cti-link-logstash-template.json  logstash_index.conf配置文件  
>
> logstash_index.conf配置文件   #修改使用redis的vip，es主机ip，redis认证密码 password => "密码"

启动
> docker run -d --net=host --name=logstash -v /usr/local/logstash/:/usr/local/elk/logstash-5.6.3/conf/ registry.cn-beijing.aliyuncs.com/tinet-hub/cti-link-logstash:v5.6.3

## 部署kibana

挑选2台服务器执行，安装kibana（跟logstash共用一个vip）

下载镜像

> docker pull kibana:5.6.8  
通过docker save/load方法导入指定物理机

> 启动kibana  
docker run -d -p 5601:5601 --link elasticsearch -e "ELASTICSEARCH_URL=http://136.96.63.68:9200" 136.96.63.80:5000/kibana:5.6.8