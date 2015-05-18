---
layout: post
title:  "Opencv，SVM相关库在centos的安装"
date:   2015-05-10 12:44:57
categories: diary
tags: draft
---

## 前言

最近做到一个人脸识别图像切割的项目，需要安装cv的python处理库，以及ml的相关库。这里采用的时opencv和svm库。

* 环境，centos6.5（阿里云）

## 安装Python 2.7.8

```bash
yum groupinstall "Development tools"
yum install zlib-devel bzip2-devel openssl-devel ncurses-devel sqlite-devel readline-devel tk-devel gdbm-devel db4-devel libpcap-devel

# 安装opencv可能需要的库
yum install gcc g++ gtk+-devel libjpeg-devel libtiff-devel jasper-devel libpng-devel cmake unzip
```

```bash
wget https://www.python.org/ftp/python/2.7.8/Python-2.7.8.tar.xz
tar xf Python-2.7.8.tar.xz
cd Python-2.7.8
./configure --enable-shared --prefix=/usr/local

make && make altinstall #su

# 检查以下文件
# /usr/local/lib/libpython2.7.so.1.0
# /usr/local/lib/libpython2.7.so
```

## 安装虚拟环境

```bash
wget https://bootstrap.pypa.io/ez_setup.py
python2.7 ez_setup.py
easy_install-2.7 pip

pip2.7 install virtualenv
virtualenv ~/env
ln -s /usr/local/lib/libpython2.7.so.1.0 ~/peiwo/env/lib/libpython2.7.so.1.0
ln -s /usr/local/lib/libpython2.7.so ~/peiwo/env/lib/libpython2.7.so
```

## 安装opencv

```bash
wget http://sourceforge.net/projects/opencvlibrary/files/opencv-unix/2.4.11/opencv-2.4.11.zip
unzip opencv-2.4.11.zip

cd opencv-2.4.11
mkdir build
cd build

export PYTHON_PREFIX=/usr/local
cmake ../ -DCMAKE_BUILD_TYPE=RELEASE \
-DCMAKE_INSTALL_PREFIX=/usr/local \
-DBUILD_EXAMPLES=ON \
-DWITH_EIGEN=ON \
-DBUILD_NEW_PYTHON_SUPPORT=ON \
-DINSTALL_PYTHON_EXAMPLES=ON \
-DPYTHON_EXECUTABLE=$PYTHON_PREFIX/bin/python2.7 \
-DPYTHON_INCLUDE_DIR=$PYTHON_PREFIX/include/python2.7/ \
-DPYTHON_LIBRARY=$PYTHON_PREFIX/lib/libpython2.7.so.1.0 \
-DPYTHON_NUMPY_INCLUDE_DIR=$PYTHON_PREFIX/lib/python2.7/site-packages/numpy/core/include/ \
-DPYTHON_PACKAGES_PATH=$PYTHON_PREFIX/lib/python2.7/site-packages/ \
-DBUILD_PYTHON_SUPPORT=ON
make
sudo make install
```

## 测试

```bash
source ~/env
python
>>import cv2
```

## 安装svm库

```bash
yum -y install gcc gcc-c++ numpy python-devel scipy
pip2.7 install SciPy scikit-learn
```


## Dockerfile

```
# vim:set ft=dockerfile:
FROM centos:7

ENV PYTHON_PREFIX /usr/local

RUN yum update && yum groupinstall -y "Development tools" \
    && yum install -y zlib-devel bzip2-devel openssl-devel ncurses-devel sqlite-devel readline-devel tk-devel gdbm-devel db4-devel libpcap-devel \
    && yum install -y gcc g++ gtk+-devel libjpeg-devel libtiff-devel jasper-devel libpng-devel cmake unzip

RUN mkdir -p /open_software
RUN cd /open_software && curl -# -o Python-2.7.8.tar.xz https://www.python.org/ftp/python/2.7.8/Python-2.7.8.tar.xz \
    && tar xf Python-2.7.8.tar.xz \
    && cd Python-2.7.8 \
    && ./configure --enable-shared --prefix=$PYTHON_PREFIX \
    && make && make altinstall

RUN cd /open_software && curl -# -o ez_setup.py https://bootstrap.pypa.io/ez_setup.py \
    && python2.7 ez_setup.py \
    && easy_install-2.7 pip

RUN pip2.7 install numpy

RUN yum -y install gcc gcc-c++ numpy python-devel scipy
RUN pip2.7 install SciPy scikit-learn

RUN cd /open_software && curl -# -o http://sourceforge.net/projects/opencvlibrary/files/opencv-unix/2.4.11/opencv-2.4.11.zip \
    && unzip opencv-2.4.11.zip \
    && cd opencv-2.4.11 \
    && mkdir build \
    && cd build \
    && cmake ../ -DCMAKE_BUILD_TYPE=RELEASE \
       -DCMAKE_INSTALL_PREFIX=/usr/local \
       -DBUILD_EXAMPLES=ON \
       -DWITH_EIGEN=ON \
       -DBUILD_NEW_PYTHON_SUPPORT=ON \
       -DINSTALL_PYTHON_EXAMPLES=ON \
       -DPYTHON_EXECUTABLE=$PYTHON_PREFIX/bin/python2.7 \
       -DPYTHON_INCLUDE_DIR=$PYTHON_PREFIX/include/python2.7/ \
       -DPYTHON_LIBRARY=$PYTHON_PREFIX/lib/libpython2.7.so.1.0 \
       -DPYTHON_NUMPY_INCLUDE_DIR=$PYTHON_PREFIX/lib/python2.7/site-packages/numpy/core/include/ \
       -DPYTHON_PACKAGES_PATH=$PYTHON_PREFIX/lib/python2.7/site-packages/ \
       -DBUILD_PYTHON_SUPPORT=ON \
    && make \
    && make install

VOLUME /script

COPY docker-entrypoint.sh /

COPY bin/requirements.txt /
RUN pip2.7 install -r /requirements.txt

ENTRYPOINT ["/docker-entrypoint.sh"]
```
