---
layout: post
title:  "【译】Capistrano介绍"
date:   2014-01-21 20:44:57
categories: auto deploy
tags: 自动化
---
翻译来自GREE开发者博客上的文章。[链接][capistrano-link]

译者水平有限翻译如有误请指出。
<h2>开始</h2>

这篇是GREE Advent Calendar 2013年21日文章。呈上！

大家好，我是九冈。在GREE公司，我为了巩固Java以及Scala的传播基础，一个人制作了发布和监视的系统。

这次将在这个工程中学习到的知识以这片名叫【Capistrano 3入门博客】的形式共享出来。

<h2>想将所有产生手动操作的可能性消灭在萌芽状态</h2>

这篇博客将介绍Capistrano 3的基础。Capistrano 3是基于Ruby的服务器操作以及自动发布的攻击。Capistrano 3的利用能够将系统发布等复杂的服务器操作自动化。这篇博客里将特别以发布为焦点，说明如何利用Capistrano将服务器操作自动化。

学习Capistrano 3是需要花点时间的。为了降低各位所花的时间，于是我写了这篇文章。此处套话略去1000字。。。

<h2>对象</h2>

这片博客的对象是以下各位
1. 想知道Capistrano的概要的各位
2. 想学着使用Capistrano的各位
3. 想将手工操作自动化的各位
4. 已经通过其他工具实现了自动化

以上述各位作为对象，读了这篇博客之后能取得不错的收获事本文的目标。
（对于已经通过诸如Capistrano、Ansible、Fabic之类的工具实现了服务器操作自动化的各位，可能就没有什么新意了）

<h2>为什么deploy会花费大量的功夫</h2>

将做好的网络服务之类的应用发布给用户用，并不仅仅是开发这些应用，实际上还必须要讲这些服务放在服务器上让之运行。而且，这些应用的发布，意外的能花费大量的时间。究其原因，是因为发布相关的需求本身就存在这诸多分歧。

<h2>发布的需求是什么？</h2>
发布的需求大致有以下这些。

1. 应用的构成要素
2. 实施的环境与规模
3. 允许的发布时间间隔
4. 发布的最后期限
5. 预算是多少

<h3>应用的构成要素</h3>
采用什么语言开发，框架，是不是有中间层的应用

<h3>实施环境和规模</h3>
发布在什么样的服务器，多少台上

<h3>允许的发布时间间隔</h3>
从发布开始到发布结束花多少时间为好

<h3>发布的最后期限</h3>
有没有写自动化脚本的时间

<h3>预算是多少</h3>

为什么写自动化脚本会花费初期预算？
比如说，每次都用同样的语言开发，使用同样的框架和中间件，每次都发布在同样的服务器上的话，事情就简单了。但是如果不是这样发布的难度就会增加 。

<h2>手动作业好不好？</h2>

前述的分歧较多的发布需求，我们采用自动化或者手动作业来完成。

手动作业虽然有初期零投入的优点，但是须要不断有人持续的来写操作说明，并且反复操作过程中有出现错误的可能也是它的一个缺点。这就是想做自动化的原因。

<h2>那就做自动化不就好了么？</h2>
虽然这样想，但是做自动化有不得不翻越的壁垒。生成性壁垒和保守性壁垒。

<h3>生产性壁垒</h3>
用shell脚本？Ant？Ansible？Fabric？Capistrano？

开发新项目的时候，是建立自己的发布系统，还是利用现有的比如OSS之类系统，都是一个选项。单独的发布系统编码和测试需要花功夫，用现有的系统的时候学习需要花功夫。想尽早开始开心的编码起来。

<h3>保守性壁垒</h3>

沿用性？扩展性？
如果自己开发，沿用性有时候非常的困难。设计和编码的重点在什么能够设定，什么不能设定。如果能够留下充足的文档自然非常好，但是也时常有因为时间和预算的原因只够写完脚本而不能完成文档。

<h2>想自动化</h2>

