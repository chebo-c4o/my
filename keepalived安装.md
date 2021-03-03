安装前准备

```bash
yum install -y openssl openssl-devel
```

一、yum方式

```bash
yum install -y keepalived
```

二、进制源码包方式

```bash
#解压文件
tar -zxvf keepalived-2.0.7.tar.gz

#编译
cd keepalived-2.0.7
#--prefix 指定安装地址
#/usr/local/keepalived/ 安装的目录
./configure --prefix=/usr/local/keepalived/

#编译并安装
make && make install
```

加入开机自启

```bash
systemctl enable keepalived
```

修改配置(没有创建就行)

```bash
vi /etc/keepalived/keepalived.conf
global_defs {
    notification_email {
        #mr@mruse.cn       # 指定keepalived在发生切换时需要发送email到的对象，一行一个
        #sysadmin@firewall.loc
    }
    notification_email_from xxx@163.com   # 指定发件人
    smtp_server smtp@163.com              # smtp 服务器地址
    smtp_connect_timeout 30               # smtp 服务器连接超时时间
    router_id LVS_1 # 标识本节点的字符串,通常为hostname,但不一定非得是hostname,故障发生时,邮件通知会用到
    }

vrrp_instance VI_1 {  # 实例名称
    state MASTER      # 可以是MASTER或BACKUP，不过当其他节点keepalived启动时会将priority比较大的节点选举为MASTER
    interface eth0    # 节点固有IP（非VIP）的网卡，用来发VRRP包做心跳检测
    mcast_src_ip  172.24.35.68 #本机的ip，需要修改
    virtual_router_id 51 # 虚拟路由ID,取值在0-255之间,用来区分多个instance的VRRP组播,同一网段内ID不能重复;主备必须为一样;
    priority 100      # 用来选举master的,要成为master那么这个选项的值最好高于其他机器50个点,该项取值范围是1-255(在此范围之外会被识别成默认值100)
    advert_int 1      # 检查间隔默认为1秒,即1秒进行一次master选举(可以认为是健康查检时间间隔)
    authentication {  # 认证区域,认证类型有PASS和HA（IPSEC）,推荐使用PASS(密码只识别前8位)
        auth_type PASS  # 默认是PASS认证
        auth_pass MrUse # PASS认证密码
    }
    virtual_ipaddress {
        192.168.0.219    # 虚拟VIP地址,允许多个
    }
}
```

启动，检查

```bash
systemctl start keepalived
[root@izs3l77ihmekj0z ~]# systemctl status keepalived
● keepalived.service - LVS and VRRP High Availability Monitor
   Loaded: loaded (/usr/lib/systemd/system/keepalived.service; enabled; vendor preset: disabled)
   Active: active (running) since Sun 2019-12-15 21:38:29 CST; 51s ago
  Process: 21451 ExecStart=/usr/sbin/keepalived $KEEPALIVED_OPTIONS (code=exited, status=0/SUCCESS)
 Main PID: 21452 (keepalived)
   CGroup: /system.slice/keepalived.service
           ├─21452 /usr/sbin/keepalived -D
           ├─21453 /usr/sbin/keepalived -D
           └─21454 /usr/sbin/keepalived -D

Dec 15 21:38:32 izs3l77ihmekj0z Keepalived_vrrp[21454]: Sending gratuitous ARP on eth0 for 192.168.0.219
Dec 15 21:38:32 izs3l77ihmekj0z Keepalived_vrrp[21454]: Sending gratuitous ARP on eth0 for 192.168.0.219
Dec 15 21:38:32 izs3l77ihmekj0z Keepalived_vrrp[21454]: Sending gratuitous ARP on eth0 for 192.168.0.219
Dec 15 21:38:32 izs3l77ihmekj0z Keepalived_vrrp[21454]: Sending gratuitous ARP on eth0 for 192.168.0.219
Dec 15 21:38:37 izs3l77ihmekj0z Keepalived_vrrp[21454]: Sending gratuitous ARP on eth0 for 192.168.0.219
Dec 15 21:38:37 izs3l77ihmekj0z Keepalived_vrrp[21454]: VRRP_Instance(VI_1) Sending/queueing gratuitous ARPs on eth0 for 192.168.0.219
Dec 15 21:38:37 izs3l77ihmekj0z Keepalived_vrrp[21454]: Sending gratuitous ARP on eth0 for 192.168.0.219
Dec 15 21:38:37 izs3l77ihmekj0z Keepalived_vrrp[21454]: Sending gratuitous ARP on eth0 for 192.168.0.219
Dec 15 21:38:37 izs3l77ihmekj0z Keepalived_vrrp[21454]: Sending gratuitous ARP on eth0 for 192.168.0.219
Dec 15 21:38:37 izs3l77ihmekj0z Keepalived_vrrp[21454]: Sending gratuitous ARP on eth0 for 192.168.0.219
[root@izs3l77ihmekj0z ~]# ip add
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN qlen 1
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP qlen 1000
    link/ether 00:16:3e:0c:0f:2d brd ff:ff:ff:ff:ff:ff
    inet 172.24.35.68/18 brd 172.24.63.255 scope global dynamic eth0
       valid_lft 315165282sec preferred_lft 315165282sec
    inet 192.168.0.219/32 scope global eth0
       valid_lft forever preferred_lft forever
```





