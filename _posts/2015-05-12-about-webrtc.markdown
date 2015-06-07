---
layout: post
title:  "WebRTC及其相关信令协议"
date:   2015-05-10 12:44:57
categories: diary
tags: draft
---

## WebRTC

WebRTC是一个用于互联网语音的解决方案。基于将语音连接嵌入浏览器的思想而开发，由google主导，赢得了开发者的关注。利用webrtc技术，能够很简单的搭建一个网络电话服务。

WebRTC的基本流程当中，包含以下几个主要的概念：

1. offer: 通话的主叫方向被叫方发起的通话请求。
2. answer: 被叫方回应主叫方的对话请求
3. local descriptor: 本地描述符
4. remote descriptor: 远端描述符
5. sdp: 客户端的通信通道描述子
6. iceserver: 用于tcp穿透和udp语音传输的服务器

webrtc利用交换电话双方的网络情况（sdp），通过中间服务器，来打通双方的网络来通信。由于大多数的主机位于局域网之内，没有公网的ip，所有只有借助局域网穿透技术来达到在NAT之后的设备也能建立P2P直连的目的。局域网的穿透的成功率不是100%，这涉及到市面上的四种局域网的类型的问题。如果能打通的话，就能进行p2p直连的通话，如果不能打通的话，就只能借助于具有公网IP的服务器进行中转了。穿透和中转服务器就称为ICE服务器。其中rfc5776-turnserver是turn/stun协议的开源实现。其中turn部分负责穿透，stun部分负责在无法穿透的时候中转数据包。

![1]({{ site.url }}/assets/uml/normal-rtc.png)

一个webrtc建立的通话流程是这样的简单：首先主叫方设置本地描述符，最为自己的sdp，将sdp放入offer中，传给对方。对方收到offer后，提取其中的sdp，设置为远程描述符，同时获取自己的本地描述符作为sdp放入answer中，传给对方。双方这样互相交换了信息之后，就可以进行通话了。


## TURN/STUN

```
ICE，全名叫交互式连接建立（Interactive Connectivity Establishment）,一种综合性的NAT穿越技术，它是一种框架，可以整合各种NAT穿越技术如STUN、TURN（Traversal Using Relay NAT 中继NAT实现的穿透）。ICE会先使用STUN，尝试建立一个基于UDP的连接，如果失败了，就会去TCP（先尝试HTTP，然后尝试HTTPS），如果依旧失败ICE就会使用一个中继的TURN服务器(摘录)
```

webrtc进行局域网穿透，以及在穿透失败的时候进行服务器的语音中转都是依靠ice server来完成。ice server是一个实现TURN/STUN协议的服务器组。webrtc技术和局域网穿透技术是相关的技术，但是实现是分离的，而webrtc的作用则是负责为双方选择和协商使用的ice server服务。

## SDP

SDP是webrtc建立连接的关键因素。它定义了会话描述的统一格式，并且只是格式，并不负责压缩编码传输。这些都有信令完成。

普通电话和网络电话的区别是普通电话的硬件设备都遵循一个固定的制造模式。网络电话由于硬件的多样化，不同设备对音频和视频的支持不一样。所以就需要通话双方在通话之前告诉对方你能采取的编码，传输方式，然后协商。传输这些协商信息的介质就是SDP。

