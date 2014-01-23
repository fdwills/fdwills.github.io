---
layout: post
title:  "服务器建站笔记-自动任务"
date:   2014-01-23 20:44:57
categories: server
tags: 服务器 建站
---
因为代码采用github管理，并采用测试驱动开发模式。

这里安装jenkins，旨在对github的pull-request进行Test，对pull-request的merger进行安全判定。

后续用jenkins替代cron执行batch处理。

jenkins的安装配置参考[这里][jenkins-link]

<h2>1. yum安装jenkins</h2>
{% highlight bash%}
# 加入jenkins源
sudo wget -O /etc/yum.repos.d/jenkins.repo http://pkg.jenkins-ci.org/redhat/jenkins.rep
sudo rpm --import http://pkg.jenkins-ci.org/redhat/jenkins-ci.org.key
# 或将以上命令中redhat换成redhat-stable安装稳定版本
 
# 安装jenkins
sudu yum install jenkins
 
# 安装java
sudo yum install java
 
# centos, 从1.5升级为1.6
java -version
sudo yum remove java
sudo yum install jave-1.6.0-openjdk
 
# 查看java版本，应为1.6
java -version
 
# jenkins加入自启动
sudo chkconfig --add jenkins
sudo chkconfig --level 35 jenkins on
# 编辑iptables打开8080端口监听tcp请求
# 重启服务
sudo service iptables restart
sudo service jenkins start
{% endhighlight%}

关于jenkins启动参数的修改，修改启动脚本（/etc/rc*.d/**jenkins）的，或者查看设置启动脚本查看启动脚本中环境变量的名称(/etc/sysconfig/jenkins)。参数如下：
{%highlight text%}
--httpPort=$JENKINS_PORT
--httpListenAddress=$JENKINS_LISTEN_ADDRESS
--httpsPort=$JENKINS_HTTPS_PORT
--httpsListenAddress=$JENKINS_HTTPS_LISTEN_ADDRESS
--ajp13Port=$JENKINS_AJP_PORT
--ajp13ListenAddress=$JENKINS_AJP_LISTEN_ADDRESS
--debug=$JENKINS_DEBUG_LEVEL
--handlerCountStartup=$JENKINS_HANDLER_STARTUP
--handlerCountMax=$JENKINS_HANDLER_MAX
--handlerCountMaxIdle=$JENKINS_HANDLER_IDLE
{%endhighlight%}

默认jenkinshome: /var/lib/jenkins

默认Port：8080

<h2>2. 设置jenkins安全管理选项</h2>
参考[jenkinswiki][jenkins-wiki]
设置管理员用户与匿名用户
安装Jenkins Github插件，便于自动化管理

<h2>3. 浏览器连接http://[host]:8080，出现jenkins画面，ok</h2>
[jenkins-link]: http://pkg.jenkins-ci.org/redhat/
[jenkins-wiki]: https://wiki.jenkins-ci.org/display/JENKINS/Standard+Security+Setup
