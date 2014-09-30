---
layout: post
title:  "GooglePlay的消息推送"
date:   2014-07-30 22:44:57
categories: diary
tags: draft
---

## 关于google的消息推送服务

运用google的消息推送服务需要注意的一些问题。

### 0. 不能使用google的消息推送服务的几种情况

1. android版本2.3之前
2. 没有安装google play必要的package

### 1. 必要的设置

google的push notification（google cloud messing）服务所需要的配置相对苹果的简单很多，不需要复杂的p12文件的生成过程。对于客户端来说，只需要一个由google console生成的project id。而对于自己的服务器来说，只需要这个project下面生成的server key即可。

project id作为sender id用来向gcm请求regeistion id；而server key被自己的服务器用来向google注册regeistion id以及发送消息。

不管是使用aws之类的中间服务还是直接向google发消息，都需要server key，而这个server key并没有苹果那样有sandbox和product之分。

### 2. 关于regeistion id的获取（与iOS的device\_token相当）

在发布google-play-services\_lib之前的消息推送服务的regeistion id的获取，建议在可能早的时候获得regeistion id。google-play-services\_lib也尽可能在早的时候发送注册的intent。

对于自己实现的receiver，首先需要声明必要的权限，这部分的设置在google服务的使用说明中友明确的写出。
配置好的manifest大致多了以下一些配置。

```xml
    <uses-permission android:name="android.permission.GET_ACCOUNTS" />
    <uses-permission android:name="android.permission.VIBRATE" />
    <uses-permission android:name="android.permission.WAKE_LOCK" />
    <uses-permission android:name="com.google.android.c2dm.permission.RECEIVE" />
    <permission
        android:name="{your package name}.permission.C2D_MESSAGE"
        android:protectionLevel="signature" />

    <uses-permission android:name="{your package name}.permission.C2D_MESSAGE" />
    <!-- end added for gms -->

    <application
        android:allowBackup="true"
        android:icon="@drawable/ic_launcher"
        android:label="@string/app_name"
        android:theme="@style/AppTheme" >

        <receiver
            android:name="{your receiver class}"
            android:permission="com.google.android.c2dm.permission.SEND" >

            <!-- Receive the actual message -->
            <intent-filter>
                <action android:name="com.google.android.c2dm.intent.RECEIVE" />

                <category android:name="{your package name}" />
            </intent-filter>
            <!-- Receive the registration id -->
            <intent-filter>
                <action android:name="com.google.android.c2dm.intent.REGISTRATION" />

                <category android:name="{your package name}" />
            </intent-filter>
        </receiver>

        <service android:name=".GcmIntentService" />
```

对于采用google-play-services_lib的情况请参照里面的说明。

自己实现的receiver的话，大致是以下逻辑：

* 如果是com.google.android.c2dm.intent.REGISTRATION的action，则将regeistion id写入sharedPreference。
* 如果是com.google.android.c2dm.intent.RECEIVE则按情况显示消息。

### 3. 关于消息的动作

获得推送消息的时候，应用程序属于何种状态，在这种状态下应用程序应该作何处理，都可以考虑。

一般考虑的是应用程序在前台或者后台，例如在前台则toast显示，在后台则在push notification的bar里面显示等等。

在这种情况下，需要手动添加代码在onPasuse和onResume里面来记录activity的状态，在对应com.google.android.c2dm.intent.RECEIVE的时候检查这些状态做对应处理。

同时，在用户点击推送消息打开activity或者将activity调至前台时，会调用activity的onNewIntent函数。在这个函数里面可以统计用户打开push的开封率等等。goolge文档中记载，如果要是onNewIntent有效，必须将activity的start mode设置成singleTop，即存在activity在activityManger顶部的时候激活activity而不是新建。实验验证singleTask的mode也可以做到这一点。

### 4. 关于通知栏里消息的显示

一般的google通知栏可显式的要素有6个。其中有大图标和小图标两种。

大图标是采用bitmap的方式传递，于是可以从url连接获取或者从drawable中获取。

小图标采用的是drawable的ID。

当只设置了小图标或者大图标无法获取是，小图标取代大图标的位置显示，原来小图标的位置则不显示。

当大小图标都无法获取的时候，则不会显示。

## 以上

作为memo。iOS的p12认证文件的程序比较复杂，而对于推送消息的控制则比较简单。在此略。
