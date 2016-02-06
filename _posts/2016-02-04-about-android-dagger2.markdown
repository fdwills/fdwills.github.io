---
layout: post
title:  "安卓dagger2"
date:   2016-02-04 12:44:57
categories: diary
tags: draft
---

## 前言

什么是依赖性。简单地说依赖性指代码里面两个模块（在面向对象语语言里面就是两个类）之间的耦合关系，一般是指一个雷要使用另外一个类做一些事情。

* 依赖性是危险的。

从高层（使用者）到低层（被使用）的依赖关系是危险的。原因是一旦我们想要改变其中的某个模块，我们需要修改双方的代码。解决这个问题的方法就是反向依赖。


Dependency Injection(依赖性注入)简称DI，著名的有square开发的dagger1以及google开发的dagger2.

```
In software engineering, dependency injection is a software design pattern that implements inversion of control for resolving dependencies.
A dependency is an object that can be used (a service). 
An injection is the passing of a dependency to a dependent object (a client) that would use it. 
The service is made part of the client's state. Passing the service to the client,
rather than allowing a client to build or find the service, is the fundamental requirement of the pattern.
```

这是wiki上关于依赖性注入的解释：依赖性注入是一种实现了依赖性关系反转约束的软件设计模式。依赖性是一个可以被使用的对象（服务）。注入则是吧一个依赖性传递给一个可能使用这种依赖性的对象（客户端）。这个服务被当成是客户端的状态。把服务传给客户端，而不是允许客户端生成或者找到这个服务，是这个模式的关键需求。

依赖性注入允许软件设计遵循依赖反转原则。客户端委托外部代码（注入者）提供给他依赖性的关系。客户端不允许调用注入者的代码。注入代码构造了服务然后让客户端注入他们。这意味着客户端不需要知道注入代码的具体实现，不需要知道服务的结构，不需要知道他具体是使用了哪个具体的服务。客户端只要知道服务接口。

关于依赖性的定义，有下面一个例子简单的解释了。