因为这种原因，实际上我们在将发布自动化的时候，不得不考虑发布系统的沿用性和扩展性问题。这很难取舍。譬如“这次没时间了就手动操作”“先不管怎样自动化做起来，需要的时候在写文档”，也是没办法的事情。

但是，如果说理想情况，那就是超越生产性和保守的屏障做好自动化。

<h2>用Capistrano 3开始做自动化</h2>
越过上面所述的生产性和保守性的壁垒的一个方法是，降低学习以及持续的成本。本文就是出于这个目的。

<h2>期待的结果</h2>

采用Capistrano带来的变化
采用Capistrano，能够将各种发布流程同一成所谓的【Capistrano的设定】。

这种变化带来的优点和缺点是什么的？

<h3>优点</h3>

<h4>保守性程度高~maintainable~</h4>

写脚本的人设计思想是不一样的，读懂别人的设计思想是需要花时间的。如果大家都懂Capistrano的话，别人写的发布的设定动起来就很容易，就会导致保守性可持续性变高。

<h4>生成性程度高~productive~</h4>

shell脚本的话，通过软件包管理软件安装要使用的工具，或者通过git获取所需要的脚本，不同的人不同的组织有不同的选择方法。安装的话通过bundle install命令能将包括Capistrano本身，库文件以及扩展在内的所有囊括进来。

<h4>柔软度高~flexible~</h4>
是不是手上已经有为了发布而写的说明文档或者shell脚本了呢？
因为Capistrano任务本身只是“按照一定的顺序执行脚本”，这就和为了发布为写的脚本和操作流程是一样的。用nohup将操作放到后台运行，upstart/monit/daemontools/god之类的模块化，进程监视，进程ID的管理之类的脚本等等上述通过Ruby代码表象出来就行了。所以，如果与发布相关的东西，如果写进了Capistrano里，就很少有被限制的需求。

<h4>易读易写</h4>

能够用就像英语一样的精炼的DSL编写代码

而且，本地环境与服务器的操作在DSL语法上被明确的区分开来。首先本地环境上做什么，服务器环境生做什么，所谓的基于大局的脚本在写法上被很自然的被规约起来。

<h3>缺点</h3>

<h4>学习Capistrano需要花时间</h4>

确实需要花时间按，尤其是Capistrano 3 2013年8月刚刚发布。首先资料很少，就别说日语资料了。要记住新的东西本身就很困难，资料也少就难上加难了。

于是我写了这篇文章。如果大家能通过这篇文章很快的掌握Capistrano，我的目的也就达到了

<h2>首先要记住的是</h2>
粗分的话记住一下三个方面就够了
1. Capistrano的模块
2. Capistrano的工作流程
3. Capistrano配置文件的书写方法

<h3>Capistrano模块</h3>

具体的代码和设定学习之前，如果能掌握Capistrano的根本的工作方式，从全局上理解Capistrano的话，学期里会轻松很多。这就是所谓的Capistrano模块。程序从文档开始，文章从目录开始读的话全局一了解理解起来就会很容易

理解Capistrano的最低要求是一下的概念的理解
1. Capistrano
2. 库文件
3. 配置文件
4. host

<h4>Capistrano</h4>
Capistrano大致由以下三部分组成
1. cap命令
2. Capistrano的库文件
3. 默认的deploy任务

我们利用Capistrano的库文件和默认的deploy任务描述配置文件，然后通过cap命令执行。这样就能使Capistrano自动的进行一系列的操作。

<h4>库文件</h4>
Capistrano仅仅是一个框架，大家的应用开发时固有的deploy方法，服务器信息并没有被包含在里面。所以为了各自的自动化任务，必须要对Capistrano进行配置。

关于配置，有只是用一次的配置和使用多次的配置之分。再利用程度高的东西被称为插件，具体有以下两种。

1. Ruby插件
2. Capistrano扩展

<h4>配置文件</h4>

配置Capistrano的时候，只是用一次的设定（例如某个项目的服务器信息，某个项目固有的数据）不在上述的插件里面设置而在配置文件当中设置。具体有以下两种：

