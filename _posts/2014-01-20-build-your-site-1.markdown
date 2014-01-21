---
layout: post
title:  "服务器建站笔记-初期设定"
date:   2014-01-20 20:44:57
categories: server
tags: 服务器 建站
---
从日本域名服务商onamae上注册了fdwills的域名，开始准备建站。
用onamae提供的公共服务器服务可以一键建立wordpress服务，绑定DNS之后就能很好的运作。
现在开始尝试在VPS（KVM）模式，即从一无所有的虚拟主机开始建立网络应用。

系统情况：CentOs6.2 64bit， 开启ssh服务

<h2>1. 新建用户root之外的工作用用户</h2>

{% highlight bash%}
#新建用户
root$ adduser wills
root$ passwd wills

#安装Git,vim
root$ yum install git
root$ yum install vim

#安装各种编译所需要的组件
root$ yum install gcc gcc-c++ gdb openssl-devel crul libcurl-devel expat-devel perl-ExtUtils-MakeMaker build-essential tcl8.4 tk8.4 gettext wget
{% endhighlight %}
编辑/etc/sudoer文件，添加下列, 赋予wills sudo权限，方便之后的设置
{% highlight text %}
wills All=(All) All
{% endhighlight %}


<h2>2. 使用工作用户登录，配置用户环境</h2>

{% highlight bash%}
root$ su wills
$cd /home/wills

#从Github下载个人环境配置并安装
$git clone https://github.vom/fdwills/wills
$cd wills;./install.sh
{% endhighlight %}


<h2>3. 更新git版本</h2>

{% highlight bash %}
$git clone https://github.com/git/git
$cd git; make; sudo make install
#安装路径问题
$sudo mv /root/bin/git* /user/bin/
# 检查git版本
$git -v
{% endhighlight %}

