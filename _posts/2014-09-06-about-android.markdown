---
layout: post
title:  "安卓相关"
date:   2014-07-30 22:44:57
categories: diar
tags: draft
---

## 1. android.app

* android.app.Activity - Activity
* android.app.AlertDialog - 警告对话框
  - AlertDialog.Builder(this).setMessage(message).setNeutralButton("OK", listener).create().show();

## 2. android.content

* android.content.DialogInterface
  - new DialogInterface.OnClickListener()

## 3. android.widget

* android.widget.Button
  - runButton = (Button) findViewById(R.id.button\_run);
  - runButton.setOnClickListener(new OnClickListener()) // android.view.View.OnClickListener
* android.widget.TextView
