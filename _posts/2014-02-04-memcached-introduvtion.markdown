---
layout: post
title:  "【译】memcached介绍(1)"
date:   2014-02-04 20:44:57
categories: memcached
tags: apache memcached
---
翻译来自日本某技术网站的入门级文章。[链接][memcached]

译者水平有限翻译如有误请指出。

memcached是曾经运营LiveJournal的Danga Interactive公司，以Brad Fitzpatrick为中心开发的软件。现在在mixi，facebook，Vox，LiveJournal等各种网络应用中在提升性能方面起着重要的作用。

大多数的网络应用的数据存储在关系数据库上(RDBMS)。这些应用从数据库中读取数据表示在浏览器等上面。但是数据量增大的时候，访问一旦集中，RDBMS的负荷就会增大，数据库响应就会变慢。网络应用的表示就会受到延迟等很大影响。

memcached就活跃在这块领域。memcached是高性能的分散缓存服务器。通常数据库的访问会被缓存一段时间，对数据库的访问回数就会减少，动态的使网络服务高速化。

![1]({{ site.url }}/assets/TH400_0001-01.png)

## memcached的特征

memcached是非常高性能的分散缓存服务器，具有以下特征：

1. 简单的协议
2. 通过libevent处理事件
3. 内置的内存存储
4. 采用在memcached之间不进行通信的分散方式

### 简单的协议

memcached的服务器与客户端之间的通信不采用XML等复杂的格式，采用基于行的简单的协议进行。因为是基于行的协议，能够通过telnet方式存取memcached的数据。下面是例子：

    $ telnet localhost 11211
    Trying 127.0.0.1...
    Connected to localhost.localdomain (127.0.0.1).
    Escape character is '^]'.
    set foo 0 0 3     （保存的命令）
    bar               （数据）
    STORED            （结果）
    get foo           （获取命令）
    VALUE foo 0 3     （数据）
    bar               （数据）

协议相关内容在memcached的源码里面有，参考[这里][source]

### 通过libevent处理事件

libevent是不管Linux还是epoll,BSD系列的OS还是kqueue等的时间处理机制，是对于服务器连接增加之后仍然能够以O(1)的性能发挥作用的共同功能使用的库。memcached里面采用了libevent的库，所以能够在Linux,BSD,Solaris等系统上发挥作用。事件处理机制在这里不详说明，参考以下：

1. [libevent][libevent]
2. [The C10K problem][libevent2]

### 内置的内存存储

保存在memcached里面的数据使用能够提升性能的内置内存存储方式存储。数据全部保存在内存上，所以当memcached或者OS重启的时候所有的数据都会消失。另外，如果到达了指定的内存利用上线的时候，基于LRU(Least Recently Used)原则自动删除缓存。因为为了使memcached本身拥有缓存功能，所以设计的时候几乎不考虑数据的持久化。

### 采用在memcached之间不进行通信的分散方式

虽然说memcached是分散的缓存服务器，但是与分散相关的功能却没有在服务器侧实现。memcached之间不能通过通信进行信息共享。怎样分散全部依赖于客户端的实现。

![2]({{ site.url }}/assets/TH400_0001-02.png)

## memcached的导入

memcached的导入比较简单，这里对安装做说明。

memcached在一下的平台上理论上能够运作

* Linux
* FreeBSD
* Solrais(memcached 1.2.5以上版本)
* Mac OS X

另外也能安装在Windows上，这里利用Fedora8进行说明

### memcached的安装

memcached的运行需要之前介绍的libevent。Fedora8上rpm已经有安装包，利用yum进行安装

    sudo yum install libevent libevent-devel

memcached的云马在memcached的官网可以下载[连接][memcache-source]。Fedora8上有rpm包，这次不利用yum安装。

memcached与一般的软件相同，configure, make, make install就能安装完毕。

{%highlight bash%}
    wget http://www.memcached.org/files/memcached-1.4.17.tar.gz
    tar zxf memcached-1.4.17.tar.gz
    cd memcached-1.4.17
    ./configure
    make
    sudo make install
{%endhighlight%}

memcached被安装在/usr/local/bin下面

### memcached的启动

终端上执行命令就能启动memcached

    $ /usr/local/bin/memcached -p 11211 -m 64m -vv
    slab class   1: chunk size     88 perslab 11915
    slab class   2: chunk size    112 perslab  9362
    slab class   3: chunk size    144 perslab  7281
    ....
    slab class  38: chunk size 391224 perslab     2
    slab class  39: chunk size 489032 perslab     2
    <23 server listening
    <24 send buffer was 110592, now 268435456
    <24 server listening (udp)
    <24 server listening (udp)
    <24 server listening (udp)
    <24 server listening (udp)

debug的信息出来了，这样就能利用TCP的11211端口坚挺，最大利用的内存位64m的memcached在前端启动起来了。

想让memcached作为demon启动的话运行以下

    $ /usr/local/bin/memcached -p 11211 -m 64m -d

这里利用的memcached的启动选项的说明如下：

<table>
<tr>
  <th>选项</th>
  <th>说明</th>
