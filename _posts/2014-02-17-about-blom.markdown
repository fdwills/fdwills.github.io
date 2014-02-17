---
layout: post
title:  "rails网络应用blom开发笔记"
date:   2014-02-17 20:44:57
categories: diary
tags: log
---

blom是一个图片上传，组织成类似于ppt的东西然后公开阅览的简单程序。

* 图片管理：图片的上传，修改，删除
* 文章管理：创建，修改，删除，添加图片

## 需要考虑清楚的部分

### 权限管理

1. 非登陆用户的权限
2. 登陆用户对自己的文件的权限
3. 登陆用户对他人的文件的权限
4. 管理员权限

* 不同用户通过不同namespace的controller控制
* 同一资源的访问提供不同的链接（为了controller的管理）
* 同一资源访访问提供不同的模板（为了简化模板中的if-else逻辑）

### 图片上传文件管理

1. 不同用户之间的文件访问不会冲突（存储文件规则）
2. 相同用户同一文件名的文件不会冲突（命名规则）
3. 用户删除图片后与文章关系的删除（防止空链接）
4. 用户删除文章后图片的不删除（防止影响其他文章）
5. 图片的版本空中（应对resize的需求）
6. 图片存储置于git管理之外（自动deploy的需求）

### 有用的链接

* [rails的手机端对应][cellphone]



[cellphone]: http://tobiascohen.com/articles/2012/07/01/creating-a-mobile-version-of-your-rails-site/

