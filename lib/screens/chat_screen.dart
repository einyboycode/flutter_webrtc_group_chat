import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/message.dart';
import '../models/peer.dart';
import '../providers/rtc_provider.dart';
import '../providers/signaling_provider.dart';
import '../widgets/message_bubble.dart';
import '../widgets/peer_list.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final signaling = Provider.of<SignalingProvider>(context);
    signaling.init(context);
    final rtc = Provider.of<RTCProvider>(context);

    return Scaffold(
      appBar: AppBar(
        //title: Text('房间: ${signaling.currentRoomId?.substring(0, 10)}'),
        title: GestureDetector(
          onLongPress: () {
            final text = '${signaling.currentRoomId}';
            Clipboard.setData(ClipboardData(text: text));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('已复制: $text')),
            );
          },
          child: Text('群房间号: ${signaling.currentRoomId}'),
        ),
        // leading: IconButton(
        //     icon: Icon(Icons.arrow_back),
        //     onPressed: () => Navigator.pop(context), // 手动返回
        // ),
        actions: [
          IconButton(
            icon: const Icon(Icons.people),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (context) => PeerList(peers: signaling.peers),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: rtc.messages.length,
              itemBuilder: (context, index) {
                final message = rtc.messages[index];
                return MessageBubble(
                  message: message,
                  isMe: message.isMe,
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: '输入消息...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    if (_messageController.text.isNotEmpty) {
      final signaling = Provider.of<SignalingProvider>(context, listen: false);
      final rtc = Provider.of<RTCProvider>(context, listen: false);
      
      final message = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: signaling.myId!,
        content: _messageController.text,
        timestamp: DateTime.now(),
        isMe: true,
        name: signaling.myName!,
      );
      
      rtc.addMessage(message);
      signaling.sendMessage(_messageController.text);
      _messageController.clear();
      _scrollToBottom();
    }
  }
}