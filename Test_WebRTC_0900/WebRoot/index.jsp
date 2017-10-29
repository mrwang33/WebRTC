<%@ page language="java" import="java.util.*" pageEncoding="UTF-8"%>
<%
	String path = request.getContextPath();
	String basePath = request.getScheme() + "://"
			+ request.getServerName() + ":" + request.getServerPort()
			+ path + "/";
%>

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
<base href="<%=basePath%>">

<title>My JSP 'index.jsp' starting page</title>
<meta http-equiv="pragma" content="no-cache">
<meta http-equiv="cache-control" content="no-cache">
<meta http-equiv="expires" content="0">
<meta http-equiv="keywords" content="keyword1,keyword2,keyword3">
<meta http-equiv="description" content="This is my page">
<!--
	<link rel="stylesheet" type="text/css" href="styles.css">
	-->

<script type="text/javascript">
	var socket =new WebSocket("wss://192.168.1.100:8080/Test_WebRTC_0900/games");
	var isCaller = window.location.href.split('#')[1];
	
	socket.onopen = function() {
		if(isCaller==null||isCaller==undefined) {
			socket.send("new user");
		}
	};
	// stun和turn服务器
	var iceServer = {
		"iceServers" : [ {
			"url" : "stun:stun.l.google.com:19302"
		}, {
			"url" : "turn:numb.viagenie.ca",
			"username" : "webrtc@live.com",
			"credential" : "muazkh"
		} ]
	};

	// 创建PeerConnection实例 (参数为null则没有iceserver，即使没有stunserver和turnserver，仍可在局域网下通讯)
	var pc = new webkitRTCPeerConnection(null);

	// 发送ICE候选到其他客户端
	pc.onicecandidate = function(event) {
		if (event.candidate !== null) {
			socket.send(JSON.stringify({
				"event" : "_ice_candidate",
				"data" : {
					"candidate" : event.candidate
				}
			}));
		}
	};

	// 如果检测到媒体流连接到本地，将其绑定到一个video标签上输出
	pc.onaddstream = function(event) {
		document.getElementById('vid2').src = URL
				.createObjectURL(event.stream);
	};

	// 发送offer和answer的函数，发送本地session描述
	var sendOfferFn = function(desc) {
		pc.setLocalDescription(desc);
		socket.send(JSON.stringify({
			"event" : "_offer",
			"data" : {
				"sdp" : desc
			}
		}));
	}, sendAnswerFn = function(desc) {
		pc.setLocalDescription(desc);
		socket.send(JSON.stringify({
			"event" : "_answer",
			"data" : {
				"sdp" : desc
			}
		}));
	};

	// 获取本地音频和视频流
	navigator.webkitGetUserMedia({
		"audio" : true,
		"video" : true
	},
			function(stream) {
				//绑定本地媒体流到video标签用于输出
				document.getElementById('vid1').src = URL
						.createObjectURL(stream);
				//向PeerConnection中加入需要发送的流
				pc.addStream(stream);
				//如果是发起方则发送一个offer信令
				if (isCaller) {
					pc.createOffer(sendOfferFn, function(error) {
						console.log('Failure callback: ' + error);
					});
				} 
			}, function(error) {
				//处理媒体流创建失败错误
				console.log('getUserMedia error: ' + error);
			});

	//处理到来的信令
	socket.onmessage = function(event) {
		if(event.data=="new user") {
			console.log("new user");
			location.reload();
		} else {
			var json = JSON.parse(event.data);
			console.log('onmessage: ', json);
			//如果是一个ICE的候选，则将其加入到PeerConnection中，否则设定对方的session描述为传递过来的描述
			if (json.event === "_ice_candidate") {
				pc.addIceCandidate(new RTCIceCandidate(json.data.candidate));
			} else {
				pc.setRemoteDescription(new RTCSessionDescription(json.data.sdp));
				// 如果是一个offer，那么需要回复一个answer
				if (json.event === "_offer") {
					pc.createAnswer(sendAnswerFn, function(error) {
						console.log('Failure callback: ' + error);
					});
				}
			}
		}
	};
	
	window.onload=function(){ 
		if(isCaller==null||isCaller==undefined) {
			var tips = document.getElementById("tips");
			tips.remove();
		} else {
			var create = document.getElementById("create");
			create.remove();
		}
	};
	function init() {
		location.reload();
	}
</script>
</head>

<body>
	<video id="vid1" width="640" height="480" autoplay></video>
	<video id="vid2" width="640" height="480" autoplay></video><br>
	<a id="create" href="/Test_WebRTC_0900/#true" onclick="init()">点击此链接新建聊天室</a><br>
	<p id="tips" style="background-color:red">请在其他浏览器中打开：http://此电脑ip:8080/Test_WebRTC_0900   加入此视频聊天</p>
</body>
</html>
