# Oracle 19c之RPM安装

  本文链接：https://blog.csdn.net/bisal/article/details/100909708



对我来说，12c都是比较陌生的，毕竟平时没什么机会用到，但是没条件，就要创造条件，要了解19c，第一步，就是需要具备一个测试环境。



说到19c的安装，相比11g，除了支持图形、命令行、静默安装外，最大的改进，就是支持RPM安装。

Linux上安装Oracle 19c，需要OL7、RHEL7、SLES12及以上的更高版本。Oracle Enterprise Linux6和RedHat Linux6并没有出现在官方给的列表中，

![640?wx_fmt=png](https://ss.csdn.net/p?https://mmbiz.qpic.cn/mmbiz_png/a1q64ic86PancQibvosWUaBvqGZTwWDE519nFIMd0J6pAWhUf8tsXmlPSbxnxZPlAKJFjiabGgl2omCuwGEC5QgFw/640?wx_fmt=png)



19c的RPM包下载链接，

https://www.oracle.com/database/technologies/oracle19c-linux-downloads.html



可以看到，19c开始支持企业版本的RPM，容量是2.5GB，![640?wx_fmt=png](https://ss.csdn.net/p?https://mmbiz.qpic.cn/mmbiz_png/a1q64ic86PancQibvosWUaBvqGZTwWDE51L3u1PDg8BlF6SVQhrTfOx8uoNqsCuqEPkic90Dvs027EfIicFElusN5w/640?wx_fmt=png)



使用手工方式，通过RPM安装19c数据库，只需要两步操作，

步骤1：安装oracle-database-preinstall-19c-1.0-1.el7.x86_64.rpm

步骤2：安装oracle-database-ee-19c-1.0-1.x86_64.rpm



**步骤1**：安装oracle-database-preinstall-19c-1.0-1.el7.x86_64.rpm



如果OEL平台，只需要执行，

```javascript
yum -y install oracle-database-preinstall-19c
```

如果不是OEL平台，首先要下载对应平台的RPM，我用的是RedHat 7.4，下载链接地址，

https://yum.oracle.com/repo/OracleLinux/OL7/latest/x86_64/index.html

![640?wx_fmt=png](https://ss.csdn.net/p?https://mmbiz.qpic.cn/mmbiz_png/a1q64ic86PancQibvosWUaBvqGZTwWDE51YtkzhibGAbw9LZpQCAVjqszJAwcib2jnfvweNweymKqfEAhbKEAsict6A/640?wx_fmt=png)



搜索preinstall-19c，找到，

![640?wx_fmt=png](https://ss.csdn.net/p?https://mmbiz.qpic.cn/mmbiz_png/a1q64ic86PancQibvosWUaBvqGZTwWDE51XyjR9dVIRECFhB6Z2B869raCwO1bFXpickcMfXia4NA0C0ULdFaaeuEw/640?wx_fmt=png)



第一次执行，未必就可以成功，在我的测试环境，从错误的提示看，少了一些依赖库，

```javascript
[root@localhost software]# rpm -ivh oracle-database-preinstall-19c-1.0-1.el7.x86_64.rpm
warning: oracle-database-preinstall-19c-1.0-1.el7.x86_64.rpm: Header V3 RSA/SHA256 Signature, key ID ec551f03: NOKEY
error: Failed dependencies:
    compat-libcap1 is needed by oracle-database-preinstall-19c-1.0-1.el7.x86_64
    compat-libstdc++-33 is needed by oracle-database-preinstall-19c-1.0-1.el7.x86_64
    glibc-devel is needed by oracle-database-preinstall-19c-1.0-1.el7.x86_64
...
```



碰见这种情况，一个是可以从操作系统安装文件的Package中找到些库，另一个就是从网上检索安装库，在我的测试中，大部分少的库，都可以从Package中找到，但是compat-libstdc++-33这个并不在。



根据MOS(2254198.1)的提示，这个包是Oracle Text需要的，如果不用Oracle Text，可以忽略这个包，在RedHat 7的安装包中已经删除了。



如果不能容忍任何的错误，非得装上，可以到这个链接，下载下来安装，

http://www.rpmfind.net/linux/rpm2html/search.php?query=compat-libstdc%2B%2B-33(x86-64)

![640?wx_fmt=png](https://ss.csdn.net/p?https://mmbiz.qpic.cn/mmbiz_png/a1q64ic86PancQibvosWUaBvqGZTwWDE51fum1vyorsUWQF1LVKmUml43ibcVbRGiaSibiao1pKicA6jreYDlf4wgenDA/640?wx_fmt=png)



再次安装，

```javascript
[root@localhost software]# rpm -ivh oracle-database-preinstall-19c-1.0-1.el7.x86_64.rpm

warning: oracle-database-preinstall-19c-1.0-1.el7.x86_64.rpm: Header V3 RSA/SHA256 Signature, key ID ec551f03: NOKEY

Preparing...                          ################################# [100%]

Updating / installing...

   1:oracle-database-preinstall-19c-1.################################# [100%]
```



**步骤2**：安装oracle-database-ee-19c-1.0-1.x86_64.rpm



此时，只需要执行oracle-database-ee-19c-1.0-1.x86_64.rpm的安装即可，但是我的第一次执行中，报了错，提示清楚，总计要6.9GB的空间，我还需要1.3GB的空间，所以安装前，准备出足够空间，是个前提，

```javascript
[root@localhost software]# yum install -y oracle-database-ee-19c-1.0-1.x86_64.rpm

Loaded plugins: langpacks, product-id, search-disabled-repos, subscription-

              : manager

This system is not registered with an entitlement server. You can use subscription-manager to register.

Examining oracle-database-ee-19c-1.0-1.x86_64.rpm: oracle-database-ee-19c-1.0-1.x86_64

Marking oracle-database-ee-19c-1.0-1.x86_64.rpm to be installed

Resolving Dependencies

--> Running transaction check

---> Package oracle-database-ee-19c.x86_64 0:1.0-1 will be installed

--> Finished Dependency Resolution

Dependencies Resolved

================================================================================

 Package                Arch   Version

                                     Repository                            Size

================================================================================

Installing:

 oracle-database-ee-19c x86_64 1.0-1 /oracle-database-ee-19c-1.0-1.x86_64 6.9 G

Transaction Summary

================================================================================

Install  1 Package

Total size: 6.9 G

Installed size: 6.9 G
Downloading packages:
Running transaction check
Running transaction test
Transaction check error:
  installing package oracle-database-ee-19c-1.0-1.x86_64 needs 1322MB on the / filesystem


Error Summary

Disk Requirements:

  At least 1322MB more space needed on the / filesystem.
```



再次安装，只需要几分钟，就可以完成Oracle 19c软件的安装，

```javascript
[root@localhost software]# yum install oracle-database-ee-19c-1.0-1.x86_64.rpm


Loaded plugins: langpacks, product-id, search-disabled-repos, subscription-

              : manager

This system is not registered with an entitlement server. You can use subscription-manager to register.

Examining oracle-database-ee-19c-1.0-1.x86_64.rpm: oracle-database-ee-19c-1.0-1.x86_64

Marking oracle-database-ee-19c-1.0-1.x86_64.rpm to be installed

Resolving Dependencies

--> Running transaction check

---> Package oracle-database-ee-19c.x86_64 0:1.0-1 will be installed

--> Finished Dependency Resolution
Dependencies Resolved


================================================================================

 Package                Arch   Version

                                     Repository                            Size

================================================================================

Installing:

 oracle-database-ee-19c x86_64 1.0-1 /oracle-database-ee-19c-1.0-1.x86_64 6.9 G

Transaction Summary

================================================================================

Install  1 Package

Total size: 6.9 G

Installed size: 6.9 G

Is this ok [y/d/N]: y

Downloading packages:

Running transaction check

Running transaction test

Transaction test succeeded

Running transaction

Warning: RPMDB altered outside of yum.

  Installing : oracle-database-ee-19c-1.0-1.x86_64                          1/1

[INFO] Executing post installation scripts...

[INFO] Oracle home installed successfully and ready to be configured.

To configure a sample Oracle Database you can execute the following service configuration script as root: /etc/init.d/oracledb_ORCLCDB-19c configure

  Verifying  : oracle-database-ee-19c-1.0-1.x86_64                          1/1

Installed:

  oracle-database-ee-19c.x86_64 0:1.0-1                                         

Complete!
```



完成了软件安装，下一步就是创建数据库，指令是

/etc/init.d/oracledb_ORCLCDB-19c configure



但是首次执行，还是出错了，要求使用root执行，

```javascript
[oracle@localhost init.d]$ /etc/init.d/oracledb_ORCLCDB-19c configure

You must be root user to run the configurations script. Login as root user and try again.
```



再执行，这次的错误，提示数据文件空间满了，从提示可以看出，RPM安装默认的数据文件路径是/opt/oracle/oradata，

```javascript
[root@localhost ~]# /etc/init.d/oracledb_ORCLCDB-19c configure

Configuring Oracle Database ORCLCDB.

[FATAL] [DBT-06604] The location specified for 'Data Files Location' has insufficient free space.

   CAUSE: Only (4,174MB) free space is available on the location (/opt/oracle/oradata/ORCLCDB/).

   ACTION: Choose a 'Data Files Location' that has enough space (minimum of (4,244MB)) or free up space on the specified location.

Database configuration failed.   
```



这个执行过程，就是11g很像了，需要十几分钟，才可以执行完成，

```javascript
[root@localhost ~]# /etc/init.d/oracledb_ORCLCDB-19c configure

Configuring Oracle Database ORCLCDB.

Prepare for db operation

8% complete

Copying database files

31% complete

Creating and starting Oracle instance

32% complete

36% complete

 



40% complete

43% complete

46% complete

Completing Database Creation

51% complet

54% complete

Creating Pluggable Databases

58% complete

77% complete

Executing Post Configuration Actions

100% complete

Database creation complete. For details check the logfiles at:

 /opt/oracle/cfgtoollogs/dbca/ORCLCDB.

Database Information:

Global Database Name:ORCLCDB

System Identifier(SID):ORCLCDB

Look at the log file "/opt/oracle/cfgtoollogs/dbca/ORCLCDB/ORCLCDB.log" for further details.

Database configuration completed successfully. The passwords were auto generated, you must change them by connecting to the database using 'sqlplus / as sysdba' as the oracle user.
```



从路径中，可以看到，相关的控制文件、日志文件、数据文件，

```javascript
[oracle@localhost ORCLCDB]$ pwd

/opt/oracle/oradata/ORCLCDB

[oracle@localhost ORCLCDB]$ ls

control01.ctl  ORCLPDB1  redo01.log  redo03.log    system01.dbf  undotbs01.dbf

control02.ctl  pdbseed   redo02.log  sysaux01.dbf  temp01.dbf    users01.dbf
```



和11g相同，oracle用户的profile，需要做些配置，增加环境变量，

```javascript
export ORACLE_BASE=/opt/oracle

export ORACLE_HOME=/opt/oracle/product/19c/dbhome_1

export ORACLE_SID=ORCLCDB

export PATH=$ORACLE_HOME/bin:$PATH:$HOME/.local/bin:$HOME/bin
```



正常访问，

```javascript
[oracle@localhost ~]$ sqlplus / as sysdba

SQL*Plus: Release 19.0.0.0.0 - Production on Sun Sep 8 08:55:56 2019

Version 19.3.0.0.0

Copyright (c) 1982, 2019, Oracle.  All rights reserved.


Connected to:

Oracle Database 19c Enterprise Edition Release 19.0.0.0.0 - Production

Version 19.3.0.0.0
```

从安装步骤看，RPM确实简单，除了需要关注安装路径和数据库文件的磁盘空间，以及保证依赖包具备，需要做的，就是一个RPM指令，降低了以往Linux下的安装复杂性，和19c倡导Autonomous自治不谋而和，真正实现了一键安装。

参考：

https://www.eygle.com/archives/2018/10/oracle_18c_orclcdb_install.html