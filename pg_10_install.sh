#!/bin/bash
#written by panf

work_dir=`pwd`
pgsql_data_dir=/pg_data/postgres
unzip_def_dir=/usr/local/src


if [[ $# -ne 3 && $# -ne 1 ]];then
    echo && echo "Usage: bash install.sh [master|slave|single] [clusterIp] [VIP]
  -- [master|slave|single]:当前节点集群角色,single为单点部署;
  -- [clusterIp]:当角色为[master]时，clusterIp为[slave]节点Ip;
                 当角色为[slave]时，clusterIp为[master]节点Ip;
  -- [VIP]:虚拟IP"
    echo && exit
fi

#判断执行步骤是否成功
function check_step(){
if [ $? -ne 0 ];then
    echo_color error "执行步骤失败，请联系管理员..." && echo && exit
fi
}
#终端输出字体控制
function echo_color(){
fatal_color="[1;5;41m" #红底带闪烁，致命错误
error_color="[1;31m"  #红色字体，执行错误信息
warn_color="[1;33m"   #黄色字体，警号信息
succ_color="[1;32m"   #绿色字体，执行正确信息
info_color="[1;30m"   #蓝色自己，提示信息

case $1 in
f*) #fatal
    echo -e -n "\e${fatal_color}${date_time}$2\e[0m"
;;
e*) #error
    echo -e -n "\e${error_color}${date_time}$2\e[0m"
;;
w*) #warning
    echo -e -n "\e${warn_color}${date_time}$2\e[0m"
;;
s*) #success
    echo -e -n "\e${succ_color}${date_time}$2\e[0m"
;;
i*) #info
    echo -e -n "\e${info_color}${date_time}$2\e[0m"
;;
esac
}


## 初始化系统参数
sed -i "s|^#RemoveIPC.*|RemoveIPC=no|g" /etc/systemd/logind.conf
systemctl daemon-reload
systemctl restart systemd-logind

#function initia(){
##创建pgsql用户postgres
id postgres &> /dev/null
if [ $? -ne 0 ];then
    useradd postgres
    echo "postgres" | passwd --stdin postgres
fi

## 创建pgsql数据存储目录
if [ ! -d "$pgsql_data_dir" ];then
    mkdir -p $pgsql_data_dir
fi
chown -R postgres:postgres $pgsql_data_dir

