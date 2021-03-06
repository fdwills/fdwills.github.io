---
layout: post
title:  "服务器建站笔记-Jenkins+Github配置"
date:   2014-01-24 10:44:57
categories: diary
tags: 服务器 建站
---
上一篇中安装了Jenkins

这一篇中将要完成一下任务：

1.github中创建代码仓库，自己的源码通过源码仓库管理

2.Jenkins中建立设置任务，测试脚本

3.github与Jenkins关联

<h2>1. 创建代码仓库</h2>

通过github创建一个初始repo

本地操作代码

{%highlight bash%}
# 本地git操作
git init
git remote origin [github创建的repo]
git add .
git commit -m'first init'
git push
 
# 如果push出现权限问题，请创建security key
sudo -u [username] -H ssh-keygen -t rsa -C hoge@gmail.com
# 将创建出来的~/.ssh/id_rsa.pub的内容添加到github中个人的key列表中
{%endhighlight%}

<h2>2. jenkins建立自动任务对rails进行自动测试</h2>

1. Jenkins管理界面中安装github插件

2. Jenkins中新建任务，并将在source code管理里面，选择git选项（需安装jenkins的github插件）

3. 将Repository URL设置成rails应用的repo地址（https的地址）

![jenkins1]({{ site.url }}/assets/2014-01-24-8.48.43.png)

4. Branch Specifier里面输入**

5. Build when a change is pushed to GitHub选中

![jenkins2]({{ site.url }}/assets/2014-01-24-8.48.59.png)

6. 设置将可用的.rbenv文件夹创建到JENKINS_HOME下的链接（因为在rails测试脚本中，需要用到.brenv管理下的命令）

7. build选择shell脚本，脚本文件例

{%highlight bash%}
$HOME/.rbenv/shims/bundle install
RAILS_ENV=test $HOME/.rbenv/shims/bundle exec rake db:drop:all
RAILS_ENV=test $HOME/.rbenv/shims/bundle exec rake db:create:all
RAILS_ENV=test $HOME/.rbenv/shims/bundle exec rake db:migrate
 
# 这里采用的测试框架是rspec。gemfile中加入rspec，并初始化rspec：
# bundle exec rails generate rspec:install
 
COVERAGE=true JENKINS=true $HOME/.rbenv/shims/bundle exec rspec
{%endhighlight%}

其他默认即可。设置完成之后点击面板左边的build执行，就能看到jenkins在执行rails的test任务了

![jenkins2]({{ site.url }}/assets/2014-01-24-8.48.59.png)
<h2>3. 关联github与jenkins</h2>

1. 按照生产用户security key的方法生产jenkins专用key，并将key加入github的列表中(/var/lib/jenkins/.ssh/id_rsa.pub)

{%highlight bash%}
sudo -u jenkins -H ssh-keygen -t rsa -C hoge@gmail.com
{%endhighlight%}

2. 登陆github，找到项目，在项目setting中选择ServiceHooks

选择Jenkins (Github plugin)选项

输入hook的URL，并激活

http://hostname/github-webhook/

TestHook

3. 测试：

在本地修改代码，并通过git push到github，即会在jenkins面板上看到Jenkins把代码拿下来做测试了。

如果测试结果没通过，请修改测试脚本


