---
layout: post
title:  "【译】memcached介绍(2)"
date:   2014-02-05 20:44:57
categories: diary
tags: apache memcached
---
翻译来自日本某技术网站的入门级文章。[链接][memcached]

译者水平有限翻译如有误请指出。

上一回介绍了memcached，这次将memcached内部实现，以及怎样进行内存管理的进行介绍。以及memcached内部构造产生的缺点。

## 内存整理在利用的Slab Allocation机制

memcached默认采用Slab Allocator的机制管理内存。在这种机制出现之前，单纯的采用对所有的记录采取malloc和free的方法进行管理。这种方法会产生大量的内存碎片，给操作系统的内存管理造成很大负担。最坏的时候内存造成的负担比memcached本身的进程消耗都要多。为了克服这种问题产生了Slab Allocator。

看看Slab Allocator的结构。以下引用自memcached文档。

    the primary goal of the slabs subsystem in memcached was to eliminate memory fragmentation issues totally by using fixed-size memory chunks coming from a few predetermined size classes.

总之，Slab Allocation的根本是分配好的内存按照事先决定好的class size分成固定的长度的小块，内存碎片的问题就完全克服了。

Slab Allocation的结构是简单的，分配好的内存的内存按照各种各样固定的大小分成块(chunk)，相同大小的chunk按照class整理起来。

![1]({{ site.url }}/assets/TH400_0002-01.png)

另外，slab allocator里面，有个目标是将分配好的内存再利用。于是，memcached不释放被分配的内存而是将chunk再利用。

### Slab Allccator的主要术语

* Page
  - 默认按照大小1MB的固定大小，用Slab分割好的块。Slab分割好之后，按照slab的大小分配成chunk
* Chunk
  - 缓存记录的内存块
* Slab Class
  - 按照特定大小的chunk整理好的class

### Slab内的记录缓存结构

通过客户端传来的数据，memcached究竟怎样选择slab，怎样存入chunk缓存中进行说明。

memcached参照收到的数据的大小，在slab中选择一个最适合的一个。memcached在slab内维持一个空闲的chunk列表，基于这个列表选择一个chunk，将数据放入chunk之中。

![2]({{ site.url }}/assets/TH400_0002-02.png)

这里介绍的Slab Allocator，不仅仅有有点而且也有缺点，下面对缺点说明。

## Slab Alloctor的缺点

虽然解决了内存碎片的问题，但是还有其他问题。

这个问题就是：分配固定长度的内存解决方案中，分配的内存不能有效的利用的问题。例如，100字节的数据存储在128字节的，多出来的28字节就不能有效利用。

![2]({{ site.url }}/assets/TH400_0002-03.png)

