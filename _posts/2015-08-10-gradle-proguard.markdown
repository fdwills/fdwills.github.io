---
layout: post
title:  "Gradle和proguard的配置例子"
date:   2015-08-10 12:44:57
categories: diary
tags: draft
---

## 前言

Gradle是个很好用的编译框架，在最新的android studio中也默认的支持了gradle的编译方法。在创建项目的时候选择使用gradle时候，就会在项目中生产gradle文件。

未经混淆的android代码可以通过很多工具反编译成可读的源码。进过混淆的jar文件中，变量，方法以及类的名称都会大幅的变化让人不能直观的读懂其中的含义。Progurad这个开源项目就是做的这个事情，讲代码进行混淆。

### Gradle

最重要的gradle文件是app的build.gradle文件，其中记录了编译打包android的方式。文件DSL的方式，简单记载了打包的各种配置：SDK版本，包依赖，签名设置以及混淆的配置等等。

一个典型build.gradle文件如下所示：

```
apply plugin: 'com.android.application'

android {
    // 项目参数
    compileSdkVersion 22
    buildToolsVersion "21.1.2"

    // 默认参数
    defaultConfig {
        applicationId "com.fdwills.sample"
        minSdkVersion 15
        targetSdkVersion 22
        versionCode 1
        versionName "1.0.0"
    }

    // 签名
    signingConfigs {
        releaseConfig {
            storeFile=file(project.properties.storeFile)
            storePassword=project.properties.storePassword
            keyAlias=project.properties.keyAlias
            keyPassword=project.properties.keyPassword
        }
    }

    // 混淆
    buildTypes {
        release {
            signingConfig signingConfigs.releaseConfig
            minifyEnabled true
            proguardFiles getDefaultProguardFile('proguard-android.txt'), 'proguard-rules.pro'
        }
    }

    // 渠道
    productFlavors {
        channel1 {
            applicationId = '包名'
        }
        channel2 {
            applicationId='包名'
        }
    }
}

// 包依赖关系
dependencies {
    compile fileTree(dir: 'libs', include: ['*.jar'])
    compile 'com.android.support:appcompat-v7:22.1.1'
    compile 'com.google.code.gson:gson:2.2.4'
    compile 'de.hdodenhof:circleimageview:1.3.0'
}
```

上面的签名部分的内容，在gradle.properties中记录如下类似keystore的信息:

```
storeFile=cer.jks
storePassword=passwd
keyAlias=alias
keyPassword=passwd
```

这时候可以通过如下命令打包:

```
./gradlew assembleRelease
```

如果需要安装到设备的话:

```
./gradlew assembleRelease installRelease
```

### Progurad

在build.gradle中设置minifyEnabled为true，表示启用proguard。

在[更新日志][New Build System]里面记载，开启proguard的函数由runProguard变更为minifyEnabled。旧版的gradle重会报找不到minifyEnabled的错误。

```
    buildTypes {
        release {
            signingConfig signingConfigs.releaseConfig
            minifyEnabled true
            proguardFiles getDefaultProguardFile('proguard-android.txt'), 'proguard-rules.pro'
        }
    }
```

在这里可以在两处配置你的proguard规则：

1. {ANDROID_SDK}/tools/proguard/proguard-android.txt文件
2. proguard-rules.pro文件

关于proguard文件的参考示例在[此处][Proguard Sample]。

可以参考里面的A complete Android application处的关于android程序的proguard的设置来完成对程序代码的混淆。

## 参考文档

* [New Build System](http://tools.android.com/tech-docs/new-build-system)
* [Proguard Sample](http://proguard.sourceforge.net/manual/examples.html)
