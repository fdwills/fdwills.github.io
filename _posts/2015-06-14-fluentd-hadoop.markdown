---
layout: post
title:  "Log, Fluentd和hadoop"
date:   2015-06-14 12:44:57
categories: diary
tags: draft
---

## 前言

log分布在各个服务器上，分析起来比较难。于是想到将log发送存储起来，以便与后期搜索与处理。

通用的方案elasticsearch用的比较多。

这里使用fluentd+hadoop的解决方案，来完成log的搜集和存储。好处在于以json格式化的形式存储数据，并且在分布式文件系统中存储，后面接入hive，pig或者scalar等等的处理都比较方便。

### hadoop安装

这里参考官方文档的[安装手册](http://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-common/SingleCluster.html)，来安装一个pseudo-distributed模式。

### fluentd的安装

fluentd实际上就是一个log的搜集并json化的一个系统。首先fluentd可以搜集日志，搜集的来源可以使从http接口，socket，或者是从本地文件都可以。日志搜集的时候就可以按照正则匹配的形式格式化成json字符串。

其次fluentd可以发送日志，如果是要存储，可以发送到mongodb或者hdfs等等系统当中，甚至可以发json数据不进行存储，交给其他fluentd节点处理。一个fluentd节点完成的工作实际上就是接受-格式化-发送三个任务，以怎样的拓扑结构来完成这个网络，就需要自己设计了。

fluentd的安装方法，[这里](http://docs.fluentd.org/articles/quickstart)有详细的说明.

安装完成进入配置文件件之后，可以看到fluentd的配置文件中包含两个主要的节：source和match。

```
<source>
  type forward
</source>

<source>
  type http
  port 8888
</source>

<match hdfs.*.*>
  type webhdfs
  host 127.0.0.1
  port 50070
  path /user/hdfsuser/%Y%m%d_%H/accesslog.log.${hostname}
  flush_interval 10s
</match>
```

source和match可以有很多。source的意思是从哪些渠道接收数据，match的意思匹配并处理打上某些标记的数据。

以上面的例子来看，本机通过两中渠道接收数据forward和http，其中forward是从其他fluentd节点转发过来的数据（端口24224），而http则接受的http的请求。

用http举例来走完一个完整的流程：

1. 首先本地curl -X post -d 'data={"json": "test"}' 127.0.0.1:8888/hdfs.test。这是一个普通http的请求
2. 本地fluentd的daemon收到请求之后，判断能用type为http的模式接受数据，并且将hdfs.test解析为tag
3. 本地根据match规则，发现match hdfs.*.*的规则能够match到hdfs.test这个tag，于是将数据交给里面配置的webhdfs模块去处理。该模块是讲web数据存储到hdfs中的模块（当然首先的配置好hdfs的环境）。于是根据配置的namenode和存储位置，将data={"json": "test"}存储到hdfs当中

fluentd除了forward，http之外，还有tail同道可以用来处理本地log文件等等。

而match规则里面可用的模块处理webhdfs，还有http，mongodb等等对应的模块。

### 配置实战

目的：

```
这里的应用是将haproxy输出的http的log文件，以格式化好饿格式存储到hdfs当中去。
```

hdfs与haproxy分别部署在不同的物理机器上，当中由内网沟通。将fluentd设计成一个cs的结构，在haproxy机器上做client用于搜集和发送，在hdfs上做server用于接受和存储。

一个典型的haproxy的log如下：

```
Jun 11 18:31:35 localhost haproxy[27860]: 60.180.171.174:21572 [11/Jun/2015:18:31:35.408] https_frontend~ web_server/http_backend 34/0/1/114/149 200 3497 - - --VN 11/6/0/0/0 0/0 "GET /index.html HTTP/1.1"
```

首先配置haproxy上的发送服务，

```
<source>
  type tail
  path /data/log/haproxy/haproxy.log # log文件位置
  pos_file /var/log/td-agent/haproxy.log.pos # position记录文件
  format /^(?<ha_month>\w+) (?<ha_day>\d+) (?<ha_time>[\d:]+) (?<host>\w+) (?<ps>\w+)\[(?<pid>\d+)\]: (?<c_ip>[\w\.]+):(?<c_port>\d+) \[(?<time>.+)\] (?<f_end>\S+) (?<b_server>\S+) (?<tq>\S+) (?<status_code>\d+) (?<bytes>\d+) (?<req_cookie>\S+) (?<res_cookie>\S+) (?<t_state>[\w-]+) (?<conn>\S+) (?<srv_queue>[\d-]+)\/(?<backend_queue>[\d-]+) "(?<method>\S+) (?<request>\S+) (?<req_version>\S+)"/ # log的正则匹配
  tag hdfs.haproxy.http # 指定tag
  time_format %d/%B/%Y:%H:%M:%S
</source>

<match hdfs.*.*>
  type forward # forward模式，转发给其他服务器处理
  send_timeout 60s
  recover_wait 10s
  heartbeat_interval 1s
  phi_threshold 30
  hard_timeout 60s
  <server>
    name hdfs
    host 192.169.1.2
    port 24224
    weight 1
  </server>
</match>
```

按面所写fluentd搜集本地的log日志，并格式化好json后通过foward模式转发个server中指定的hdfs服务器。

所以在hdfs服务器上需要有个充当server角色的fluentd服务。

```
<source>
  type forward
</source>

<match hdfs.*.*>
  type webhdfs
  host 127.0.0.1
  port 50070
  path /user/hdfsuser/haproxy/%Y%m%d_%H/accesslog.log.${hostname}
  flush_interval 10s
</match>
```

在hdfs上通过forward模式接受数据，此时数据已经有tag，这个tag是由tail的时候打上，并且由forward模式转发过来的。这是后tag被match hdfs.*.*的规则匹配到，于是交给了webhdfs存储到本地的hdf文件系统中。

### 查看结果

在hdf上使用hdfs tail命令，就能看到在/user/hdfsuser/haproxy/%Y%m%d_%H/accesslog.log.${hostname}路径，存储的格式：

```
{"ha_month":"Jun","ha_day":"15","ha_time":"13:31:06","host":"localhost","ps":"haproxy","pid":"27861","c_ip":"112.17.235.81","c_port":"7917","f_end":"https_frontend~","b_server":"web_server/httpserver","tq":"3577/0/1/9/3587","status_code":"200","bytes":"263","req_cookie":"-","res_cookie":"-","t_state":"--NI","conn":"5/3/0/0/0","srv_queue":"0","backend_queue":"0","method":"GET","request":"/index.html","req_version":"HTTP/1.1"}
```

使用一个简单的pig脚本就能够读取和处理其中的数据：

```
first_table = load '/user/deploy/haproxy/20150615_13/accesslog.log.peiwo-hub4'
    using JsonLoader('ha_month:chararray,ha_day:chararray,ha_time:chararray,host:chararray,ps:chararray,pid:chararray,c_ip:chararray,c_port:chararray,f_end:chararray,b_server:chararray,tq:chararray,status_code:chararray,bytes:chararray,req_cookie:chararray,res_cookie:chararray,t_state:chararray,conn:chararray,srv_queue:chararray,backend_queue:chararray,method:chararray,request:chararray,req_version:chararray');
STORE first_table
    INTO 'first_table.json'
    USING JsonStorage();
```

#### Troubleshooting

一、 no nodes are available

这是由于心跳以及传输的过程过程中，tcp和udp的都要允许。在官网上也有解释：

```
Please make sure that you can communicate with port 24224 using not only TCP, but also UDP. These commands will be useful for checking the network configuration.

$ telnet host 24224
$ nmap -p 24224 -sU host
```

很多人都是在内网搭建这样的网络，所以是对于内网，记得打开tcp和udp协议的访问许可。

### 其他

在fluentd中，用于接受和发送数据的都是一些插件，http，forward，webhdfs，apache都是fluentd内置的插件。另外还有个人开发的类似处理nginx的插件等等，都可以拿来用。在应用程序中，fluentd提供了各种语言的库文件，用于向fluentd发送log，这些大多数都是基于http模块的。于是，下一步就是，如何处理这些log了。

## 参考文档

* [out_webhdfs参考](http://docs.fluentd.org/articles/out_webhdfs)
* [hadoop的安装](http://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-common/SingleCluster.html)
* [fluentd文档](http://docs.fluentd.org/articles/quickstart)