虽然能完全解决这个问题的方案还不存在，但是在文档里面记载了一个效率的解决方案。

    The most efficient way to reduce the waste is to use a list of size classes that closely matches (if that's at all possible) common sizes of objects that the clients of this particular installation of memcached are likely to store.

就是，提前解析客户端送来的数据的大小，或者存在用户的需求仅保存在正好大小的快中。根据这个大小使用适合的列表，能够抑制内存的浪费。

但是可惜的是现状是这个方案没有实行，留作了将来的课题。但是slab class的大小的差异是可以调节的。在下面的growth factor选项里面说明了。

## 使用Growth Factor进行调节

memcached启动的时候制定叫做Growth Factor的因子（-f 选项），能够在某种程度上控制slab之间的大小差异。默认值是1.25，在这个选项开发之前是所谓的“2的次方”的战略，固定设置为2。

按照以前的设定启动memcached以verbose模式启动即为

    memcached -f 2 -vv

下面是启动之后的输出

    slab class   1: chunk size    128 perslab  8192
    slab class   2: chunk size    256 perslab  4096
    slab class   3: chunk size    512 perslab  2048
    slab class   4: chunk size   1024 perslab  1024
    slab class   5: chunk size   2048 perslab   512
    slab class   6: chunk size   4096 perslab   256
    slab class   7: chunk size   8192 perslab   128
    slab class   8: chunk size  16384 perslab    64
    slab class   9: chunk size  32768 perslab    32
    slab class  10: chunk size  65536 perslab    16
    slab class  11: chunk size 131072 perslab     8
    slab class  12: chunk size 262144 perslab     4
    slab class  13: chunk size 524288 perslab     2

正如显示的这样，从128字节的class开始，不断按照两倍的倍率增加。这个设定的问题是，slab之间的差距比较大，根据usecase会产生相当大的无效内存，基于这个背景增加了growth factor选项。

现在按照默认的1.25的倍率设定的话，输出为以下

    slab class   1: chunk size     88 perslab 11915
    slab class   2: chunk size    112 perslab  9362
    slab class   3: chunk size    144 perslab  7281
    slab class   4: chunk size    184 perslab  5698
    slab class   5: chunk size    232 perslab  4519
    slab class   6: chunk size    296 perslab  3542
    slab class   7: chunk size    376 perslab  2788
    slab class   8: chunk size    472 perslab  2221
    slab class   9: chunk size    592 perslab  1771
    slab class  10: chunk size    744 perslab  1409

正如看到的，因为选用了比2小的因子来启动，能够很贴切的存储数百字节的数据。另外，看了输出之后，可能会感觉到在计算上存在了很多误差，这些误差是为了保持内部的字节数的对齐而刻意产生的。

在探讨是否将memcached导入产品，或者不考虑直接配置到产品里的情况，一定先计算数据的平均预测值，调节growth factor到最优。内存很珍贵，不要无端浪费。

## memcached内部使用情况调查

memcached里面有个stats命令，根据stats的情况能得到很多有用的信息。执行命令的方法有很多，telnet是最轻量的一个。

    $ telnet host port

连接到memcached之后，输入stats命令，可以得到包括资源使用率在内的各种信息。其他的诸如stats slabs，status items输入之后slab缓存的数据就能取出来。输出quit是退出。关于命令的详细参考memcached包里面的protocol.txt里面的记载。

{%highlight bash%}
    $ telnet localhost 11211
    Trying ::1...
    Connected to localhost.
    Escape character is '^]'.
    stats
    STAT pid 481
    STAT uptime 16574
    STAT time 1213687612
    STAT version 1.2.5
    STAT pointer_size 32
    STAT rusage_user 0.102297
    STAT rusage_system 0.214317
    STAT curr_items 0
    STAT total_items 0
    STAT bytes 0
    STAT curr_connections 6
    STAT total_connections 8
    STAT connection_structures 7
    STAT cmd_get 0
    STAT cmd_set 0
    STAT get_hits 0
    STAT get_misses 0
    STAT evictions 0
    STAT bytes_read 20
    STAT bytes_written 465
    STAT limit_maxbytes 67108864
    STAT threads 4
    END
    quit
{%endhighlight%}

另外，安装了叫做libmemcached的c/c++的库文件之后，叫做memstat的可执行文件也同时被安装，能够以比telnet简单的步骤获取复杂的服务器数据信息。

    $ memcached -servers=server1,server2,server2,...

libmemcached可以从下面的连接获取
[链接][libmemcached]

## Slabs的使用情况调查

Brad写的memcached-tool的perl脚本，能够简单的获取memcached的使用情况。[脚本链接][tools]

使用方法很简单

    $ memcached-tool host:port option

查询Slabsde使用情况可以不指定选项

    $ memcached-tool host:port

输出的情况如下：

     #  Item_Size   Max_age  1MB_pages Count   Full?
     1     104 B  1394292 s    1215 12249628    yes
     2     136 B  1456795 s      52  400919     yes
     3     176 B  1339587 s      33  196567     yes
     4     224 B  1360926 s     109  510221     yes
     5     280 B  1570071 s      49  183452     yes
     6     352 B  1592051 s      77  229197     yes
     7     440 B  1517732 s      66  157183     yes
     8     552 B  1460821 s      62  117697     yes
     9     696 B  1521917 s     143  215308     yes
    10     872 B  1695035 s     205  246162     yes
    11     1.1 kB 1681650 s     233  221968     yes
    12     1.3 kB 1603363 s     241  183621     yes
    13     1.7 kB 1634218 s      94   57197     yes
    14     2.1 kB 1695038 s      75   36488     yes
    15     2.6 kB 1747075 s      65   25203     yes
    16     3.3 kB 1760661 s      78   24167     yes

各列的意思是：
<table>
<tr>
<th>column</th>
<th>description</th>
</tr>
<tr>
<td>#</td>
<td>slab class号</td>
</tr>
<tr>
<td>item\_Size</td>
<td>chunk的大小</td>
</tr>
<tr>
<td>Max\_age</td>
<td>LRU里面最古来的数据的生存时间</td>
</tr>
<tr>
<td>1MB\_pages</td>
<td>被Slab分割的page数目</td>
</tr>
<tr>
<td>Conunt</td>
<td>Slab里的记录数</td>
</tr>
<tr>
<td>Fulls?</td>
<td>slab里面是否有空闲的chunk的标志位</td>
</tr>
</table>

## 总结

这次讲了memcached的机制和调节方法。下次讲memcached的最新动向。

to be continued
[tools]: http://www.danga.com/memcached/dist/memcached-tool
[libmemcached]: http://tangent.org/552/libmemcached.html
[memcached]: http://gihyo.jp/dev/feature/01/memcached/0002


