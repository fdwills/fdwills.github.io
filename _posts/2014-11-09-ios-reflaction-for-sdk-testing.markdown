---
layout: post
title:  "iOS的反射机制用于客户端SDK测试"
date:   2014-11-08 22:44:57
categories: diary
tags: draft
---

## 关于客户端SDK的假设

某部门开发了iOS的客户端SDK，准备对外提供。SDK的主要任务包括以下：

* 打包隐藏后端的URL
* 加密解密简历安全的链接
* 客户端缓存
* 集成iOS的IAP和PushNotification
* 其他

案例假设SDK的主要调用格式为：

[Interface_name func:param1 param2Desc:param2 param3Desc:param3 OnSuccess:onSuccess OnError:onError]

* 服务器端默认是RESTFul风格的设计
* Inteface_name相当于功能的模块名称，如payment之类
* func是模块的方法名称，如purchase之类
* params是参数，如product_id，quantity之类的拥有基本类型或者NS类型的参数
* OnSuccess为返回状态2xx时候的回调函数，处理成功时候的句柄
* OnError为返回状态为2xx以外时候的回调函数，处理失败时候的句柄

于是问题是，当服务急速扩张的时候，当服务器有大量的模块和大量的方法的时候，该如何做测试？
从测试的等级上看，可以分为三个层次的测试：

* 服务器测试：直接采用curl等工具对服务器进行命令行的测试
* SDK测试：通过反射的机制对包装好的SDK进行批量测试
* 应用程序测试：讲SDK集成真实的应用程序中进行测试

这里说的是用反射机制对iOS的SDK进行批量测试的问题。

## 测试框架设计

测试的主要目的是测试SDK是不是会使应用崩溃，SDK是不是能正常连接服务器，SDK取回的结果是不是正确。

于是设计测试的json如下，以payment purchase为例，接受product_id和quantity两个参数

```json
{
	"tests": [
		{
			"methods": "Payment purchase:quantity:onSuccess:onError:"
			"args": [101, 1]
		},
		{
			"methods": "Payment purchase:quantity:onSuccess:onError:"
			"args": [102, 1]
		},
		{
			"methods": "Payment purchase:quantity:onSuccess:onError:"
			"args": [103, 1]
		},
		{
			"methods": "Payment purchase:quantity:onSuccess:onError:"
			"args": [104, 1]
		}
	]
}
```

上面的例子中test里面的每一项表示一次调用，methods里面的是函数的signature，args是传入的参数。原则上onSuccess和onError也是应该传入的函数参数，这里默认传入的这两个参数是讲返回值输出到界面的函数。

于是上面的例子里面其实是包含了四个test case。这篇post关于测试的设计大概就是这样：

1. 通过json传递signature和参数
2. 通过某种方式将json测试用例传到模拟器或者真机上
3. 通过反射机制来调用函数执行测试用例

* 关于如何将json传到机器里面，有一些方法。android可以通过usb线push一个文件到设备当中，iOS的话可以通过http的方式去从网络上获取测试文件。
* 多个测试用例的测试实际上是要执行一系列测试用例，这里面job的编写这里略过。
* onSuccess与onError的实际代码，这里略过，于你app界面的实现结构有关。

## 反射的相关代码

于是乎这就变成了如何从method和args来执行某个函数的问题

核心代码如下：

```objc
- (void)exec:(NSString)className method:(NSString)methodName args:(NSArray)args {
    // set
    NSInvocation *invocation;
    NSMethodSignature *signature;
    @try {
        Class classType = NSClassFromString(className);
        SEL method = NSSelectorFromString(methodName);
 
        signature =
            [classType methodSignatureForSelector:method];
        invocation = [NSInvocation invocationWithMethodSignature:signature];
        [invocation setSelector:method];
        [invocation setTarget:classType];
    }
    @catch (id exception) {
        // 当不存在此class或此method时候，做自己的异常处理
        return;
    }
 
    // success delegate
    OnSakashoSuccess successDelegate = ^(NSString *data) {
        // 实现自己的delegate
    };
 
    // error delegate
    OnSakashoError errorDelegate = ^(SakashoError *error) {
      // 实现自己的delegate
    };
 
    // parameter exception
    @try {
        // set parameter
        int argNo = 2;
        // 对参数列表中的项目进行便利，载入函数对应的位置中
        for (id arg in args) {
            if ([arg isKindOfClass:[NSString class]]) {
                NSString *strArg = arg;
                [invocation setArgument:&strArg atIndex:argNo];
            } else if ([arg isKindOfClass:[NSArray class]]) {
                NSArray *arrArg = arg;
                [invocation setArgument:&arrArg atIndex:argNo];
            } else if ([arg isKindOfClass:[NSNumber class]]) {
                // 如果此时args里面的是类似101这样的数字，那么此时函数的参数可能是int和NSNumber
                // may be int or NSNumber
                // 获得参数的encode做对应处理
                const char *type = [signature getArgumentTypeAtIndex:argNo];
                if (strcmp(type, @encode(int)) == 0) {
                    int num = [arg intValue];
                    [invocation setArgument:&num atIndex:argNo];
                } else {
                    NSNumber *numArg = arg;
                    [invocation setArgument:&numArg atIndex:argNo];
                }
            } else if (arg == (id)[NSNull null]) {
                id nilArg = nil;
                [invocation setArgument:&nilArg atIndex:argNo];
            } else {
                break;
            }
            argNo++;
        }
 
        // add onSuccess
        [invocation setArgument:&successDelegate atIndex:argNo++];
        // add onError
        [invocation setArgument:&errorDelegate atIndex:argNo++];
    }
    @catch (id exception) {
        // 参数加载异常时候的处理实现
        return;
    }
 
    // run exception
    @try {
        [invocation invoke];
    }
    @catch (id exception) {
        // 执行异常的处理实现
        return;
    }
}
```

## 总结

主要想写两点

1. 处理异常。在json的文件当中写错了就很容易出现异常，所以要处理多种情况的异常。
2. 参数裂变的处理。主要思路为从参数列表估计参数的类型，单有一些特殊的情况需要处理。

祝大家好运。
