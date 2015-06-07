## 客户端状态

* OFFLINE: 用户处于离线状态(不响应任何消息)
* IDLE: 用户闲置状态(相应Call)
* CONNECTING: 用户拨号中状态(相应Ringing, OK, OKResponse, 超时检查)
* CHATING: 用户通话中状态(相应Bye, 超时检查)
* MATCHING: 匿名聊匹配中(相应TrigerCall, Call)

## 客户端定时任务

* CONNECTING的状态持续时间的超时检测
* MATCHING状态的加入池子的定时任务

## 电话时序

![xxx](call.png)


## 电话信令：

* Call: 拨号

```
call_id: wdw1213qw
from: 812232
to: 12121
sdp: 21211
ice_servers: ['123.223.22.12:9030?tcp=1']
```

* Trying: Call的服务器的回复

```
call_id: wdw1213qw
```

* Ringing: 对方客户端的回复

```
call_id: wdw1213qw
from: 12121
to: 812232
```

* OK: 对方客户端接受

```
call_id: wdw1213qw
from: 12121
to: 812232
sdp: 21211
ice_candidate: ['123.223.22.12:9030?tcp=1']
```

* Reject: 对方客户端拒绝接受

```
call_id: wdw1213qw
from: 12121
to: 812232
reason: busy/offline
```

* OKResponse: OK的回应

```
call_id: wdw1213qw
from: 812232
to: 12121
ice_candidate: ['123.223.22.12:9030?tcp=1']
```

* Bye: 结束通话

```
call_id: wdw1213qw
from: 812232
to: 12121
```

* ByeResponse: 结束通话的回应

```
call_id: wdw1213qw
from: 12121
to: 812232
```

## 匿名聊信令

* Join: 加入池子的命令

```
from: 12333
```

* leave: 离开池子的命令

```
from: 12333
```

## 控制信令

* TrigerCall: 向客户端发送命令，使他自动触发Call

```
target: 31122
```

## 客户端逻辑

1. 发起通话逻辑

* 改变状态为CONNECTIING
* 本地生产call_id，SDP，设置from为自己，to为对方，发送call消息
* 从此只接受此call_id的消息，拒绝一切call_id非本call_id的消息
* 设置定时器：5秒钟未收到Trying消息，10秒钟未收到Ringing或Reject消息重发Call，尝试两次挂断
* 收到理由为busy的Reject，发送未接来显离线消息
* 20秒未收到ok消息，挂断。发送未接来电离线消息。
* 此时主叫方获取可用ice服务器组列表，作为ice_servers 传递给对方

2. 接受通话逻辑

* 只有在IDLE状态才能接受call消息
* 收到call消息后，将call_id置为本地call_id，从此只接受只接受此call_id的消息，拒绝一切call_id非本call_id的消息
* 如果在CONNECTION状态多次收到同样的call_id的消息，返回同样的内容。如果收到其他call_id的消息，拒绝。
* 回复OK消息时设置定时器，如果10秒钟未收到okResponse，重发，尝试两次挂断。
* 此时根据主叫方传过来的ice_servers，初始化webrtc，在onicecandidate中向对方发送
exchange_info消息

3. 收到被叫回复的消息

* 收到被叫ok回复的时候，初始化webrtc，在onicecandidate中向对方发送exchange_info消息。
* 收到exchange_info消息的时候，解析并通过addIceCandidate()方法加入到实例中

4. 匿名聊逻辑

* 客户端进入MATCHING状态，发送Join命令。同时设置定时器，如果在MATCHING每10秒发送一次join
* 服务器匹配双方，随机向一方发送TrigerCall命令
* 和护短收到TrigerCall之后，进入通话逻辑，每个消息中添加call_type为wildcat
* 从此只接受此call_id的消息

4. 匿名聊被匹配逻辑

* 客户端在MATCHING状态中，只接受type为wildcat的call消息和trigerCall消息。

