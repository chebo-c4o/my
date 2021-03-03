```bash
#防火墙，selinux一定要关
# 安装编译redis(3台都做)
tar -zxvf redis-4.0.10.tar.gz
cd redis-4.0.10
make && make install

# 创建日志目录(3台都做)
mkdir -p /home/redis/log/

# redis配置文件(3台都做 注意修改端口)
cat <<EOF > /usr/local/redisConfig/redis-6379.conf
protected-mode no
tcp-backlog 511
timeout 0
tcp-keepalive 0
daemonize yes
supervised no
loglevel notice
databases 16
stop-writes-on-bgsave-error yes
rdbcompression yes
rdbchecksum yes
slave-serve-stale-data yes
slave-read-only yes
repl-diskless-sync no
repl-diskless-sync-delay 5
repl-disable-tcp-nodelay no
appendonly no
appendfilename "appendonly.aof"
appendfsync everysec
no-appendfsync-on-rewrite no
auto-aof-rewrite-percentage 100
auto-aof-rewrite-min-size 64mb
aof-load-truncated yes
lua-time-limit 5000
slowlog-log-slower-than 10000
slowlog-max-len 128
latency-monitor-threshold 0
notify-keyspace-events ""
hash-max-ziplist-entries 512
hash-max-ziplist-value 64
list-max-ziplist-size -2
list-compress-depth 0
set-max-intset-entries 512
zset-max-ziplist-entries 128
zset-max-ziplist-value 64
hll-sparse-max-bytes 3000
activerehashing yes
client-output-buffer-limit normal 0 0 0
client-output-buffer-limit slave 256mb 64mb 60
client-output-buffer-limit pubsub 32mb 8mb 60
hz 10
aof-rewrite-incremental-fsync yes
dbfilename "dump-6379.rdb"
maxmemory 4gb
maxclients 10000
pidfile "/var/run/redis-6379.pid"
logfile "/home/redis/log/redis-6379log"
port 6379
masterauth "180aCd3ee-005"
requirepass "180aCd3ee-005"
dir "/home/redis/dump"                                          #该目录要手动创建
EOF

# 两个从节点添加配置(注意修改主redis地址端口)
cat <<EOF >> /usr/local/redisConfig/redis-6379.conf
slaveof 192.68.255.101 6379
slave-priority 110
EOF

# 启动redis
/usr/local/bin/redis-server /usr/local/redisConfig/redis-6379.conf

# 验证主从关系
# Replication
role:master
connected_slaves:2
slave0:ip=172.16.203.82,port=6378,state=online,offset=154,lag=0
slave1:ip=172.16.203.83,port=6378,state=online,offset=154,lag=1

# 配置sentinel
cat <<EOF > /usr/local/redisConfig/sentinel.conf
port 26379
bind 0.0.0.0
daemonize yes
pidfile "/var/run/redis-sentinel.pid"
logfile "/var/log/redis/sentinel.log"
dir "/tmp"

sentinel monitor paasmaster6379 192.168.255.101（主ip） 6379 2
sentinel down-after-milliseconds paasmaster6379 5000
sentinel failover-timeout paasmaster6379 15000
sentinel client-reconfig-script paasmaster6379 /usr/local/redisConfig/notify_master6379.sh
sentinel auth-pass paasmaster6378 180aCd3ee-005

EOF

# 添加VIP漂移脚本
cat <<'EOF' > /usr/local/redisConfig/notify_master6379.sh
#!/bin/bash

MASTER_IP=$6  #第六个参数是新主redis的ip地址

LOCAL_IP='192.168.255.101'  #这里记得要改，每台服务器写自己的本地ip即可

VIP='192.168.255.104'

NETMASK='24'

INTERFACE='ens33' #网卡接口设备名称

if [[ ${MASTER_IP} = ${LOCAL_IP} ]]; then

    /usr/sbin/ip  addr  add ${VIP}/${NETMASK}  dev ${INTERFACE}  #将VIP绑定到该服务器上

    /usr/sbin/arping -q -c 3 -A ${VIP} -I ${INTERFACE}

    exit 0

else

   /usr/sbin/ip  addr del  ${VIP}/${NETMASK}  dev ${INTERFACE}   #将VIP从该服务器上删除

   exit 0

fi

exit 1
EOF

# 给脚本加执行权限
chmod +x notify_master6378.sh

# 创建日志目录
mkdir -p /var/log/redis

# 启动sentinel
/usr/local/bin/redis-sentinel /usr/local/redisConfig/sentinel.conf

# 连接sentinel
# Sentinel
sentinel_masters:1
sentinel_tilt:0
sentinel_running_scripts:0
sentinel_scripts_queue_length:0
sentinel_simulate_failure_flags:0
master0:name=paasmaster6378,status=ok,address=172.16.203.81:6378,slaves=2,sentinels=3

# 手动为master添加VIP  
/usr/sbin/ip  addr  add(del) 172.16.203.88/24  dev em1
```

