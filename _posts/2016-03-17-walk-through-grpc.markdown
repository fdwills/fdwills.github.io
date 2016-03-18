---
layout: post
title:  "gRPC + python笔记"
date:   2016-03-17 12:44:57
categories: diary
tags: draft
---

## 环境

* os: OSX EI Capitan
* python: 2.7.11

## 安装

* 安装protobuff

* 安装gRPC

```
pip install grpcio
```

### 问题1: grpc_python_plugin缺失

源码编译安装

```
git clone https://github.com/grpc/grpc
git submodule update --init
make grpc_python_plugin
```

### 问题2： https://github.com/grpc/grpc/issues/5280

```
添加以下参数重新build python
--enable-unicode=ucs4
```

#### 重新build python

* 下载python2.7.11 
* ./configure --enable-shared --prefix=/usr/local --enable-unicode=ucs4
* make && make altinstall
* chmod -v 755 /usr/local/lib/libpython2.7.so.1.0
* ln -s /usr/local/lib/libpython2.7.so.1.0 /lib64/
* 删除原来虚拟环境
* 重新生成虚拟环境
* pip install grpcio

【参考】

* [http://qiita.com/iorionda/items/b11bba878dbeece412e7](http://qiita.com/iorionda/items/b11bba878dbeece412e7)
* [http://www.linuxfromscratch.org/blfs/view/svn/general/python2.html](http://www.linuxfromscratch.org/blfs/view/svn/general/python2.html)

## 运行测试代码

* 下载测试代码: git clone https://github.com/grpc/grpc.git
* cd examples/python/helloworld/
* ./run_codegen.sh
* python greeter_server.py
* python greeter_client.py

## 开发步骤

1. 定义.proto
2. 生成_pb.py接口代码
3. 实现接口
4. 实现服务器代码

## 参考文档

* [http://qiita.com/ko2ic/items/6e140c8e1a3568ced2ee](http://qiita.com/ko2ic/items/6e140c8e1a3568ced2ee)
* [http://satoshun.github.io/2015/05/dagger2/](http://satoshun.github.io/2015/05/dagger2/)

