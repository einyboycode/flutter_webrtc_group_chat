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

  final FocusNode _focusNode = FocusNode();
  List<String> _filteredOptions = [];
  bool _showDropdown = false;
  
  final List<String> _options = [
    'Apple',
    'Banana',
    'Cherry',
    'Dragon Fruit',
    'Grapes',
    'Orange',
  ];


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
              // Autocomplete<String>(
              //   optionsBuilder: (TextEditingValue textEditingValue) {
              //     if (textEditingValue.text.isEmpty) {
              //       return const Iterable<String>.empty();
              //     }
              //     return _options.where((option) =>
              //     option.toLowerCase().contains(textEditingValue.text.toLowerCase()));
              //   },
              //   onSelected: (String selection) {
              //     print("选择了: $selection");
              //   }, 
              //   fieldViewBuilder: (
              //     BuildContext context,
              //     TextEditingController _roomController,
              //     FocusNode focusNode,
              //     VoidCallback onFieldSubmitted,
              //   ){
              //     return TextField(
              //       controller: _roomController,
              //       onTap: () {
              //         signaling.getRoomList();
              //       },
              //       decoration: const InputDecoration(
              //         labelText: '群ID',
              //         border: OutlineInputBorder(),
              //       ),
              //     );
              //   },
              // ),
            TextField(
                controller: _roomController,
                onTap: () {
                  signaling.getRoomList();
                  print("文本框被点击了！");
                  // 可以在这里执行一些操作，比如弹出键盘、显示对话框等
                },
                decoration: const InputDecoration(
                  labelText: '群ID',
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
                child: const Text('加入群'),
              ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                setState(() {
                  _isCreatingRoom = !_isCreatingRoom;
                });
              },
              child: Text(_isCreatingRoom ? '已有群？加入' : '创建新群'),
            ),
            if (_isCreatingRoom)
              ElevatedButton(
                onPressed: () async {
                  if (_nameController.text.isNotEmpty) {
                    await signaling.connect(_nameController.text);
                    await signaling.createRoom('新群');
                    Navigator.pushNamed(context, '/chat');
                  }
                },
                child: const Text('创建群'),
              ),
          ],
        ),
      ),
    );
  }
}