---
layout: post
title:  "手机游戏平台中的消费系统设计（三）"
date:   2014-07-20 20:44:57
categories: diary
tags: draft
---


## 接前言

正如前面所说，在苹果平台上的消费系统有如上特性，在谷歌平台上亦是如此。

需求还是如前没有变化，变化的是谷歌平台消费系统的特性。以最新发布的V3为例说明，区别在于如下:

1. 购买商品是可以自定义字符串developerPayLoader作为参数，该信息会被记录在购买的receipt里面，在做receipt验证的时候会返回该字符串。这可以被用作该购买的唯一标示。
2. 最新版本的Google In App Billing（IAB）内规定，购买的商品没有被消费之前，不能进行下一次购买，也就是说购买时的quantity不再作为购买的参数，然后就是购买之后必须进行一次显式的consume操作之后才能进行下一次同一物品的购买。
3. receipt的验证可以有多种方式
 - 在自己的服务器通过signature，receipt信息来完成验证
 - 在自己的服务器利用google purchase status API来连接google服务器完成验证（这里采用这种方式的验证）

### google的建议

在google android的IAB开发者文档里面有一些关于IAB安全方面的建议：

1. 永远进行signature的验证
2. 尽量使用服务器发放物品
3. 在购买时使用payloadery并用于验证receipt

还用其他一些建议，具体可以参考google的开发者文档。

### 流程图

这里需要完成的目标与iOS的IAP一样，同时结合google平台的特殊性，流程图就会有些变化。
具体的差别有：

1. 购买和验证时使用payloader
2. 购买后显式的cosume

![2]({{ site.url }}/assets/uml/iab-framework.png)

## 讨论

由于平台（IAP，IAB）存在一个价格变动的机制，即购买时候的价格不能确定。所以如果要正确计算平台的收入的话，最好购入时将价格一起传给平台用于统计。