具体SDP的内容参考[此处](http://wenku.baidu.com/link?url=nWTrrPNJKacKvT3QBzrOSFB0S2JZw1dsY-DQoE2v_JL3JoeLQgQ6JTL-BxW9Ynjd2yW-DKpyT6S0PO6tohvQv7anc_JJBFhYgevHtnW1ILO)

offer和answer信令格式一样，一个典型的SDP是一个没有经过编码的文本，具有严格的格式。信息如下：

```
v=0
o=- 4388124623671028179 2 IN IP4 127.0.0.1
s=-
t=0 0
a=group:BUNDLE audio
a=msid-semantic: WMS ARDAMS
m=audio 9 RTP\/SAVPF 111 103 9 102 0 8 106 105 13 127 126
c=IN IP4 0.0.0.0
a=rtcp:9 IN IP4 0.0.0.0
a=ice-ufrag:gJ3cfMOwVJR9\/siA
a=ice-pwd:1WwGp7cOIp7eicrJDod\/Q2Zc
a=mid:audio
a=extmap:1 urn:ietf:params:rtp-hdrext:ssrc-audio-level
a=extmap:3 http:\/\/www.webrtc.org\/experiments\/rtp-hdrext\/abs-send-time
a=sendrecv
a=rtcp-mux
a=crypto:1 AES_CM_128_HMAC_SHA1_80 inline:czOi0cUQED7\/CQ4LzRT6daMW\/zME6mOr8qy8FjkG
a=rtpmap:111 opus\/48000\/2
a=fmtp:111 minptime=10; useinbandfec=1
a=rtpmap:103 ISAC\/16000
a=rtpmap:9 G722\/8000
a=rtpmap:102 ILBC\/8000
a=rtpmap:0 PCMU\/8000
a=rtpmap:8 PCMA\/8000
a=rtpmap:106 CN\/32000
a=rtpmap:105 CN\/16000
a=rtpmap:13 CN\/8000
a=rtpmap:127 red\/8000
a=rtpmap:126 telephone-event\/8000
a=maxptime:60
a=ssrc:1942841082 cname:NMUQ\/IGANm+EBYO7
a=ssrc:1942841082 msid:ARDAMS ARDAMSa0
a=ssrc:1942841082 mslabel:ARDAMS
a=ssrc:1942841082 label:ARDAMSa0
```

一个SDP氛围session部分和media部分。session部分用于描述本地的协议版本号，浏览器信息，传输模式等等。在这里session是上面SDP描述中开头的六行。vost四行分别表示version，origin，name，timezone必须存在且顺序不能改变，描述了协议版本等等。

```
v=0
o=- 4388124623671028179 2 IN IP4 127.0.0.1
s=-
t=0 0
a=group:BUNDLE audio
a=msid-semantic: WMS ARDAMS
```

从标记由m的行开始就是media部分。可能有多个部分，每个m节表示一个media信息。这里的media体如下。


```
m=audio 9 RTP\/SAVPF 111 103 9 102 0 8 106 105 13 127 126
c=IN IP4 0.0.0.0
a=rtcp:9 IN IP4 0.0.0.0
a=ice-ufrag:gJ3cfMOwVJR9\/siA
a=ice-pwd:1WwGp7cOIp7eicrJDod\/Q2Zc
a=mid:audio
a=extmap:1 urn:ietf:params:rtp-hdrext:ssrc-audio-level
a=extmap:3 http:\/\/www.webrtc.org\/experiments\/rtp-hdrext\/abs-send-time
a=sendrecv
a=rtcp-mux
a=crypto:1 AES_CM_128_HMAC_SHA1_80 inline:czOi0cUQED7\/CQ4LzRT6daMW\/zME6mOr8qy8FjkG
a=rtpmap:111 opus\/48000\/2
a=fmtp:111 minptime=10; useinbandfec=1
a=rtpmap:103 ISAC\/16000
a=rtpmap:9 G722\/8000
a=rtpmap:102 ILBC\/8000
a=rtpmap:0 PCMU\/8000
a=rtpmap:8 PCMA\/8000
a=rtpmap:106 CN\/32000
a=rtpmap:105 CN\/16000
a=rtpmap:13 CN\/8000
a=rtpmap:127 red\/8000
a=rtpmap:126 telephone-event\/8000
a=maxptime:60
a=ssrc:1942841082 cname:NMUQ\/IGANm+EBYO7
a=ssrc:1942841082 msid:ARDAMS ARDAMSa0
a=ssrc:1942841082 mslabel:ARDAMS
a=ssrc:1942841082 label:ARDAMSa0
```

media体中告诉了对方我可以使用的通信，编码压缩模式。具体不详述了从中可以看到音频处理的一些关键字：[opus](https://mf4.xiph.org/jenkins/view/opus/job/opus/ws/doc/html/group__opus__decoder.html)，G722等等。具体选择哪种传输模式，就有webrtc自己去选择了。

## WebRTC的信令

到这里，为什么webrtc需要信令就很自然了：在没有建立通信的情况下，怎么将sdp等信息传送给对方，并建立起一个正常的童话。当中涉及到两个内容：1，如何完成webrtc信息的传递；2，如何完成一个合理的通话流程。

信令是一个用于控制webrtc通话的信号的总称，包括控制如何开始通话，如何结束通话，不同的服务有着自己的逻辑。而webrtc本身没有实现通话的信令，原因是已有的成熟的信令方案有很多，包括主打电话的SIP协议，主打即时消息的XMPP协议。而webrtc想最大程度的复用已有的技术。

何以参考的例如SIP协议，在整合webrtc过程中，只需要将sdp信息整合到信令中传输就可以了。


### SIP协议

SIP协议是一个成熟的经过考验的网络通话协议。SIP协议的流程和包含的信令大致如下：

![1]({{ site.url }}/assets/uml/sip.png)

通过类似的传输过程，整合webrtc的信令传输，就能建立起简单的通话逻辑了。
