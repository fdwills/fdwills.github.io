---
layout: post
title:  "服务器建站笔记-组件安装"
date:   2014-01-21 20:44:57
categories: diary
tags: 服务器 建站
---
想建立的网站架构是apache+mysql+ruby rails架构
可能的话建立自动任务（暂定jenkins）
建立自动deploy,migration体系（暂定capitrano, 没搞过，可能需要点时间）

<h2>1. apache安装</h2>
{% highlight bash%}
# 安装httpd服务
yum install httpd
chkconfig --add httpd
chkconfig -level 35 httpd on
{% endhighlight %}

修改/etc/httpd/conf/httpd.conf
include “自己的ConfPath”
写入以下内容至个人的httpd.conf

{%highlight xml%}
<VirtualHost *:80>
ServerAdmin email
DocumentRoot /var/www/html/
# fdwills.com的绑定需在域名服务商处绑定，若没有绑定，则可以通过IP连接
ServerName fdwills.com
</VirtualHost>
{%endhighlight%}

<h2>2. 修改iptables配置，打开相应端口（例）</h2>

{%highlight text%}
*filter
:INPUT ACCEPT [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
-A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
-A INPUT -p icmp -j ACCEPT
# local request
-A INPUT -i lo -j ACCEPT
#ssh
-A INPUT -m state --state NEW -m tcp -p tcp --dport 22 -j ACCEPT
# http service
-A INPUT -m state --state NEW -m tcp -p tcp --dport 80 -j ACCEPT
-A INPUT -j REJECT --reject-with icmp-host-prohibited
-A FORWARD -j REJECT --reject-with icmp-host-prohibited
COMMIT
{%endhighlight%}
关于IPtables的设置可以参考[此处][iptables]http://qiita.com/shimohiko/items/ec672655edb84578a82e

<h2>3. 通过IP链接服务器，可以看到apache的欢迎页面，Ok</h2>

[iptables]: http://qiita.com/shimohiko/items/ec672655edb84578a82e
