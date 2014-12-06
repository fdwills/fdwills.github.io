---
layout: post
title:  "Jenkins用于android程序自动化的尝试"
date:   2014-12-06 22:44:57
categories: diary
tags: draft
---

## Android程序的自动化打包

想将android的程序用jenkins自动打包，用于开发测试。建立的过程与web的过程差不多，不同的是需要解决java sdk，android sdk以及系统版本之间的各种不兼容问题。

这里采用的平台是：

* CentOS 6.2 x86-64
* Eclipse
* Ant 1.9
* JDK1.7.0
* 以及从google官网下的最新的x86-64的adt

如果以上版本问题都完全解决的话，build的步骤就很简单：

1. android update project --path .
2. ant clean / ant debug / ant release

### 在环境配置的过程中可能遇到的问题

#### 1. 无法找到android命令

* 原因：android sdk下的工具目录未被加入$PATH中
* 解决方法：导出ANDROID\_HOME到环境变量中，并

```sh
export PATH=$ANDROID_HOME/platform-tools:$ANDROID_HOME/tools:$PATH
```

#### 2. 没有target错误

* 原因：下载的adt里面没有target
* 解决方法：命令行下升级安装相关sdk，tools和platform-tool

```sh
android list sdk --all
android update sdk -u -a -t <package no.>
```

#### 3. yum安装的ant版本不够

* 原因：android会提示ant 1.7版本
* 解决策略：卸载系统的ant，从官网下载最新的ant版本，解压后设置ANT\_HOME，并

```sh
export PATH=$ANT_PATH/bin:$PATH
```

#### 4. android SDK编译出错

* 原因：64位系统编译android需要i686的库文件
* 解决策略：安装一下包

```sh
yum install glibc.i686 libstdc++.i686 ncurses-libs.i686 zlib.i686
```

参考：[http://pythonlife.seesaa.net/article/225399632.html](http://pythonlife.seesaa.net/article/225399632.html)

#### 5. libstdc++.i686无法安装，与系统现有版本冲突的错误

* 原因：libstdc++.i686与libstdc++.x86-64的冲突
* 解决方案：yum update

#### 6. ant debug提示找不到某resources

* 原因：project.properties的依赖问题没有解决
* 解决方案：手动外接库依赖问题

#### 7. Jenkins提示JAVA\_HOME未定义

* 原因：jeknins有自己的环境变量系统
* 解决方案：手动导出JAVA\_HOME，将之前的定义的变量在jenkins里导入
