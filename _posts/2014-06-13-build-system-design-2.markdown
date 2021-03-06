---
layout: post
title:  "手机游戏平台中的消费系统设计（二）"
date:   2014-06-13 20:44:57
categories: diary
tags: blog
---


## 接前言

如上篇所说，如果作为一个综合性平台来说的话，又不希望自己来完成整套支付系统的话，那么就必须整合苹果和谷歌的服务（可能在国内谷歌的服务并不能顺畅的被访问）。这里首先探讨苹果的在线支付服务。

首先再明确一下现在的需求

1. 用户的数据存在平台端
2. 支付由苹果完成，内容的赋予由平台完成
3. 商品的购买方式，购买权限都用平台来控制
4. 平台管理并记录用户的商品购买，而不采用苹果

简单的说，在这里苹果唯一做的事情就是接受用户的付款，然后通知App付款成功这么简单。

然而困难的地方在于服务器对商品的控制，例如有以下几种情况

1. 商品从上午一点贩卖到下午一点（时间上的控制）
2. 商品能够每天购买两次（次数上的控制）
3. 商品的第一次购买的价格优惠80%（商品显示上的控制）

困难的根源在于苹果的支付的事务，App是无法介入的，当苹果的购买流程开始之后，你就除了等到他完成的通知没有其他办法。购买流程的开始到结束中间有弹出确认框，输入密码等等动作，而这里的工作都是用iOS的StoreKit框架来完成，跟程序本体无关属于别的进程，购买完成之后再通知应用程序。

商品的信息通过iTunes放在了苹果的服务器上，苹果服务器又不能完成时间，数量的控制。如果就弹出确认框开始防止不动，开始另一台机器购买等等情况发生的可能性而言，无法完成严格的时间数量控制。

### 苹果的建议流程

先来看看苹果对于用服务器发放内容的实现流程。

![1]({{ site.url }}/assets/iap.png)

整个流程中有三种角色：

1. 程序客户端：用于从苹果服务器购买，并将购买结果发给服务器用于内容的发放
2. 苹果服务器：用于完成用户的购买，并提供收据的验证服务
3. 游戏自己的服务器：用于接收收据并验证，合法之后发放内容

这种设计对于没有种种购买限制的商品，并且系统的鲁棒性要求不是太高的情况下，是绰绰有余的设计了。

### 探讨1

如果加入购买限制怎么办？

对，可以在购买之前先请求游戏服务器是否允许购买。

即在上一个图中的购买之前，添加一个部分：请求服务器的事务。

游戏服务器的事务设计成这样：

* 什么时候请求事务？
  - 去苹果的购买之前，从SDK上来说就是addPayment之前

* 什么情况下拒绝事务的方法请求？
 - 已经对同一商品拥有一个未完成的事务
 - 用户请求的商品超出了购买的时限
 - 用户购买的数量超过了购买的数量限制

* 什么时候结束事务？
  - 用户从苹果购买成功的时候，往服务器发送结束事务请求
  - 用户取消购买/购买失败的时候，往服务器发送取消任务请求

服务器在收到客户端事务的请求之后，查看这个商品设置（什么时候能买）以及用户的购买历史等等，最后决定食物是否发放。如果方法事务的话，继续进行到苹果服务器的购买，如果不发放，就结束这次购买。

最后苹果的购买完成之后，通知服务器结束这个事务。并保证每个用户对于每个商品只允许拥有一个开放的事务。

### 探讨2

如果如上的增加服务器端事务的策略，那么整个过程中通讯故障怎么办？

整个过程中其实需要通讯的步骤很多，如果在App在苹果商店完成交易之后服务器完成内容发放之前发生通讯故障，那么就会造成数据的不整合，即完成了交易但是用户没有拿到东西。

解决这个问题首先要熟悉App一般在苹果商店里面执行应用内购买的步骤：

1. 启动程序时从DefaultQueue初始化PaymentQueue
2. 实现Observer，并添加updatedTransaction方法，为里面购买成功/失败/取消是添加对应的处理。在处理之后添加finishTransaction从Queue里面移除
3. 将Observer附加到PaymentQueue上

如果通讯中断，那么为服务器端可能已经完成，但是App的本地环境上的IAP的事务不会被清除。而且如果服务器的内容赋予没有完成的话，情况就更遭了，即用户永远不会拿到他所购买的东西。

这里添加一个恢复阶段，即程序初始化以及每次的购买之前，首先检查Queue里面是不是留有参与的事务，如果有则做回复处理。

![2]({{ site.url }}/assets/uml/recovery.png)

### 流程图

综合以上的想法，于是最后的设计流程变成了这样

![2]({{ site.url }}/assets/uml/iap-framework.png)

## 讨论

这样的处理也不是万无一失的处理，最大的原因在于如果服务器端事务方法了之后，客户端在实施购买之前出现了故障，那么服务器端的未关闭的事务就无法删除/取消，可能对用户购买产生一点影响。
