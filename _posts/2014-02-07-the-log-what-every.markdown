---
layout: post
title:  "【译】The Log: What every software engineer should know about real-time data's unifying abstraction"
date:   2014-02-05 20:44:57
categories: draft
tags: log
---
翻译来自Linked-in工程师的一篇文章。[链接][origin-link]

译者水平有限翻译如有误请指出。

Log：每个软件工程师都应该知道的数据的抽象

我在一个非常有趣的时间里加入了Linked-in。那个时候我们正面对我们单一的集成化的服务器的性能极限，需要开始将其其移植到一个组合的分布式系统上去。这是一个有趣的体验：我们搭建发布到一个分布图的数据库，一个分布式的搜索后台，Hadoop的安装，一个一级和二级的键值存储系统。

从中我学习到的最有趣的事是我们所做的大部分事情都有一个极其简单的核心概念：Log。有时叫做write-ahead log，有时候是commit log或者transcation log等等。log几乎与计算机存在的时间一样长，并且是很多分布式数据系统和实时应用框架的核心部分。

如果你不懂log，你就不会完全理解数据库，NoSQL存储，key-value存储，replication，paxos，hadoop，版本控制或者其他任何软件系统；并且大多数工程师都不熟悉这些。我想改变这种情况。在这片文章里面，我会带你了解所有你必须了解的关于log的东西，包括什么是log，怎样使用log进行数据调整，实时的数据处理以及建立系统。

## 第一部分：什么是log？

log可能是最简单的数据抽象表达方式。它是一个只能添加，完全有序的按照时间排序的记录的序列。像如下：

![2]({{ site.url }}/assets/log.png)

记录被添加在log的结尾处，处理从左向右进行，每个项都被赋予了一个唯一的log序列号码。

记录的排序代表了时序的概念，因为从左到右的记录表示了存在时间的长短。log的号码可以看做是记录的时间戳。描述这个顺序与时间的概念似乎有些奇怪，但因为它脱离任何特定的物理，使得考虑到分布式系统的时候很有必要。

记录的形式和内容在这次讨论中不很重要。并且，我们不能持续不断的添加log因为空间有限。待会再回来将这些。

所以，log并不与文件和数据表有很大区别区别。一个文件是字节的数组，数据表是数据的数组，log就像一种按时间排序的记录的文件或是表。



todo

[origin-link]: http://engineering.linkedin.com/distributed-systems/log-what-every-software-engineer-should-know-about-real-time-datas-unifying