1. config/deploy.rb
2. config/deploy/任意阶段名称.rb

“deploy.rb”是发布的共通的设定和操作流程的书写的地。“任意阶段名称.rb”是线上环境，测试环境，开发环境等根据环境不同而不同的设定书写的地方。

<h4>host</h4>

发布的环境可以根据发布对象分为本地环境和服务器环境两种。必须要决定在什么样的环境执行什么样的命令。比如说本地环境build应用，在服务器发布应用，如果有这个认识的话就容易理解 多。

<h3>Capistrano的工作流程</h3>

为了使用Capistrano，为什么使用，用什么操作，要写什么代码好呢？让我们记住大体的流程吧。

1. Capistrano的安装
2. 建立配置文件的模型
3. 修改配置文件
4. 执行cap命令

以上的流程后面将做具体说明。

<h2>试着用Capistrano</h2>

<h3>1. Capistrano的安装</h3>

一键安装Capistrano

如果安装了RubyGems的话，执行以下命令就能安装Capistrano
{%highlight bash%}
gem install capistrano
{%endhighlight%}

如果执行gem须要root权限的话，别忘了加上sudo

如果是使用bundler的话，在Gemfile里面追加上以下然后运行bundle intall命令就能安装Capistrano

{%highlight ruby%}
gem 'capistrano', '~> 3.0.1'
{%endhighlight%}

不用bundler的话上述可以忽略。

<h3>2. 建立配置文件的模型</h3>

Capistrano安装完了之后，建立Capistrano配置文件存放的地方，名字任意

然后运行cap intall命令，上述的配置文件就生成了。

{%highlight bash%}
mkdir test-project
cd test-project
cap install
{%endhighlight%}

<h3>3. 配置文件设定</h3>

执行cap install命令之后，上述的配置文件就自动生成了。修改了这些配置文件之后就能实现自动化。

<h3>4. 配置文件完成之后大致形态</h3>

为了简单的理解，现在把完成之后的配置文件作为示例放出来。这样就能朝着示例文件方向一步一步讲解设定方法。

<h4>config/deploy/test.rb</h4>

{% highlight text%}
作业对象服务器的设定
{% endhighlight%}

<h4>config/deploy.rb</h4>
{% highlight text%}
去除Capistrano默认任务
任务 [代码获取]的定义
任务 [build，压缩、打包]的定义
任务 \[压缩包的build和安装\] [应用的启动和停止]的定义
{% endhighlight%}

<h3>5. Capistrano默认任务的消去</h3>

首先把Capistrano建立的默认任务全部删掉。

正如之前所述，Capistrano框架存在一些默认的任务。Capistrano默认任务包含了Capistrano本身推荐的一些deploy方法。例如通过链接将之前deploy的结果保存下来等等。

这里是否使用链接是开发的具体内容，在本片文章的范围之外。正因为如此，我们这里集中将如何将既存的手动作业利用capistrano自动化。

在现有Capistrano推荐的deploy方法基础上，将已有的deploy说明书改成Capistrano比较花费时间。与其相比，不如首先做个自己的deploy配置，如果有需要再慢慢改成Capistrano推荐的deploy流程。为什么这样呢，因为一下子需要改变的东西比较少而已。所以先将Capistrano默认任务全部删除。

{% highlight ruby%}
framework_tasks = [:starting, :started, :updating, :updated, :publishing, :published, :finishing, :finished]

framework_tasks.each do |t|
  Rake::Task["deploy:#{t}"].clear
end

Rake::Task[:deploy].clear
{% endhighlight%}

调用Capistrano里定义的默认deploy任务，多个[deploy:子任务]将被定义。运行Capistrano里定义的默认deploy的情况下，重定义[deploy:子任务]就够了，非常方便。但这里没有必要座椅全部删掉。删除任务的代码是
{%highlight ruby%}
Rake:Task[删除的任务名].clear
{%endhighlight%}
实际上Capistrano 3里面定义了叫做Rake的build工具。Rake的作用就是通过命令行或者应用的调用，完成定义好的任务。这里运用Rake将已有的任务删除。

