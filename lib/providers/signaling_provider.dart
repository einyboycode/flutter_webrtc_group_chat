import 'dart:convert';
import 'dart:io';

//import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:webrtc_group_chat/models/message.dart';
import 'package:webrtc_group_chat/models/room.dart';
import 'package:webrtc_group_chat/providers/rtc_provider.dart';

import '../models/peer.dart';

class SignalingProvider with ChangeNotifier {
  final String _serverUrl =
      'ws://192.168.200.120:18080'; // Replace with your signaling server address
  dynamic _socket = null;
  String? _myId;
  String? _myName;
  String? _currentRoomId;
  final List<Peer> _peers = [];
  bool _isConnected = false;
  final List<Room> _rooms = [];

  final config = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
      {'urls': 'stun:stun2.l.google.com:19302'},
      {'urls': 'stun:stun3.l.google.com:19302'},
    ]
  };

  // Getters
  String? get myId => _myId;
  String? get myName => _myName;
  String? get currentRoomId => _currentRoomId;
  List<Peer> get peers => _peers;
  bool get isConnected => _isConnected;
  List<Room> get rooms => _rooms;

  Function()? onListRooms;

  BuildContext? _context;

  // 初始化上下文
  void init(BuildContext context) {
    _context = context;
  }

  // 获取房间列表
  Future<void> getRoomList() async {
    _rooms.clear();
    if (_socket == null) {
      _socket = await WebSocket.connect(_serverUrl);
      // Listen for messages
      _socket.listen((data) {
        // Handle incoming data
        _handleSignalingMessage(data);
      }, onDone: () {
        print('Connection closed');
        _isConnected = false;
        notifyListeners();
      }, onError: (error) {
        print('Error: $error');
      });
    }
    if (_socket!.readyState == WebSocket.open) {
      // 发送listRoom消息
      notifyListeners();
      _socket!.add(jsonEncode({
        'type': 'listRoom',
      }));
    }
  }

  // 连接到信令服务器
  Future<void> connect(String name) async {
    _myId = const Uuid().v4();
    _myName = name;

    if (_socket == null) {
      _socket = await WebSocket.connect(_serverUrl);

      // Listen for messages
      _socket.listen((data) {
        // Handle incoming data
        _handleSignalingMessage(data);
      }, onDone: () {
        print('Connection closed');
        _isConnected = false;
        notifyListeners();
      }, onError: (error) {
        print('Error: $error');
      });
    }

    // 验证连接是否成功
    if (_socket!.readyState == WebSocket.open) {
      print("WebSocket connected successfully!");
      _isConnected = true;
      notifyListeners();

      // 发送注册消息
      _socket!.add(jsonEncode({
        'type': 'register',
        'userId': _myId,
        'name': name,
      }));
    } else {
      print("WebSocket failed to connect.");
    }
  }

  // 处理信令消息
  void _handleSignalingMessage(dynamic message) {
    final data = jsonDecode(message);
    print("=========>data:$data");
    switch (data['type']) {
      case 'roomCreated':
        _currentRoomId = data['roomId'];
        notifyListeners();
        break;
      case 'listRoom':
        _handelListRoom(data);
        break;
      case 'peerJoined':
        _handlePeerJoined(data);
        break;
      case 'joinedRoom':
        _handleJoinedRoom(data);
        break;
      case 'offer':
        _handleOffer(data);
        break;
      case 'answer':
        _handleAnswer(data);
        break;
      case 'iceCandidate':
        _handleIceCandidate(data);
        break;
      case 'peerLeft':
        _handlePeerLeft(data);
        break;
    }
  }

  // 创建房间
  Future<void> createRoom(String roomName) async {
    _peers.add(Peer(id: _myId!, name: _myName! + "(self)"));
    _socket!.add(jsonEncode({
      'type': 'createRoom',
      'userId': _myId,
      'name': _myName,
      'roomName': roomName,
    }));
  }

  // 加入房间
  Future<void> joinRoom(String roomId) async {
    _peers.add(Peer(id: _myId!, name: _myName! + "(self)"));
    _socket!.add(jsonEncode({
      'type': 'joinRoom',
      'userId': _myId,
      'name': _myName,
      'roomId': roomId,
    }));
    _currentRoomId = roomId;
    notifyListeners();
  }

  Future<void> _handelListRoom(Map<String, dynamic> data) async {
    final List<dynamic> roomList = data['rooms'];
    //print("=========>roomList:${roomList}");
    for (final room in roomList) {
      //print("=========>room:$room");
      _rooms.add(Room(
        id: room['roomId'],
        name: room['name'],
        peerIds: [],
      ));
    }
    print("=========>_rooms:$_rooms");
    onListRooms?.call();
  }

  // 处理peer加入
  void _handlePeerJoined(Map<String, dynamic> data) {
    final peerId = data['peerId'];
    final peerName = data['peerName'];

    if (!_peers.any((p) => p.id == peerId)) {
      _peers.add(Peer(id: peerId, name: peerName));
      notifyListeners();
      _initiatePeerConnection(peerId);
    }
  }

  void _handleJoinedRoom(Map<String, dynamic> data) {}

  // 初始化peer连接
  Future<void> _initiatePeerConnection(String peerId) async {
    final peer = _peers.firstWhere((p) => p.id == peerId);
    final pc = await createPeerConnection(config);

    // 创建数据通道
    final dataChannel =
        await pc.createDataChannel('chat', RTCDataChannelInit());
    _setupDataChannel(dataChannel, peerId);

    peer.pc = pc;
    peer.dataChannel = dataChannel;

    // 收集ICE候选
    pc.onIceCandidate = (candidate) {
      _socket!.add(jsonEncode({
        'type': 'iceCandidate',
        'userId': _myId,
        'peerId': peerId,
        'candidate': {
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        },
      }));
    };

    // 创建offer
    final offer = await pc.createOffer();
    await pc.setLocalDescription(offer);

    _socket!.add(jsonEncode({
      'type': 'offer',
      'userId': _myId,
      'peerId': peerId,
      'peerName': _myName,
      'offer': offer.toMap(),
    }));
  }

  // 处理offer
  Future<void> _handleOffer(Map<String, dynamic> data) async {
    final peerId = data['userId'];
    final offer = data['offer'];
    final peerName = data['peerName'];

    if (!_peers.any((p) => p.id == peerId)) {
      _peers.add(Peer(id: peerId, name: peerName));
      notifyListeners();
    }

    final peer = _peers.firstWhere((p) => p.id == peerId);
    var pc = peer.pc;
    pc ??= await createPeerConnection(config);

    pc.onDataChannel = (channel) {
      _setupDataChannel(channel, peerId);
      peer.dataChannel = channel;
      notifyListeners();
    };

    pc.onIceCandidate = (candidate) {
      _socket!.add(jsonEncode({
        'type': 'iceCandidate',
        'userId': _myId,
        'name': _myName,
        'peerId': peerId,
        'candidate': {
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        },
      }));
    };

    await pc.setRemoteDescription(RTCSessionDescription(
      offer['sdp'],
      offer['type'],
    ));

    final answer = await pc.createAnswer();
    await pc.setLocalDescription(answer);

    _socket!.add(jsonEncode({
      'type': 'answer',
      'userId': _myId,
      'peerId': peerId,
      'answer': answer.toMap(),
    }));

    peer.pc = pc;
    notifyListeners();
  }

  // 处理answer
  Future<void> _handleAnswer(Map<String, dynamic> data) async {
    final peerId = data['userId'];
    final answer = data['answer'];

    final peer = _peers.firstWhere((p) => p.id == peerId);
    await peer.pc!.setRemoteDescription(RTCSessionDescription(
      answer['sdp'],
      answer['type'],
    ));
  }

  // 处理ICE候选
  Future<void> _handleIceCandidate(Map<String, dynamic> data) async {
    final peerId = data['userId'];
    final candidate = data['candidate'];
    final peerName = data['name'];

    if (!_peers.any((p) => p.id == peerId)) {
      // 这里可能需要从信令服务器获取peer的名字，或者使用默认值
      _peers.add(Peer(id: peerId, name: peerName));
      notifyListeners();
    }

    final peer = _peers.firstWhere((p) => p.id == peerId);

    peer.pc ??= await createPeerConnection(config);

    await peer.pc!.addCandidate(RTCIceCandidate(
      candidate['candidate'],
      candidate['sdpMid'],
      candidate['sdpMLineIndex'],
    ));
  }

  // 处理peer离开
  void _handlePeerLeft(Map<String, dynamic> data) {
    final peerId = data['peerId'];
    _peers.removeWhere((p) => p.id == peerId);
    notifyListeners();
  }

  // 设置数据通道
  void _setupDataChannel(RTCDataChannel channel, String peerId) {
    channel.onDataChannelState = (state) {
      print('Data channel state: $state');
    };

    channel.onMessage = (message) {
      final rtc = Provider.of<RTCProvider>(_context!, listen: false);
      final Map<String, List<String>> fileChunksMap = {};

      // 处理收到的消息
      final data = jsonDecode(message.text);
      switch (data['type']) {
        case 'message':
          //data['isMe'] = false;
          rtc.addMessage(Message.fromJson(data, _myId!));
          notifyListeners();
        break;
        case 'fileMetadata':
        // 初始化文件接收
        fileChunksMap[data['fileId']] = List.filled(data['totalChunks'], '');
        break;
        
      case 'fileChunk':
        // 存储文件块
        fileChunksMap[data['fileId']]?[data['chunkIndex']] = data['data'];
        
        // 检查是否所有块都已接收
        final chunks = fileChunksMap[data['fileId']];
        if (chunks != null && !chunks.any((chunk) => chunk.isEmpty)) {
          // 所有块已接收，组合文件
          final fileData = chunks.join();
          final metadata = data; // 这里应该保存之前的元数据
          
          rtc.addMessage(Message(
            id: metadata['fileId'],
            senderId: metadata['senderId'],
            content: '发送了文件: ${metadata['fileName']}',
            timestamp: DateTime.parse(metadata['timestamp']),
            isMe: metadata['senderId'] == _myId,
            name: metadata['name'], 
            type: SendMessageType.file,
            fileName: metadata['fileName'],
            fileSize: metadata['fileSize'],
            fileData: fileData,
          ));
          
          // 清理
          fileChunksMap.remove(data['fileId']);
        }
        break;
      }

      // if (data['type'] == 'message') {
      //   // 在这里处理消息
      //   // 可以通知UI更新
      //   final peerName = data['name'];
      //   final content = data['content'];
      //   final senderId = data['senderId'];
      //   final timestamp = data['timestamp'];
      //   print("$_myName接收到[$peerName]消息:$content 时间:$timestamp");
      //   final rtc = Provider.of<RTCProvider>(_context!, listen: false);
      //   final message = Message(
      //       id: DateTime.now().millisecondsSinceEpoch.toString(),
      //       senderId: senderId!,
      //       content: content,
      //       timestamp: DateTime.parse(timestamp),
      //       isMe: false,
      //       name: peerName);
      //   rtc.addMessage(message);
      //   notifyListeners();
      // }
    };
  }

  // 发送消息
  void sendMessage(String text) {
    final message = {
      'type': 'message',
      'senderId': _myId,
      'name': _myName,
      'content': text,
      'timestamp': DateTime.now().toIso8601String(),
    };

    for (final peer in _peers) {
      if (peer.dataChannel?.state == RTCDataChannelState.RTCDataChannelOpen) {
        peer.dataChannel!.send(RTCDataChannelMessage(jsonEncode(message)));
      }
    }
  }

  // 离开房间
  Future<void> leaveRoom() async {
    if (_currentRoomId != null) {
      _socket!.add(jsonEncode({
        'type': 'leaveRoom',
        'userId': _myId,
        'roomId': _currentRoomId,
      }));

      for (final peer in _peers) {
        await peer.pc?.close();
      }

      _peers.clear();
      _currentRoomId = null;
      notifyListeners();
    }
  }

  // 发送文件
  Future<void> sendFile(String filePath, String fileName) async {
    final file = File(filePath);
    final fileSize = await file.length();
    final bytes = await file.readAsBytes();
    final base64Data = base64Encode(bytes);

    // 将文件分块发送以避免数据通道大小限制
    const chunkSize = 16 * 1024; // 16KB 每个块
    final totalChunks = (base64Data.length / chunkSize).ceil();

    // 发送文件元数据
    final metadata = {
      'type': 'fileMetadata',
      'name': _myName,
      'fileId': const Uuid().v4(),
      'fileName': fileName,
      'fileSize': fileSize,
      'totalChunks': totalChunks,
      'senderId': _myId,
      'timestamp': DateTime.now().toIso8601String(),
    };

    for (final peer in _peers) {
      if (peer.id == _myId) continue;
      if (peer.dataChannel?.state == RTCDataChannelState.RTCDataChannelOpen) {
        peer.dataChannel!.send(RTCDataChannelMessage(jsonEncode(metadata)));
      }
    }

    // 发送文件数据块
    for (var i = 0; i < totalChunks; i++) {
      final start = i * chunkSize;
      final end = (i + 1) * chunkSize;
      final chunk = base64Data.substring(
        start,
        end > base64Data.length ? base64Data.length : end,
      );

      final chunkMessage = {
        'type': 'fileChunk',
        'name': _myName,
        'fileId': metadata['fileId'],
        'chunkIndex': i,
        'totalChunks': totalChunks,
        'data': chunk,
      };

      for (final peer in _peers) {
        if (peer.id == _myId) continue;
        if (peer.dataChannel?.state == RTCDataChannelState.RTCDataChannelOpen) {
          peer.dataChannel!
              .send(RTCDataChannelMessage(jsonEncode(chunkMessage)));
        }
      }
    }
  }

  // 断开连接
  Future<void> disconnect() async {
    await leaveRoom();
    _socket?.close();
    _isConnected = false;
    _myId = null;
    notifyListeners();
  }
}
