---
layout: post
title:  "HAProxy在生产环境中的使用"
date:   2015-05-10 12:44:57
categories: diary
tags: draft
---

## HAProxy

HAProxy作为一款企业级的负载均衡软件，支持HTTP，TCP的负载均衡，且配置和使用方便。这里将负载均衡以及HAProxy的配置。

### 负载均衡的几种方式和比较

说到负载均衡，最简单的负载均衡是采用DNS的解析。大多数域名提供商都支持单个域名解析到多条记录的功能。将提供服务的多个主机记录作为DNS解析的记录，可以达到最简单的负载均衡功能。单纯使用此功能有如下缺陷：

1. 动态增加和削减主机的操作变得复杂，需要直接操作域名解析记录。
2. 大部分DNS提供商以一种轮询的方式向用户提供解析记录，负载的模式单一。
3. 域名的解析有生效时间，且客户端有解析的缓存，使得生效时刻不可控制。
4. 域名有可能被运营商封禁，导致整体服务不可用。

于是想到使用开源免费的负载均衡软件来解决这类事情。

市面上开源免费功能强大的负载均衡软件有：LVS，HAProxy，Nginx等等。关于三者的比较在各种博客上都有记载。

Nginx的proxypass模块提供简单的负载功能，且配置简单，在主机数量不多的时候，可以使用nginx的负载功能，但是Nginx作为web前端的反向代理，只提供Http的负载均衡功能。

LVS的功能强大，支持4层和7层的负载功能，性能出色，但是配置略复杂。而HAProxy则兼具两者的优势，在不输性能的同时配置又简单易用。

### HAProxy的安装和基本配置

### 设置自启动和haproxy.conf

* 在官网上下载最新的安装包（现在最新的稳定版本是1.5）

```bash
tar xzvf haproxy-1.5.11.tar.gz
# 如果使用https，需要添加编译选项USE\_OPENSSL，选在适合自己的内核版本进行编译
make TARGET=linux2628 PREFIX=/usr/local/haproxy USE_OPENSSL=1
make install PREFIX=/usr/local/haproxy
ln -s /usr/local/haproxy/sbin/haproxy /usr/local/sbin/haproxy
```

* 设置启动配置

```bash
# 从这里下载参考的启动配置
wget https://ma.ttias.be/downloads/haproxy/haproxy.init -O /etc/init.d/haproxy

# 修改/etc/init.d/haproxy的参数

# 设置启动项
chkconfig haproxy on
```

* 设置log（centos）

```bash
# 在/etc/rsyslog.conf,打开udplog选线，打开514端口
# Provides UDP syslog reception
$ModLoad imudp
$UDPServerRun 514

#添加log的输出到自己的输出
local0.*                                                /data/log/haproxy/haproxy.log
```

* 基本配置

HAProxy的配置包含global, default, listen, frontend, backend几部分，其中global设置的时haproxy启动相关的全局配置，例：

```
global
        log 127.0.0.1   local0
        log 127.0.0.1   local1 notice
        # ssl证书位置
        # ca-base

        # 证书相对于ca-base的位置文件
        # ca-file
        # crl-file

        # crt 的位置
        # crt-base

        # 最大连接数，由于HAProxy会建立两个连接。所以实际的TCP连接数会是两倍。
        maxconn 20000
        chroot /usr/local/haproxy/data

        # 启动使用的用户id和组id
        uid 99
        gid 99

        # 以守护进程的方式运行
        daemon

        # 开启的进程数，一般不大于机器的物理核数
        nbproc 2
        pidfile /usr/local/haproxy/haproxy.pid
```

default部分设置的是每个虚拟服务器的默认部分，如果配置不被覆盖的话，将使用于以下设置的listen，frontend和backend。例：

```
defaults
        log     global
        # 默认模式
        mode    http
        option  httplog
        option  dontlognull
        # 是否失败重试
        option redispatch
        # 重试次数
        retries 3
        # 最大连接数
        maxconn 20000
        # 超时相关
        timeout connect     5000
        timeout client     50000
        timeout server     50000
        # 管理页面账号密码配置
        stats   uri     /haproxy-admin
        stats auth  admin:admin
```

#### 实践HTTP负载的配置

HAProxy最常见的应用是用来做http服务的负载均衡。这里采用linten的配置。listen是结合了frontend和backend两者的功能。

```
listen http_proxy :80
        # 自定义用于健康监测的URL
        option  httpchk GET /
        option  httpclose

        # 将请求的信心添加进Forwardfor里面，如果需要获取客户端真实IP，此项很重要
        option forwardfor

        # 采用轮询的负载均衡方式
        balance roundrobin

        # 采用acl的方法禁止某些IP的访问
        acl bad_ip src 218.18.248.219
        http-request deny if bad_ip

        # 用于处理的server配置
        server api1-1 127.0.0.1:8080 cookie 11 check inter 2000 rise 2 fall 5
```

#### 实践TCP负载的配置

```
listen tcp_proxy :5400
        option tcplog
        mode tcp
        balance roundrobin

        server tcp-1 127.0.0.1:5500 check inter 2000 rise 2 fall 5
```

#### 实践数据库负载的配置

鉴于haproxy能进行L4的负载均衡，而mysql，postgres，redis，mongodb等存储产品室依赖于tcp连接的，所以可以通过haproxy对这类集群进行负载均衡。

这里以postgres为例，postgres提供了stream repli的功能，能够将主库的数据同步搭配多个从库当中去。其他的存储产品都有类似的功能。首先配置postgres产生一个从库的集群，然后通过haproxy做负载均衡。

```
listen postgres_tcpm_master :5432
        option tcplog
        timeout connect     50000
        mode tcp
        balance roundrobin
        # 这里是postgres用于用户验证的配置
        option pgsql-check user username
        server slave1 127.0.0.1:5433 check inter 2000 rise 2 fall 5
        server slave2 127.0.0.1:5434 check inter 2000 rise 2 fall 5
```

TODO: pgbouncer

#### 参考

* [haproxy配置文档](http://www.haproxy.org/download/1.4/doc/configuration.txt)

