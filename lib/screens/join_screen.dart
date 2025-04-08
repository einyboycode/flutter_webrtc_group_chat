import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/signaling_provider.dart';

class JoinScreen extends StatefulWidget {
  const JoinScreen({super.key});

  @override
  _JoinScreenState createState() => _JoinScreenState();
}

class _JoinScreenState extends State<JoinScreen> {
  final _nameController = TextEditingController();
  final _roomController = TextEditingController();
  bool _isCreatingRoom = false;

  @override
  void dispose() {
    _nameController.dispose();
    _roomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final signaling = Provider.of<SignalingProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('加入群聊'),
        // leading: IconButton(
        //     icon: Icon(Icons.arrow_back),
        //     onPressed: () => Navigator.pop(context), // 手动返回
        // ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '你的名字',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            if (!_isCreatingRoom)
              TextField(
                controller: _roomController,
                decoration: const InputDecoration(
                  labelText: '房间ID',
                  border: OutlineInputBorder(),
                ),
              ),
            const SizedBox(height: 20),
            if (!_isCreatingRoom)
              ElevatedButton(
                onPressed: () async {
                  if (_nameController.text.isNotEmpty && 
                      _roomController.text.isNotEmpty) {
                    await signaling.connect(_nameController.text);
                    await signaling.joinRoom(_roomController.text);
                    Navigator.pushNamed(context, '/chat');
                  }
                },
                child: const Text('加入房间'),
              ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                setState(() {
                  _isCreatingRoom = !_isCreatingRoom;
                });
              },
              child: Text(_isCreatingRoom ? '已有房间？加入' : '创建新房间'),
            ),
            if (_isCreatingRoom)
              ElevatedButton(
                onPressed: () async {
                  if (_nameController.text.isNotEmpty) {
                    await signaling.connect(_nameController.text);
                    await signaling.createRoom('新房间');
                    Navigator.pushNamed(context, '/chat');
                  }
                },
                child: const Text('创建房间'),
              ),
          ],
        ),
      ),
    );
  }
}