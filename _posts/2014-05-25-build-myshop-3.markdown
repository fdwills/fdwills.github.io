---
layout: post
title:  "配置rails中的自动任务与邮件"
date:   2014-05-25 20:44:57
categories: diary
tags: blog
---

## 缘由

在网上[商店][shop]系统中，由于商品的采购价是日元，销售价是人民币，所以打算把之前的固定汇率转换成自动获取相对实时的汇率数据。

于是设计了自动获取日元对人民币汇率的系统。主要分为以下几部分：

1. 自动抓取汇率的batch系统
2. 汇率的memcached和存取
3. 汇率获取成功与否的邮件通知

### 自动抓取汇率的batch系统

#### 使用[whenever][whenever]实施cron的管理，在Gemfile里面追加

    gem 'whenever', :require => false

#### 初始化whenever

    wheneverize .

#### 修改schedule.rb

之后会在config/下面得到schedule.rb，里面的每个every对应了一个crontab里面的项。

在schedule.rb里面添加需要的batch配置，如

```
# 每四小时执行一次current_rate:generate的任务
every 4.hours do
  rake "current_rate:generate"
end
```

#### 建立任务

建立具体的任务，例如这次建立的current_rate:generate任务

    rails g rake current_rate

会生成lib/tasks/current_rate.rb文件，之后修改current_rate.rb，添加具体的逻辑。

```
require 'open-uri'

namespace :current_rate do
  desc "Get Current rate from JPY to CNY"
  task :generate => :environment do
    source = open("http://stocks.finance.yahoo.co.jp/stocks/detail/?code=JPYCNY=X").read().split("\n")
    prices = source.grep(/stoksPrice/)
    if prices.size > 0
      rate = prices[0].gsub(/<[\w\s=\"\/]*>/, '').to_f
      Rails.cache.write("rate", rate)
    end
  end
end
```

由于google yahoo等取消了能够返回json的实时汇率API，所以只能够去网页上抓取。yahoo的网页上能够抓取到对应时刻的数据，分析之后的大致逻辑如上所示。此时就能够保证每隔2个小时抓取一次汇率，并存于memcached中。

### 处理memcached

在model/good.rb里面将原先固定的汇率换成汇率函数

```
def self.get_cached_rate_or_default
  # 在有cache时读cache，没有cache是采用固定汇率
  if value = Rails.cache.read("rate")
    value
  else
    0.0612
  end
end
```

### 邮件体系

由于网页网页失效/网页parse错误/取值异常等可能性，所以考虑对batch的rate值发mail通知管理员（userID = 1）。

#### 新建mail模型

    rails generate mailer SystemMailer

这是会生成app/mailers/system_mailer.rb文件，修改添加两个邮件的方法，一个用于成功，一个用于异常时的邮件发送。

```
class SystemMailer < ActionMailer::Base
  # 显示的邮件地址
  default from: "system@shop.fdwills.com"

  # 成功时
  def rate_batch_email(user, rate)
    @user = user
    @rate = rate
    mail(to: @user.email, subject: 'Rate Update Successfully')
  end

  # 异常时
  def rate_batch_fault_email(user)
    mail(to: @user.email, subject: 'Rate Update Failed')
  end
end
```

此时重新修改current_rate.rb的task，加入邮件处理，代码如下

```
require 'open-uri'

namespace :current_rate do
  desc "Get Current rate from JPY to CNY"
  task :generate => :environment do
    begin
      source = open("http://stocks.finance.yahoo.co.jp/stocks/detail/?code=JPYCNY=X").read().split("\n")
      prices = source.grep(/stoksPrice/)
      if prices.size > 0
        rate = prices[0].gsub(/<[\w\s=\"\/]*>/, '').to_f
        Rails.cache.write("rate", rate)
        SystemMailer.rate_batch_email(User.find_by_id(1), rate).deliver
      end
    rescue => e
        SystemMailer.rate_batch_fault_email(User.find_by_id(1)).deliver
    end
  end
end
```

这时就可以执行task测试一下是否成功。

### deploy

配置jenkins是需要将whenever的设置反应到系统的cron里面，所以在deploy脚本中加入

    bundle exec rake whenever -i

[whenever]: https://github.com/javan/whenever
[shop]: shop.fdwills.com
