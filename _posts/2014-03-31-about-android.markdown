---
layout: post
title:  "android"
date:   2014-03-31 20:44:57
categories: draft
tags: android
---

## ant

### 列出平台列表

android list targets

### 创建

android create project --target <target-id> --name MyFirstApp --path <path-to-workspace> MyFirstApp --activity MainActivity --package com.example.myfirstapp

### 更新项目（检查build.xml）

android update project --target android-3 --name AntTest --path /home/homer/workspace/AntTest

### 编译项目

ant debug

### 创建徐牛设备

android create avd -n name -t targetid

### 列出虚拟设备列表

android list avd

### 启动模拟器

emulator -avd AVD-1.5

### 安装apk

adb install bin/AntTest-debug.apk

### 安装apk