</tr>
<tr>
  <td>-p</td>
  <td>利用的TCP端口号，默认是11211</td>
</tr>
<tr>
  <td>-m</td>
  <td>最大利用的内存容量，默认是64</td>
</tr>
<tr>
  <td>-vv</td>
  <td>very verbose模式启动，debug信息和error信息在终端显示出来</td>
</tr>
<tr>
  <td>-d</td>
  <td>将memcached作为demon在后台运行</td>
</tr>
</table>

常用到的启动选项是上面4个，另外一些选线，参考帮助文档

    /usr/local/bin/memcached -h

### 客户端利用库文件连接

与memcached进行连接的客户端API库，从perl和php开始，已经用各种语言实现。以下是官网记载的支持的语言：

* Perl
* PHP
* Python
* Ruby
* C#
* C/C++
* Lua


[客户端API下载地址][api]

这里利用perl的API库对memcached的连接做介绍

## Cache::Memcached的利用

Perl的memcached库文件有以下在CPAN发布

* Cache::Memcached
* Cache::Memcached::Fast
* Cache::Memcached::libmemcached

这里利用memcached的开发者Brad Fitzpatrick写的Cache::Memcached作介绍。

[Cache::Memcached - search.cpan.org][memcached-cpan]

### 利用Cache::Memcached连接memcached

下面的代码是利用Cache::Memcached连接memcached的例子

{%highlight perl%}
    #!/usr/bin/perl

    use strict;
    use warnings;
    use Cache::Memcached;

    my $key = "foo";
    my $value = "bar";
    my $expires = 3600; # 1 hour
    my $memcached = Cache::Memcached->new({
      servers => ["127.0.0.1:11211"],
      compress_threshold => 10_000
    });

    $memcached->add($key, $value, $expires);
    my $ret = $memcached->get($key);
    print "$ret\n";

{%endhighlight%}

这里对Cache::Memcached指定服务器IP和选项获得instance。

Cache::Memcached经常利用到的选项有如下：

<table>
<tr>
  <th>选项</th>
  <th>说明</th>
</tr>
<tr>
  <td>servers</td>
  <td>将memcached的服务器地址与端口通过数组形式组织起来</td>
</tr>
<tr>
  <td>compress\_threshold</td>
  <td>数据压缩时候的值64</td>
</tr>
<tr>
  <td>namespace</td>
  <td>指定key的前缀</td>
</tr>
</table>

Cache::Memcached能保存Perl的复杂的Storable模块的序列化的数据，日不哈希，数组，对象等等。

### 数据的保存

memcached保存数据的方法有

* add
* replace
* set

三种方式的使用方法相同

{%highlight perl%}
    my $add = $memcached->add( 'key', 'value', 'expire time' );
    my $replace = $memcached->replace( 'key', 'value', 'expire time' );
    my $set = $memcached->set( 'key', 'value', 'expire time' );
{%endhighlight%}

期限时间以秒为单位保存，不指定的情况下基于memcached的LRU策略保存数据。这三种方法的不同点在于


<table>
<tr>
  <th>选项</th>
  <th>说明</th>
</tr>
<tr>
  <td>add</td>
  <td>仅当内存上没有此数据的时候保存</td>
</tr>
<tr>
  <td>replace</td>
  <td>仅在存在此数据的时候保存</td>
</tr>
<tr>
  <td>set</td>
  <td>任何情况都保存</td>
</tr>
</table>

### 数据的获取

数据的获取利用get和get\_multi等方法

{%highlight perl%}
my $val = $memcached->get('key');
my $val = $memcached->get\_multi('key1', 'key2', 'key3', 'key4', 'key5');
{%endhighlight%}

一下子取很多数据的时候用get\_multi。利用get\_multi，memcached能够不同步的取多个值，比用get循环取值速度块数十倍。

### 数据的删除

数据的删除用delete方法

{%highlight perl%}
    $memcached->delete('key', 'block time');
{%endhighlight%}

通常制定的第一参数是需要删除的数据的key，第二参数是在一定时间内不存储同样key的数据。这是为了防止缓存数据错乱。但是，_set方法能够在指定的key上强制保存数据_。请注意。

### 递增和递减

memcache上的特定的key上能够计数。

{%highlight perl%}
my $ret = $memcached->incr('key');
$memcached->add('key', 0) unless defined $ret;
{%endhighlight%}

注意是递增递减的计数操作不会在没有初始化时自动初始化为0。须要检查error进行初始化。同时当计数超过int的大笑之后，服务器段也不会检测。

to be continued

[memcached-cpan]: http://search.cpan.org/dist/Cache-Memcached/
[api]: https://code.google.com/p/memcached/wiki/Clients
[libevent]: http://www.monkey.org/~provos/libevent/
[libevent2]: http://www.kegel.com/c10k.html
[memcache-source]: http://memcached.org/
[source]: http://code.sixapart.com/svn/memcached/trunk/server/doc/protocol.txt
[memcached]: http://gihyo.jp/dev/feature/01/memcached/0001