echo_color info "开始安装依赖包，请耐心等待..." && echo
## yum install -y gcc vim-enhanced.x86_64 gcc-java apr apr-devel openssl openssl-devel libgcc.x86_64  perl-Module-Install.noarch  uuid*  readline-devel.x86_64 &> /dev/null
tar -xvf all-in-one.tar.gz
rpm -ivh ./all-in-one/soft/*.rpm --force --nodeps
#}

#function install_pgsql(){
#cd $work_dir
#tar -xvf ./all-in-one/soft/uuid-1.6.2.tar.gz -C $unzip_def_dir
#cd $unzip_def_dir/uuid-1.6.2
#./configure  --with-uuid=ossp && check_step
#make && check_step
#make install && check_step

cd $work_dir
tar -xvf ./all-in-one/soft/postgresql-10.0.tar.gz -C $unzip_def_dir
cd $unzip_def_dir/postgresql-10.0
./configure --prefix=/usr/local/postgres --enable-thread-safety --with-uuid=ossp  && check_step
make  && check_step
make install && check_step
#cd $unzip_def_dir/postgresql-10.0/contrib
#make && check_step
#make install && check_step

ln -s /usr/local/lib/libuuid.so.16 /usr/local/postgres/lib/ &> /dev/null
ln -s /usr/local/postgres/lib/* /usr/local/lib/ &> /dev/null
\cp -p /usr/local/postgres/bin/* /usr/local/bin/ &> /dev/null
ln -s /usr/local/postgres/share/* /usr/local/share &> /dev/null
#\cp -p /usr/local/postgres/share/postgres.bki
## 添加环境变量
su - postgres << EOF
echo 'PGHOME=/usr/local/postgres
export PGHOME
PGDATA=$pgsql_data_dir
export PGDATA
PATH=\$PATH:\$HOME/.local/bin:\$HOME/bin:\$PGHOME/bin
export PATH' >> .bashrc
source .bashrc
EOF
#}

#initia
#install_pgsql
chown -R postgres:postgres /usr/local/postgres
chown -R postgres:postgres /usr/local/share
chmod -R 0700 $pgsql_data_dir

if [[ $1 = "master" ]];then

## 初始化数据库
su - postgres << EOF
echo 'initdb -D /pg_data/postgres
pg_ctl -D /pg_data/postgres -l logfile start' > ./init.sh && bash init.sh
EOF
check_step


## 修改$pgsql_data_dir/pg_hba.conf配置文件
echo "host    replication     repl            $2/24         trust" >> $pgsql_data_dir/pg_hba.conf
echo "host    all     all            0.0.0.0/0         md5" >> $pgsql_data_dir/pg_hba.conf

## 修改$pgsql_data_dir/postgresql.conf配置文件
sed -i "s|^#listen_addresses.*|listen_addresses = '*'|g" $pgsql_data_dir/postgresql.conf
sed -i "s|^#wal_level.*|wal_level = hot_standby|g" $pgsql_data_dir/postgresql.conf
sed -i "s|^#max_wal_senders.*|max_wal_senders = 2|g" $pgsql_data_dir/postgresql.conf
sed -i "s|^#wal_keep_segments.*|wal_keep_segments = 10240|g" $pgsql_data_dir/postgresql.conf
sed -i "s|^max_connections.*|max_connections = 1000|g" $pgsql_data_dir/postgresql.conf
sed -i "s|^#port = 5432|port = 5432|g" $pgsql_data_dir/postgresql.conf
sed -i "s|^log_timezone.*|log_timezone = 'Asia/Shanghai'|g" $pgsql_data_dir/postgresql.conf
sed -i "s|^timezone.*|timezone = 'Asia/Shanghai'|g" $pgsql_data_dir/postgresql.conf

## 添加检测主库状态脚本，删除定时任务
echo "#!/bin/bash

count=\`netstat -an|grep ":5432" | grep LISTEN| wc -l\`

if [ \$count == 0 ]; then
    systemctl stop keepalived
fi
" > /usr/local/bin/check_postgres.sh
chmod +x /usr/local/bin/check_postgres.sh

## 重启数据库
su - postgres << EOF
echo 'pg_ctl -D /pg_data/postgres -l logfile restart' > ./init.sh && bash init.sh
EOF
check_step

## 创建从库角色并授权
sleep 5
psql -h127.0.0.1 -U postgres << EOF
create role repl login replication encrypted password 'postgres';
EOF
check_step
psql -h127.0.0.1 -U postgres << EOF
ALTER USER postgres WITH PASSWORD 'postgres';
EOF
check_step
elif [[ $1 = "slave" ]];then

## 从库备份主库基础数据
pg_basebackup -h $2 -p 5432 -U repl -F p -P -D $pgsql_data_dir -R -w &> /dev/null
check_step
## 修改$pgsql_data_dir/recovery.conf配置文件
echo "recovery_target_timeline = 'latest'" >> $pgsql_data_dir/recovery.conf
echo "trigger_file = 'change_role'" >> $pgsql_data_dir/recovery.conf
## 修改$pgsql_data_dir/postgresql.conf配置文件
sed -i "s|^wal_level.*|#&|g" $pgsql_data_dir/postgresql.conf
sed -i "s|^max_wal_senders.*|#&|g" $pgsql_data_dir/postgresql.conf
sed -i "s|^wal_keep_segments.*|#&|g" $pgsql_data_dir/postgresql.conf
sed -i "s|^#hot_standby.*|hot_standby = on|g" $pgsql_data_dir/postgresql.conf
sed -i "s|^#max_standby_streaming_delay.*|max_standby_streaming_delay = 30s|g" $pgsql_data_dir/postgresql.conf
sed -i "s|^#wal_receiver_status_interval.*|wal_receiver_status_interval = 10s|g" $pgsql_data_dir/postgresql.conf
sed -i "s|^#hot_standby_feedback.*|hot_standby_feedback = on|g" $pgsql_data_dir/postgresql.conf

if [ `ll $pgsql_data_dir | grep postmaster.opts | wc -l` -eq 0 ];then
    echo -E '/usr/local/bin/postgres "-D" "'$pgsql_data_dir'"' > $pgsql_data_dir/postmaster.opts
fi
chown -R postgres:postgres $pgsql_data_dir &> /dev/null
chmod -R 0700 $pgsql_data_dir &> /dev/null

## 添加定时任务，检测主库状态，异常自动切换
#cp ./change_postgres_role.sh /usr/local/bin
echo "#!/bin/bash
source /etc/profile
VIP=\`ip a | grep $3 | wc -l\`

if [ \$VIP -ne 0 ];then
    touch /pg_data/postgres/change_role
fi
" > /usr/local/bin/change_postgres_role.sh

chmod +x /usr/local/bin/change_postgres_role.sh
echo "*/1 * * * * /bin/sh /usr/local/bin/change_postgres_role.sh" >> /var/spool/cron/root

## 重启数据库
 su - postgres -c "pg_ctl -D /pg_data/postgres -l logfile restart" && check_step

elif [ $1 == "single" ]; then
## 初始化数据库
su - postgres -c "initdb -D /pg_data/postgres && pg_ctl -D /pg_data/postgres -l logfile restart" && check_step

## 修改$pgsql_data_dir/postgresql.conf配置文件
sed -i "s|^#listen_addresses.*|listen_addresses = '*'|g" $pgsql_data_dir/postgresql.conf
sed -i "s|^#wal_level.*|wal_level = hot_standby|g" $pgsql_data_dir/postgresql.conf
sed -i "s|^#max_wal_senders.*|max_wal_senders = 2|g" $pgsql_data_dir/postgresql.conf
sed -i "s|^#wal_keep_segments.*|wal_keep_segments = 10240|g" $pgsql_data_dir/postgresql.conf
sed -i "s|^max_connections.*|max_connections = 1000|g" $pgsql_data_dir/postgresql.conf
sed -i "s|^#port = 5432|port = 5432|g" $pgsql_data_dir/postgresql.conf
sed -i "s|^log_timezone.*|log_timezone = 'Asia/Shanghai'|g" $pgsql_data_dir/postgresql.conf
sed -i "s|^timezone.*|timezone = 'Asia/Shanghai'|g" $pgsql_data_dir/postgresql.conf
echo "host    all     all            0.0.0.0/0         md5" >> $pgsql_data_dir/pg_hba.conf
## 重启数据库
psql -h127.0.0.1 -U postgres << EOF
ALTER USER postgres WITH PASSWORD 'postgres';
EOF
su - postgres -c "pg_ctl -D /pg_data/postgres -l logfile restart" && check_step

else
echo -e "参数输入有误(master/slave),请检查..." && exit
fi

echo "#  su - postgres -c "pg_ctl -D /pg_data/postgres -l logfile restart"" >> /etc/rc.local