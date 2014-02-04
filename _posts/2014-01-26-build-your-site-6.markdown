---
layout: post
title:  "服务器建站笔记-博客应用"
date:   2014-01-26 10:44:57
categories: diary
tags: 服务器 建站
---
本博客的自动Deploy任务建立。这个博客采用的[jekyll][jekyll]建立的，在github pages上能够发布的同时在自己的VPS上能够自动发布。

Capistrano可以用来自动deploy，扥在Jenkins上运用有着诸多问题。如果在Capistano中不存储明文密码，就要解决ssh-key的问题。这个问题困惑了很久。

但在这次实验中中，deploy的目标服务器与Jenkins服务器是同一个服务器，简单通过rsync就能解决deploy问题，但是这种设置需要一些很危险的设置。在理想情况下，还是以下的流程比较好：

### 方案1
1. 代码中配置capistrno的production的deploy选项，采用github + ssh进行deploy
2. git push到github
3. github触动hook访问jenkins
4. jenkins获取pull代码，检查deploy条件。比如是否master有修改，是否test通过等等。
5. jenkins运行capistano的deploy任务
6. capistano运行，ssh连接目标服务器从github上获取代码进行deploy

这样的deploy可以自动进行deploy的版本控制，维持deploy记录，同时保存历次deploy的成果等等好处。
但实际上这次的流程为(先安全的运行起来，有时间再去折腾方案1的可行性)：

### 方案2
1. git push到github
2. github触动hook访问jenkins
3. jenkins获取pull代码，检查deploy条件。比如是否master有修改，是否test通过等等。
4. 使用rsync与deploy目标文件夹进行本地同步

###配置jenkins
参考[这里][jenkins-setting]设置一个deploy的jenkins任务，deploy的条件是当master有改变的时候执行（这里暂无test）。

deploy时的任务

{%highlight bash%}
#更新bundle
$HOME/.rbenv/shims/bundle install --path=vendor/bundle

# 编译jekyll到静态页面
$HOME/.rbenv/bin/rbenv exec jekyll build

#将jenkins的工作目录同步到网站目录
sudo rsync -avr --delete --stats ./ /home/wills/app/fdwills.github.io/
{%endhighlight%}
同时需要配置的是jenkins的权限。jenkins发布时采用的是jenkins用户，需要对/home/wills/app/fdwills.github.io/有控制权限。于是在/etc/sudoers里面对jenkins用户打开权限

{%highlight bash%}
# 防止错误sudo: sorry, you must have a tty to run sudo的发生
# 注释掉以下
# Defaults    requiretty

Cmnd_Alias BACKUP_TASK = /usr/bin/rsync, /usr/bin/ssh, /usr/bin/du

jenkins ALL=(ALL) NOPASSWD: BACKUP_TASK
{%endhighlight%}

ok, 到这里为止就可以了，然后需要做的就是完成jenkins与github之间的hook连接。

Test一下，本地做修改后，反应到github之后，就通过jenkins自动编译发布到了远程服务器上。

[jenkins-setting]: /server/2014/01/24/build-your-site-5.html
[jekyll]: http://jekyllrb.com/
