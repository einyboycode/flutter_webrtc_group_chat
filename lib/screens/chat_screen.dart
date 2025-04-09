import 'package:file_picker/file_picker.dart';
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
    final rtc = Provider.of<RTCProvider>(context, listen: false);
    rtc.clearMessages();
    rtc.addListener(_scrollToBottom);
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   _scrollToBottom();
    // });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    Provider.of<RTCProvider>(context, listen: false).removeListener(_scrollToBottom);
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
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
          child: Text('群号: ${signaling.currentRoomId}'),
        ),
        leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: (){
              signaling.leaveRoom();
              Navigator.pop(context);// 手动返回
            }
        ),
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
      // floatingActionButton: FloatingActionButton(
      //   onPressed: _pickAndSendFile,
      //   tooltip: '发送文件',
      //   child: const Icon(Icons.attach_file),
      // ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: rtc.messages.length,
              itemBuilder: (context, index) {
                final message = rtc.messages[index];
                if (message.type == SendMessageType.file) {
                  return _buildFileMessage(message);
                }
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
                IconButton(
                  icon: const Icon(Icons.attach_file),
                  onPressed: _pickAndSendFile,
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

  Widget _buildFileMessage(Message message) {
    final fileSize = (message.fileSize! / 1024).toStringAsFixed(2);
    
    return Align(
      alignment: message.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onTap: () => _saveFile(message),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: message.isMe 
                ? Theme.of(context).primaryColor 
                : Colors.grey[300],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: 
                message.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (!message.isMe)
                Text(
                  message.senderId.substring(0, 8),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              Row(
                children: [
                  Icon(
                    _getFileIcon(message.fileName!),
                    color: message.isMe ? Colors.white : Colors.black,
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.fileName!,
                        style: TextStyle(
                          color: message.isMe ? Colors.white : Colors.black,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '$fileSize KB',
                        style: TextStyle(
                          fontSize: 12,
                          color: message.isMe ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Text(
                '点击下载',
                style: TextStyle(
                  fontSize: 10,
                  color: message.isMe ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getFileIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      case 'mp3':
      case 'wav':
        return Icons.audiotrack;
      case 'mp4':
      case 'avi':
      case 'mov':
        return Icons.videocam;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'zip':
      case 'rar':
        return Icons.archive;
      default:
        return Icons.insert_drive_file;
    }
  }

  Future<void> _pickAndSendFile() async {
    final signaling = Provider.of<SignalingProvider>(context, listen: false);
    
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.any,
      );
      
      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        final fileName = result.files.single.name;
        
        await signaling.sendFile(filePath, fileName);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('正在发送文件: $fileName')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('选择文件出错: $e')),
      );
    }
  }

  Future<void> _saveFile(Message message) async {
    final rtc = Provider.of<RTCProvider>(context, listen: false);
    
    try {
      await rtc.saveFile(message);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('文件已保存: ${message.fileName}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存文件出错: $e')),
      );
    }
  }
}