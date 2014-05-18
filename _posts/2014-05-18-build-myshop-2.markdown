---
layout: post
title:  "rails中的memcached"
date:   2014-05-18 20:44:57
categories: diary
tags: blog
---

## rails中的memcached

rails中的memcached其实与其他memcached一样，只是使用的API不同，正如前面的翻译文章介绍的那样。

这里实际讲述memcached在rails系统上的搭建和仍遗留的问题。这里采用dailli gem来完成。

### Dailli的安装

gem file中添加以下行，再执行bundle install

    gem 'dalli'

当然在server上安装并启动memcached服务。Centos上是如下

    sudo yum install memcached

    # 具体启动的参数可以参考/etc/rc.d/init.d/memcached里面的参数设置
    # 关于参数的设置方法参看前面的memcached介绍文章
    sudo service memcached start


通过telnet连接本地端口11211进行一些write，get，state操作测试memcached服务器运作情况是否正常。

### Memcached的配置

在config/environments/production.rb和development.rd做memcached的设置，例：

    config.cache_store = :dalli_store, 'localhost', { namespace: 'shop', expires_in: 1.day, compress: true }

其他的问题可以参考[这里][intro]

通过rails command测试rails中memcached配置是否正常。这里memcached能都存取的对象不仅仅是数值和字符串，而且能存储json数据以及activerocord对象。

```
rails c

Rails.cache.write 'hoge', 'pugi'
# => true

Rails.cache.read 'hoge'
# => "pugi"

Rails.cache.delete 'hoge'
# => true

Rails.cache.read 'hoge'
# => nil
```

### 对商品的缓存

接上一片文章里面的需要缓存的内容，对商品的activerecord对象进行缓存。

新建关于cache的rails concern： model/concerns/cached.rb

```ruby
module Cache
  extend ActiveSupport::Concern

  included do
    def self.get_or_cache(id)
      unless instance = Rails.cache.read("#{self.name}_#{id}")
        instance = self.find_by_id(id)
        Rails.cache.write("#{self.name}_#{id}", instance)
      end
      instance
    end
  end

  def clear_cache
    Rails.cache.delete("#{self.class.name}_#{self.id}")
  end

  def recache
    Rails.cache.delete("#{self.class.name}_#{self.id}")
    instance = self.class.find_by_id(id)
    Rails.cache.write("#{self.class.name}_#{self.id}", instance) if instance
  end
end
```
这里对是否缓存做判断，并进行缓存。同时对于缓存也预备了手动清除/更新处理。

然后在需要缓存的model里面include Cache模块，就能对具有id index的表格进行缓存。注意取数据是的方法不是find/find_by_id/where等操作，而是通过get_or_cache完成。

将他include进商品模块中（Good）此时来测试以下运行情况。

```
rails c

Good.get_or_cache(1)
# 这里可以看到记录里面有对数据库的读操作和memcached的写操作

good = Good.get_or_cache(1)
# 这里只会看到对memcached的读操作

good.clear_cache
# 这里只会看到对memcached的删除操作

good.recache
# 这里会看到对memcached的强制更新。包括cache的删除，数据库操作和cache写操作
```

都成功之后，就可以修改controller开始对各种数据的缓存缓存处理了。

### 问题

* 如何通过activerecode的find等操作自动完成cache的操作
* 如何通过activerecord的relation完成cache操作

[shop]: shop.fdwills.com
[intro]: http://morizyun.github.io/blog/gem-dalli-memcache/
