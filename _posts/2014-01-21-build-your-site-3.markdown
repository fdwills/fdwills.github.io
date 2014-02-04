---
layout: post
title:  "服务器建站笔记-应用安装"
date:   2014-01-21 20:44:57
categories: diary
tags: 服务器 建站
---
mysql+ruby+rails环境搭建
apache的各种一般模块中MPM采用基本配置prefork模式，prefork各参数对于访问量低的应用不配置也可。
rails routes的原因，apache对于rewrite模块的需求不是很大，rewrite规则不写也可。


<h2>1. mysql安装</h2>
{% highlight bash%}
# 安装mysql，mysql-devel。后者是在安装sqlite的依赖
sudo yum install mysql mysql-devel
 
# 设置mysql开机自启动级别
sudo chkconfig --add mysqld
sudo chkconfig --level 35 mysqld on
 
# 启动mysql
sudo service mysqld start
 
# 连接数据库是否正常： root密码<空>
mysql -uroot
 
# mysql用户以及权限，可以按照自己需求添加，例：
# GRANT ALL PRIVILEGES ON *.* to 'rails'@'localhost' IDENTIFIED BY 'password'
{% endhighlight %}

<h2>2. Ruby安装</h2>

ruby on rails的开发语言。

{% highlight bash%}
# 安装ruby相关组件gem安装器
sudo yum install readline readline-devel ruby rubygems
 
# CentOs的Repo里面无ruby-devel，需指定安装
sudo yum --enablerepo=remi,remi-test -y install ruby-devel
 
# 查看ruby版本，过低版本的ruby需要升级，建议2.0.0-p247以后
ruby -v
 
# 更新Gem
gem update system
{% endhighlight%}

现在安装的Ruby版本过低，无法安装rails，rails需ruby1.9.x以上版本支持，所以要进行ruby的版本管理
这里安装rbenv进行ruby版本管理

{% highlight bash%}
# 安装rbenv
cd ~
git clone https://github.com/sstephenson/rbenv.git ~/.rbenv
 
# 设置环境变量
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bash_profile
echo 'eval "$(rbenv init -)"' >> ~/.bash_profile
exec $SHELL -l
 
# 安装ruby builder
git clone https://github.com/sstephenson/ruby-build.git ~/.rbenv/plugins/ruby-build
git clone https://github.com/sstephenson/rbenv-gem-rehash.git ~/.rbenv/plugins/rbenv-gem-rehash

{% endhighlight %}

centos 下2.0.0-p247安装会出现库文件路径问题，p353已修复，建议安装2.0.0-p353版本.[链接][centos-ruby]
{% highlight bash%}
# 通过rbenv安装ruby新版本
rbenv install -v 2.0.0-p353
 
# 将默认版本切换成最新版本
rbenv global 2.0.0-p353
rbenv rehash
 
# 查看ruby版本（大于1.9.x），此时应显示2.0.0-p353
ruby -v
echo 'gem: --no-rdoc --no-ri' >> ~/.gemrc
gem install bundler
{% endhighlight %}


<h2>3. rails安装相关</h2>

{% highlight bash %}
# 安装相关组件
rbenv exec gem install locale locale_rails gettext gettext_rails gettext_activerecord
 
# 安装rails
rbenv exec gem install rails
 
# 此时如果出现问题，找出问题所在安装所缺的库文件
# 安装rails过程中出现若干编码转换warning，可无视。
# 采用以下命令可以选择不安装rails文档（可以之后单独安装）
# rbenv exec gem install rails --no-ri --no-rdoc
 
# sqlite安装，rails数据库连接所需
sudo yum install sqllite sqlite-devel
rbenv exec gem install sqlite3-ruby
 
# 安装rails版本管理利器bundler
rbenv exec gem install bundler
{% endhighlight %}

<h2>4. 安装配置Passenger组件</h2>

passenger时apache以及nginx与rails的访问控制组件，国人开发。[链接][rails-passenger]

{% highlight bash%}
# 必要组件安装
sudo yum install httpd-devel apr-devel apr-util-devel
 
# 安装passenger
rbenv exec gem install passenger
passenger-install-apache2-module
 
# 查看apache是否成功加载passenger_module模块
apachectl -M
# 组件交互做的相当人性化，按照最后的提示操作即可
# 最后会提示修改httpd.conf
{% endhighlight%}

添加以下内容至httpd.conf(passenger安装完的提示内容完全复制粘贴)

{% highlight xml%}
LoadModule passenger_module /home/wills/.rbenv/versions/2.0.0-p353/lib/ruby/gems/2.0.0/gems/passenger-4.0.35/buildout/apache2/mod_passenger.so
<IfModule mod_passenger.c>
PassengerRoot /home/wills/.rbenv/versions/2.0.0-p353/lib/ruby/gems/2.0.0/gems/passenger-4.0.35
PassengerDefaultRuby /home/wills/.rbenv/versions/2.0.0-p353/bin/ruby
</IfModule>
{% endhighlight %}

<h2>5. 初始化Rails应用</h2>

{% highlight bash%}
cd ~
rails new [projectname] -d mysql
 
# 此时可以通过WEBrick方式启动rails应用
cd [projetname]
rails s
 
# 此时连接Ip:3000既可以看到欢迎页面或rails错误页面
{% endhighlight%}

现打算在不采用WEBrick，用apache监听80以及3000端口，同事提供两个虚拟主机的服务，其中3000用于rails提供的服务
修改httpd.conf virtualhost部分的设置如下（sample）

{% highlight xml%}
NameVirtualHost *:80
<VirtualHost *:80>
ServerAdmin yourmail@gmail.com
DocumentRoot /var/www/html/
ServerName fdwills.asia
</VirtualHost>
 
# 监听3000端口
# 如果无法连接此端口，请编辑iptables文件打开3000端口接受tcp请求
Listen 3000
NameVirtualHost *:3000
<VirtualHost *:3000>
ServerName fdwills.asia
DocumentRoot /home/wills/app/fdwills.asia/public/
AddDefaultCharset UTF-8
RailsBaseURI /
RailsEnv development
PassengerEnabled on
PassengerDefaultUser apache
PassengerMaxPoolSize 2
</VirtualHost>
{% endhighlight%}
ps. 一定要将DocumentRoot设置到应用下的public页面
public下存放静态html。从rails4.0public页面下无index.html文件，如果rails无法检测到index.html，即会转至welcome

<h2>6. 重启机器，通过IP或域名连接3000端口，出现rails的欢迎页面，Ok</h2>
[rails-passenger]: https://www.phusionpassenger.com/
[centos-ruby]: https://github.com/smalruby/smalruby/issues/4
