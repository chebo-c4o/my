### 安装说明

#### 一、目录结构

```bash
[root@iZs3l77ihmekj0Z ~]# tree
.
├── configre.json
├── keepalived.sh
└── soft
    ├── jq
    └── keepalived-2.0.7.tar.gz

1 directory, 4 files
[root@iZs3l77ihmekj0Z ~]# 
```

#### 二、配置configre.json

```bash
cat configre.json
{
  "router_id": "LVS_1",
  "vrrp_instance": [
    {
      "state": "master",
      "interface": "eth0",
      "virtual_router_id": "51",
      "priority": "100",
      "virtual_ipaddress": [
        "192.168.0.1",
        "192.168.2.3"
      ]
    },
    {
      "state": "master",
      "interface": "eth0",
      "virtual_router_id": "52",
      "priority": "101",
      "virtual_ipaddress": [
        "192.168.0.4",
        "192.168.2.8"
      ]
    }
  ]
}
```

#### 三、执行sh keepalived.sh install安装keepalived

```bash
sh keepalived.sh install

Making install in bin_install
make[1]: Entering directory `/root/soft/keepalived-2.0.7/bin_install'
make[2]: Entering directory `/root/soft/keepalived-2.0.7/bin_install'
make[2]: Nothing to be done for `install-exec-am'.
make[2]: Nothing to be done for `install-data-am'.
make[2]: Leaving directory `/root/soft/keepalived-2.0.7/bin_install'
make[1]: Leaving directory `/root/soft/keepalived-2.0.7/bin_install'
make[1]: Entering directory `/root/soft/keepalived-2.0.7'
make[2]: Entering directory `/root/soft/keepalived-2.0.7'
make[2]: Nothing to be done for `install-exec-am'.
 /usr/bin/mkdir -p '/usr/local/keepalived/share/doc/keepalived'
 /usr/bin/install -c -m 644 README '/usr/local/keepalived/share/doc/keepalived'
make[2]: Leaving directory `/root/soft/keepalived-2.0.7'
make[1]: Leaving directory `/root/soft/keepalived-2.0.7'
configure...
start...
```

安装目录：/usr/local/keepalived

配置文件目录：/etc/keepalived/keepalived.conf



