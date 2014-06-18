---
layout: post
title:  "安卓应用的SSL Pinning"
date:   2014-06-13 20:44:57
categories: diary
tags: blog
---

## 关于SSL

SSL协议是网络层的子层。标准的SSL协议当中须有四次握手过程，运用了对称加密和非对称加密的特性。完成握手之后的通讯被认为是一个安全的通道。虽然最近OpenSSL的漏洞被爆出来。四次握手大致所做的事情是这样：

#### 第一阶段：建立安全能力

* 交换客户端服务器的随即数
* 协商版本号，加密算法，密钥交换算法
* 确定回话ID

#### 第二阶段：服务器端认证

* 客户端是这个阶段的接收方
* 服务器将证书发给客户端
* 客户端验证服务器端的证书（通过CA公开键，验证证书链）
* 服务器密钥交换（交换算法可选）
* 服务器请求用户自身验证
* 服务器认证发送完成

#### 第三阶段：用户认证

* 服务器端是这个阶段的接收方
* 用户发送证书（可选）
* 用户密钥交换，客户机将预备主密钥（随机数据）发送给服务器，__采用服务器的公钥加密__
* 对预备住密钥和随机数进行签名，证明拥有服务器公钥，可选
* 服务器提取预备主密钥，服务器和客户端同时从预备住主密钥计算主密钥（服务器密钥，客户端密钥）

#### 第四阶段；握手完成

* 客户端改变密码规格为主密钥
* 客户端结束握手
* 服务器端改变密码规格为主密钥
* 服务器结束握手

## 应用程序中的SSL

在浏览器中，各浏览器厂商最新的版本中基本都提供SSL的各种特性，包括绿色地址栏，证书链的验证等等。

在应用程序中（iOS，Android），如果与服务器的通讯采用SSL的http来通讯的话，基本上都没有问题，都是基于SSL协议来做，唯一需要做的是对服务器端的证书认证工作。原来由浏览器完成的这个工作，需要程序自己的代码来实现。

其实如果不做SSL证书验证的工作，已经能够进行安全的数据交换，但不能防止客户端连接不信任的站点。在程序中对需要的连接进行验证的过程叫做SSL Pinning技术。

### 安卓下的SSL

安卓系统下的SSL Pinning根据版本不同有不同的设计：

* 在4.2之前: 系统的Pinning采用安卓build-in的pin
* 在4.2之后: 从/data/misc/keychain下面读取pin文件

所以针对4.2之后版本的SSL Pinning添加自己新的Pin的方法是：

* Pins are stored in a simple text file, so we can just write one up and place it in the required location

就是说将Pin证书按照一定的格式放置在系统的一定的位置，程序对进行网络访问的时候就会把这些证书验证的过程也放进去。

但是在应用程序内的网络访问一般只有固定的一个或几个地址，所以不需要对所有系统允许的地址都能访问。在安卓系统中可以采用硬编码的方式将证书的验证过程写进代码里里面，正如下面的所说的一样：

* If you are initializing a TrustManagerFactory with your own keystore file that contains the issuing certificate(s) of your server's SSL certificate, you are already using pinning

* It means hard-coding the certificate known to be used by the server in the mobile application. The app can then ignore the device’s trust store and rely on its own, and allow only SSL connections to hosts signed with certificates stored inside the application.

### 安卓系统下面的SSL Pinning怎么做呢

安卓系统下进行的SSL Pinning的步骤一般可以分为三步：

1. 从服务器会获取证书
2. 将证书转换成固定的能被安卓证书验证系统验证的格式，并把文件放到合适的位置便于代码读取
3. 用证书初始化HttpClient，用于之后的网路连接（这里采用Apache的HttpClient库，不同的库下面大致的做法一致）

可以从这里参考：[sample code](https://github.com/ikust/hello-pinnedcerts)

### 代码细节

#### STEP 1. 从服务器获取证书（例如api.github.com）

```
    // 通过Openssl的工作，从服务器获取证书，开通SSL的服务器都有证书
    openssl s_client -showcerts -connect api.github.com:443 </dev/null 2>/dev/null|openssl x509 -outform PEM >mycertfile.pem
```

证书的有效格式在iOS和安卓下面有不同的格式。iOS是ces格式二安卓则为bks格式，但是都可以由pem文件转换而来。

### STEP 2. 装换成能被keystore使用的.bks格式文件，并将之防止在res/raw文件夹下

```
    // 获取转换的必须的包
    wget http://repo2.maven.org/maven2/org/bouncycastle/bcprov-ext-jdk15on/1.46/bcprov-ext-jdk15on-1.46.jar

    // 格式转化
    keytool -importcert -v -trustcacerts -file "mycertfile.pem" -alias ca -keystore "keystore.bks" -provider org.bouncycastle.jce.provider.BouncyCastleProvider -providerpath "bcprov-ext-jdk15on-1.46.jar" -storetype BKS -storepass testing
```

格式转化的过程中将证书转加密换成二进制文件，使用的加密密码在加载证书的时候需要用到。

### STEP 3. 用keystore文件初始化DefaultHttpClient

```
    // 创建keystore
    InputStream in = resources.openRawResource(certificateRawResource);//file name of res/raw
    keyStore = KeyStore.getInstance("BKS");
    keyStore.load(resourceStream, password);
```
```
     // 用keystore进行HttpClient的初始化
     HttpParams httpParams = new BasicHttpParams();
     SchemeRegistry schemeRegistry = new SchemeRegistry();
     schemeRegistry.register(new Scheme("https", new SSLSocketFactory(keyStore), 443));
     ThreadSafeClientConnManager clientMan = new ThreadSafeClientConnManager(httpParams, schemeRegistry);
     httpClient = new DefaultHttpClient(clientMan, httpParams);
```

这里产生的httpClient可以用于之后的通讯。如果SSL Pinning不通过，或者密码不正确的话，则会报出SSLPeerPinning之类的异常。

### 继续探讨

SSL Pinning讨论的完全是应用程序的安全问题。如果恶意将keystore文件替换的，其pinning的作用也就被破解。所以更好的方法是将二进制的文件写进代码里面，因为反编译代码要比替换keystore文件要难的多。

### 关于iOS

iOS的SSL Pinning验证机制与安卓系统的似乎不一样。这方面并没有仔细的去研究。

大致的区别在于iOS的验证过程需要实时的从服务器获取证书，然后将获取得来的证书与内置的证书进行二进制的比较来判断访问是否合法。

### 有用连接

* [1](http://nelenkov.blogspot.jp/2012/12/certificate-pinning-in-android-42.html)
* [2](https://www.infinum.co/the-capsized-eight/articles/securing-mobile-banking-on-android-with-ssl-certificate-pinning)

### 有用的库文件

* [stand alone lib](https://github.com/moxie0/AndroidPinning)
* [X509TrustManagerExtensions](http://developer.android.com/reference/android/net/http/X509TrustManagerExtensions.html)
* [TrustManagerFactory](http://docs.oracle.com/javase/jp/1.5.0/api/javax/net/ssl/TrustManagerFactory.html)
