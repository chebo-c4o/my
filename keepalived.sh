#!/bin/bash
#若命令失败让脚本退出
set -o errexit
#若未设置的变量被使用让脚本退出
set -o nounset

dir_pwd=`dirname $0`


install(){
    echo "install..."
    openssl=$(rpm -qa|grep openssl|wc -l)
    if [ $openssl == 0 ]; then
        echo "openssl is not install..."
        exit 1
    fi
    openssl_devel=$(rpm -qa|grep openssl-devel|wc -l)
    if [ $openssl_devel == 0 ]; then
        echo "openssl-devel is not install..."
        exit 1
    fi
    if [ ! -f /etc/keepalived/keepalived.conf ];then
        cd soft
        #加压二进制源码包
        tar -zxvf keepalived-2.0.7.tar.gz
        cd keepalived-2.0.7
        #配置
        ./configure --prefix=/usr/local/keepalived
        #编译安装
        make && make install
        #回到安装目录
        cd ../../
    else
        echo "skip install..."
        stop
    fi
    #配置
    configre
    #启动
    start
}


configre(){
    echo "configure..."
    #创建配置文件夹
    if [ ! -d /etc/keepalived ];then
        mkdir -p /etc/keepalived
    fi
    if [ ! -f /usr/bin/jq ];then
        echo "install jq..."
        #安装jq
        chmod +x ./soft/jq
        cp ./soft/jq /usr/bin
    fi
    #读取json文件中router_id
    router_id=$(jq -r '.router_id' configre.json)
    echo "! Configuration File for keepalived

global_defs {
   router_id $router_id
   script_user root
   enable_script_security 
}" > /etc/keepalived/keepalived.conf
    #获取vrrp_instance数组长度
    vrrp_instance_length=$(jq -r '.vrrp_instance|length' configre.json)
    for((i = 0; i < vrrp_instance_length; i++));
    do
        #获取state
        state=$(jq -r '.vrrp_instance['$i'].state' configre.json)
        #获取interface
        interface=$(jq -r '.vrrp_instance['$i'].interface' configre.json)
        #获取virtual_router_id
        virtual_router_id=$(jq -r '.vrrp_instance['$i'].virtual_router_id' configre.json)
        #获取priority
        priority=$(jq -r '.vrrp_instance['$i'].priority' configre.json)
        #获取virtual_ipaddress
        virtual_ipaddress=$(jq -r '.vrrp_instance['$i'].virtual_ipaddress[]' configre.json)
        echo "vrrp_instance VI_$i {
    state $state
    interface $interface
    virtual_router_id $virtual_router_id
    priority $priority
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass 1111
    }
    virtual_ipaddress {" >> /etc/keepalived/keepalived.conf
        for ipaddr in $virtual_ipaddress
        do
            echo -e "        $ipaddr" >> /etc/keepalived/keepalived.conf
        done
        echo "    }
}" >> /etc/keepalived/keepalived.conf
    done
    
}


start(){
    echo "start..."
    systemctl start keepalived
}

stop(){
    echo "stop..."
    systemctl stop keepalived
}

status(){
    echo "status..."
    systemctl status keepalived
}

help(){
    echo "sh keepalived.sh install"
}

case $1 in
    "install")
        install
    ;;
    "status")
        status
    ;;
    "start")
        start   
    ;;
    "configre")
        configre
    ;;
    "stop")
        stop
    ;;
    "help")
        help
    ;;
esac