[Android: Dagger2でDIをする. 基本編 Part1](http://satoshun.github.io/2015/05/dagger2/)

依赖性注入有什么好处呢？这边文章里面给出了解释([链接](https://github.com/codepath/android_guides/wiki/Dependency-Injection-with-Dagger-2))

* 简单的对共享实例的访问。

就像butteknife库能够简单的对view，handler和资源进行访问一样，Dagger2提供了获取共享实例引用的方法。例如，一旦我们定义了一个比如MyTwitterApiClient或者对SharedPrefence，可能还有dbAccessor，我们能够通过简单定义一个@Inject注解

```java
public class MainActivity extends Activity {
   @Inject MyTwitterApiClient mTwitterApiClient;
   @Inject SharedPreferences sharedPreferences;

   public void onCreate(Bundle savedInstance) {
       // assign singleton instances to fields
       InjectorClass.inject(this);
   }
```

* 简单的配置复杂的依赖关系。

你的对象的创建是有一个隐式的顺序的，Dagger2通过遍历依赖关系图生成能够方便的理解和追踪的代码，这样大大简化了你手动的编写代码来获取引用以及将他传递给依赖他的对象。同样也方便你对模块的重构，因为你能够专注于模块内的逻辑，不需要去想模块应该按照怎么样的顺序创建出来。

* 便于测试

* 实例范围

依赖注入不仅能够管理整个应用生命周期的实例，同时也能定义一个在较短的生命周期中存在的实例，利于用户的session和activity的生命周期等。

然而Dagger2的缺点就是，学习成本太高，理解太困难了。。。。

下面的例子是一个在软件内全局实例的例子，

```java
OkHttpClient client = new OkHttpClient();

// Enable caching for OkHttp
int cacheSize = 10 * 1024 * 1024; // 10 MiB
Cache cache = new Cache(getApplication().getCacheDir(), cacheSize);
client.setCache(cache);

// Used for caching authentication tokens
SharedPreferences sharedPrefeences = PreferenceManager.getDefaultSharedPreferences(this);

// Instantiate Gson
Gson gson = new GsonBuilder().create();
GsonConverterFactory converterFactory = GsonConverterFactory.create(Gson);

// Build Retrofit
Retrofit retrofit = new Retrofit.Builder()
                                .baseUrl("https://api.github.com")
                                .addConverterFactory(converterFactory)
                                .client(client)  // custom client
                                .build();
```

这些例子在使用的时候，都可以通过注入来简化代码和逻辑。

### Dagger2

Dagger2有以下一些特征：

#### @Inject

依赖性声明。

#### @Module

声明提供依赖性方法的类。

#### @Provide

放在模块内，声明对Dagger提供怎样的依赖性。

#### @Component

@Inject和@Module之间的桥，提供被定义的所有类型的接口。

#### @Scope

#### @Qualifier

### 如何一步步导入Dagger2

#### Step1. gradle

在build.gradle中追加用于生成注入代码的配置：

```java
 buildscript {
     repositories {
         jcenter()
     }
     dependencies {
         classpath 'com.android.tools.build:gradle:1.3.0'
+        classpath 'com.neenbedankt.gradle.plugins:android-apt:1.8'
     }
 }
```

在app/build.gradle中导入dagger2的库

```java
 apply plugin: 'com.android.application'
+apply plugin: 'com.neenbedankt.android-apt'

 android {
     compileSdkVersion 23
     buildToolsVersion "23.0.1"

     defaultConfig {
         applicationId "com.sample.dagger2"
         minSdkVersion 15
         targetSdkVersion 23
         versionCode 1
         versionName "1.0"
     }
     buildTypes {
         release {
             minifyEnabled false
             proguardFiles getDefaultProguardFile('proguard-android.txt'), 'proguard-rules.pro'
         }
     }
 }

 dependencies {
     compile fileTree(dir: 'libs', include: ['*.jar'])
     testCompile 'junit:junit:4.12'
     compile 'com.android.support:appcompat-v7:23.1.0'
     compile 'de.greenrobot:eventbus:2.4.0'
     compile 'com.mcxiaoke.volley:library:1.0.19'
     compile 'com.jakewharton:butterknife:7.0.1'

+    compile 'com.google.dagger:dagger:2.0.2'
+    apt 'com.google.dagger:dagger-compiler:2.0.2'
+    provided 'org.glassfish:javax.annotation:10.0-b28'
 }
```

#### Step2. 制作Module类

Module类是包含@Provides方法的类，@Provides方法的返回值就是被注入的时候的实例。例如，@Inject Context context的时候就调用下面provideApplicationContext方法。

命名规范是@Provides方法以provide单词开头，模块的名字以Module结尾。

```java
// AppModule.java
import android.app.Application;
import android.content.Context;

import javax.inject.Singleton;

import dagger.Module;
import dagger.Provides;

@Module
public class AppModule {
    private final Application application;

    public AppModule(Application application) {
        this.application = application;
    }

    @Provides
    @Singleton
    Context provideApplicationContext() {
        return application.getApplicationContext();
    }
}
```

每个layer单独生成一个模块类比较清晰一点。@Provides方法的参数由被注入的实例提供。

```
// InfraLayerModule.java

@Module
public class InfraLayerModule {
    @Provides
    public WeatherRepository provideWeatherRepository(Context context) {
        return new WeatherRepository(context);
    }
}
```

```
// AppLayerModule.java

@Module
public class AppLayerModule {
    @Provides
    public WeatherFacade provideWeatherFacade(WeatherRepository repository) {
        return new WeatherFacade(repository);
    }
}
```

#### Step3. Component接口

Dagger1和Dagger2的区别的一点就是Component类。Component是从Dagger的ObjectGraph演变过来的，不过这都不重要了。Dagger2中，Component的实现类是自动生成的。

Component类是为了@Inject声明的时候注入类被@Module里的@Provides声明的方法的返回实例的里面实行注入而产生的类。

```java
// AppComponent.java
import javax.inject.Singleton;

import dagger.Component;
import ko2ic.dagger2.application.AppLayerModule;
import ko2ic.dagger2.infrastructure.InfraLayerModule;
import ko2ic.dagger2.ui.activity.SecondActivity;

@Singleton
@Component(modules = {InfraLayerModule.class, AppLayerModule.class, AppModule.class})
public interface AppComponent {
    void inject(SecondActivity activity);
}
```

* 例如在Component里里面声明Foo getFoo();的话，就和Dagger1里面的objectGraph.get(Foo.class);效果一样。
* 声明void inject(Baz baz);就和Dagger1里面声明objectGraph.inject(baz); 是一样的。

#### Step4. Application子类

生成Application类的子类，这是为了能在Activity中构造Component。

```java
// AppApplication.java
public class AppApplication extends Application {

    private AppComponent applicationComponent;

    @Override
    public void onCreate() {
        super.onCreate();
        initializeInjector();
    }

    private void initializeInjector() {
        applicationComponent = DaggerAppComponent.builder()
                .appModule(new AppModule(this))
                .build();
    }

    public AppComponent getApplicationComponent() {
        return applicationComponent;
    }
}
```

#### Step5. 依赖性注入

把有实例的地方都变成依赖性注入。

* 不依赖安卓的Facade用POJO的形式
* 单体测试的时候Module简单的变为Mock类

```
 public class SecondActivity extends AppCompatActivity {

-     private WeatherFacade facade; 
+     @Inject
+     WeatherFacade facade;

      @Bind(R.id.editText)
      EditText editText;

      @Bind(R.id.button)
      Button button;

      @Override
      protected void onCreate(Bundle savedInstanceState) {
         super.onCreate(savedInstanceState);
         setContentView(R.layout.activity_second);
         ButterKnife.bind(this);
+        getApplicationComponent().inject(this);
         button.setOnClickListener(new View.OnClickListener() {
             @Override
             public void onClick(View v) {
-                 facade = new WeatherFacade(getApplicationContext());
                  facade.fetchWeahter(editText.getText().toString());
             }
         });
     }
+     private AppComponent getApplicationComponent() {
+         return ((AppApplication) getApplication()).getApplicationComponent();
+    }
 public class WeatherFacade {

     private WeatherRepository repository;

-    private Context context;

-    public WeatherFacade(Context context){
-        this.context = context;
+    @Inject
+    public WeatherFacade(WeatherRepository repository){
+        this.repository = repository;
     }

     public void fetchWeahter(String cityCode){
-        repository = new WeatherRepository(context);
         repository.fetchWeather(cityCode);
     }
 }
 public class WeatherRepository {

     private Context mContext;

+    @Inject
     public WeatherRepository(Context context) {
         mContext = context;
     }
```

另外，关于Field Injection和Constractor Injection这两者方式，可以参考[这里](http://www.petrikainulainen.net/software-development/design/why-i-changed-my-mind-about-field-injection/), 不做过深的探讨。

## 参考文档

* [http://qiita.com/ko2ic/items/6e140c8e1a3568ced2ee](http://qiita.com/ko2ic/items/6e140c8e1a3568ced2ee)
* [http://satoshun.github.io/2015/05/dagger2/](http://satoshun.github.io/2015/05/dagger2/)