<h3>6. 书写类如 config/deploy/阶段名称.rb 的文件</h3>

阶段名称.rb是deploy每个阶段的设定。比如有以下这些

1. 这个阶段的对象服务器
2. 仅仅在这个阶段执行的任务

典型的是之前说 对象服务器的设定，将包含一下这些信息：

1. host名
2. 服务器角色
3. 登录用户
4. SSH的设定
5. 其他与服务器相关的设定

夭折的那个这些，server这个关键字按照一下的写法来设定

{%highlight ruby%}
# server hostname, user: login_user, roles: %{serverrole}, 其他设定: 值, ...
server 'localhost', user: 'vagrant', roles: %w{web}
{%endhighlight%}

这一行包含了以下信息：

1. 将本地环境作为对象(执行Capistrano的主机)
2. 赋予这个服务器 webserver的role
3. 用vagrant用户登陆这个服务器

<h3>7. 书写config/deploy.rb</h3>

config/deploy.rb包含了各个阶段共同的设定，经常有的有如下。

1. 应用名称
2. repository的名称
3. 利用的SCM
4. 任务
5. 各种各样的执行任务的命令

类似这样的设定通过DSL来书写，DSL是有类似如下定义的语法

1. 设定的变更和取得
2. 任务的定义

<h4>设定值的变更和取得</h4>

应用名，Repo的名字等等的设定通过set name, value的方式设定，fetch name的方式获取。

一旦在deploy.rb里面设定的值，就能在deploy.rb以及deploy/阶段名.rb的所有地方获取到。

{%highlight ruby%}
set :repo_url, 'git@github.com:mumoshu/finagle_sample_app'

fetch :repo_url
#=> "git@github.com:mumoshu/finagle_sample_app"
{%endhighlight%}

<h4>任务的定义</h4>

各个任务通过task name do; ... end代码块的方式描述。

例如一个叫做:uptime的任务可以这样定义
{%highlight ruby%}
task :uptime do
  #这里写任务具体的内容
end
{%endhighlight%}

这里将接着写task代码块中run_locally do; ... end呀，或者on 对象服务器 do; ... end部分。

前者run_locally块中写要在本地运行的命令

后者on代码块中写在服务器上执行的命令

{%highlight ruby%}
task :uptime do
  run_locally do
    # 这里写在本地环境执行的命令
  end
  on 対象サーバ do
    # 这里写在服务器执行的命令
  end
end
{%endhighlight%}

on块重点对象服务器，能够在前面讲的[阶段名.rb]里面设定。

例如只对被赋予了叫做(:web)的角色的服务器作业的时候，可以向下面这样写。

{%highlight ruby%}
task :uptime do
  run_locally do
    # 这里写本地运行的命令
  end
  on roles(:web) do
    # 这里写在服务器上执行的命令
  end
end
{%endhighlight%}

<h5>通过execute执行命令</h5>

最后执行的命令写在run_locally或on块里面。

执行命令通过execute关键字。

例如要执行uptime命令写成下面这样

{%highlight ruby%}
task :uptime do
  run_locally do
    execute "uptime"
  end
  on roles(:web) do
    execute "uptime"
  end
end
{%endhighlight%}

<h5>通过capture获取执行结果</h5>

执行了execute的场合，这个命令的标准输出就会被丢掉。如果要获取标准输出的时候就可以通过capture命令执行。

{%highlight ruby%}
task :uptime do
  run_locally do
    output = capture "uptime"
  end
  on roles(:web) do
    output = capture "uptime"
  end
end
{%endhighlight%}

单纯的将execute换成capture，作为参数传递给capture的命令就会被执行，执行之后的标准输出文字就会被捕获。所以上面代码的意思就是将命令执行后的标准输出赋给output。

<h5>通过info输出到log</h5>

