---
layout: post
title:  "搭建代购网站"
date:   2014-05-17 20:44:57
categories: diary
tags: blog
---

## 搭建代购网站

有人要做与我合作代购网站，花一天时间于是从上一个[app][app]的基础上搭建了一个新的系统。同样有production与dev两个版本，同样采用github与jenkins自动deploy。因为有之前的工作作参考，一切还都挺顺利。

系统一样分为游客访问模式(visitor)，自主管理模式(me)和管理员模式(admin)，通过controler的父类分开，并检查权限。

模型上现在主要有商品和订单的模型。商品的新建/更新依赖与管理员；订单的新建更新则有用户和管理员共同完成。

### 关于用户

由于只有注册用户才能创建订单的限制，所有与之前同样有用户的注册和登录功能。但是由于考虑到之前的[app][appi]已有这部分功能，所以这里对于用户模型采用与之间的app同样的DB连接访问。

1. 在database.yml里面添加与login相关的DB设置

```
default: &default
  adapter: mysql2
  encoding: utf8
  pool: 5
  username: root
  password:
  socket: /var/lib/mysql/mysql.sock

###### for common login ####
login_development:
  database: fdwills_development
  <<: *default

login_test:
  database: fdwills_test
  <<: *default

login_production:
  database: fdwills_production
  <<: *default

```

2. 改变User的DB连接

在model/user.rb里面添加如下行。

```
establish_connection "login_#{Rails.env}"
```

此时在各种环境上的user DB则会指向之前的DB。

另外Production环境下用户的头像图片的存放文件夹需要链接指向之前的头像文件夹。

### 关于商品

商品有管理管理员创建，提供图片上传等功能。这里考虑到商品是经常被浏览的对象，所以考虑用memcached对商品做缓存。详细见下片文章。

### 关于订单

订单属于用户与管理员同时管理的数据：

用户：创建，修改内容，更新状态

管理员：修改内容，更新状态

关于状态的更新是指该订单在流程中所处于的位置（新建--正在处理--已发货--已收到--处理结束）。在这些状态中用户只能改变其中的某系状态，管理员也只能改变其中的某些，所以在状态的更新过程中做了严格的权限检查。

流程图

![1]({{ site.url }}/assets/shop-flow.png)

[app]: app.fdwills.com
