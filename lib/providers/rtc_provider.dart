import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/message.dart';

class RTCProvider with ChangeNotifier {
  final List<Message> _messages = [];
  List<Message> get messages => _messages;

  void addMessage(Message message) {
    _messages.add(message);
    notifyListeners();
  }

  void clearMessages() {
    _messages.clear();
    notifyListeners();
  }

  // 添加保存文件的方法
  Future<void> saveFile(Message message) async {
    if (message.type != SendMessageType.file || message.fileData == null) {
      return;
    }

    // 获取下载目录
    final directory = await getDownloadPath();
    print("====>保存文件:${directory.path}/${message.fileName}");
    final file = File('${directory.path}/${message.fileName}');
    
    try {
      // 解码并写入文件
      final bytes = base64Decode(message.fileData!);
      await file.writeAsBytes(bytes);
      
      // 可以在这里添加通知用户文件已保存的逻辑
    } catch (e) {
      print('保存文件出错: $e');
    }
  }

  // 获取下载目录
  Future<Directory> getDownloadPath() async {
    Directory directory;
    try {
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory() ?? Directory('/storage/emulated/0/Download');
        }
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      } else {
        directory = Directory.current;
      }
    } catch (err) {
      directory = Directory.current;
    }
    
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    
    return directory;
  }
}