仅仅是获取可能没啥意义，尝试用Capistrano输出到log中。为了输出到log，根据run_locally和on块中的log等级，通过debug logmessage, info logmessage, warn logmessage, error logmessage, fatal logmessage等语法输出到log中。例如可以像如下这样使用info命令。
{%highlight ruby%}
task :uptime do
  run_locally do
    output = capture "uptime"
    info output
  end
  on roles(:web) do
    output = capture "uptime"
    info output
  end
end
{%endhighlight%}

<h5>任务的定义：总结</h5>

像这样，在run_locally on块中可以使用execute capture info等多种方法。可以利用的方法在[这个文件][method-list]里面定义了。

这里面介绍的语法经常被使用到的是
{%highlight ruby%}
upload! 本地文件路径, 远程文件路径
{%endhighlight%}
就像这个命令的名字一样是将文件进行传输。使用的方法是在on 对象服务器 do; ... end块里面执行，这样就能将在Capistrano执行的服务器上的文件通过SCP传输到对象服务器上。

记住这些经常被使用到的命令：

execute capture info upload!

<h2>任务的例子</h2>

任务在本地环境上执行和服务器上执行的分开来管理。这里有一些例子。

<h3>在本地环境上执行的例子</h3>

deploy.rb和阶段名.rb上要写的有如下

1. 源代码的获取
2. build和压缩打包

<h4>源代码的获取</h4>

在应用发布之前，须要在某个时间获取源代码。

例如，如果是采用Git进行版本管理的项目，下面这段代码就能获取源代码：

{%highlight ruby%}
set :application, 'finalge_sample_app'
set :repo_url, 'git@github.com:mumoshu/finagle_sample_app.git'

task :update do
  run_locally do
    application = fetch :application
    if test "[ -d #{application} ]"
      execute "cd #{application}; git pull"
      end
    else
      execute "git clone #{fetch :repo_url} #{application}"
    end
  end
end
{%endhighlight%}

在这个例子当中，定义了 :update的任务来获取代码，为了在本地环境上获取代码，代码的执行备方法run_locally里面。

在run_locally里面，根据有没有存在这个文件夹来判断是采用clone方法还是pull方法。

如果没有源代码，就根据设定好的repo_url通过git clone获取代码。保存的路径通过application设定。如果已经存在了源代码，，就先移动到代码目录下，再执行git pull命令更新之。

<h4>build和打包压缩</h4>

源码的编译在其他资源的操作之前进行，结果通过tarball，zip，war，debian package等等转换成可以再次发布的形式。

例如之前取得了代码的应用，在之后加入build和压缩打包的过程可以如下。

在这里利用叫做sbt的build和压缩工具，需要安装一个叫做sbt-pack的插件。（有兴趣请自己搜索）

{%highlight ruby%}
task :archive => :update do
  run_locally do
    sbt_output = capture "cd #{fetch :application}; sbt pack-archive"

    sbt_output_without_escape_sequences = sbt_output.lines.map { |line| line.gsub(/\e\[\d{1,2}m/, '') }.join

    archive_relative_path = sbt_output_without_escape_sequences.match(/\[info\] Generating (?<archive_path>.+\.tar\.gz)\s*$/)[:archive_path]
    archive_name = archive_relative_path.match(/(?<archive_name>[^\/]+\.tar\.gz)$/)[:archive_name]
    archive_absolute_path = File.join(capture("cd #{fetch(:application)}; pwd").chomp, archive_relative_path)

    info archive_absolute_path
    info archive_name

    set :archive_absolute_path, archive_absolute_path
    set :archive_name, archive_name
  end
end
{%endhighlight%}

按顺序来看。首先，通过task :achieve => :update do这样的写法：achieve任务=> update任务这个顺序。这是任务之间依赖关系的一种表现方式，就是指在执行achieve执行之前必须先执行update命令。

续。。。




[method-list]: https://github.com/capistrano/sshkit/blob/v1.2.0/lib/sshkit/backends/abstract.rb#L21
[capistrano-link]: http://labs.gree.jp/blog/2013/12/10084/
