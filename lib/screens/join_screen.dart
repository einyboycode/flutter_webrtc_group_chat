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
  final _groupNameController = TextEditingController();
  bool _isCreatingRoom = false;

  final FocusNode _focusNode = FocusNode();
  List<String> _filteredOptions = [];
  bool _showDropdown = false;

  final List<String> _options = [
    // 'Apple',
    // 'Banana',
    // 'Cherry',
    // 'Dragon Fruit',
    // 'Grapes',
    // 'Orange',
  ];

  @override
  void initState() {
    super.initState(); // 必须调用父类方法
    _roomController.text = "";
  }

  @override
  void dispose() {
    _nameController.dispose();
    _roomController.dispose();
    super.dispose();
  }


  void showTip(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 5), // 自动消失时间
        // action: SnackBarAction(
        //   // 可选操作按钮
        //   label: "撤销",
        //   onPressed: () => print("点击了撤销"),
        // ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final signaling = Provider.of<SignalingProvider>(context);
    signaling.loadSavedSettings();
    //signaling.getRoomList();
    // signaling.getRoomList().then((_) {
    //   _options.clear();
    //   print('===========>rooms_list:${signaling.rooms}');
    //   final roomList = signaling.rooms;
    //   for (final room in roomList) {
    //     final value = room.id;
    //     print('value:${value}');
    //     _options.add(value);
    //   }
    // });

    signaling.onListRooms = () {
      _options.clear();
      print('===========>rooms_list:${signaling.rooms}');
      final roomList = signaling.rooms;
      setState(() {
        for (final room in roomList) {
          final value = room.id;
          print('value:${value}');
          _options.add('group number:' + value);
        }
      });
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Webrtc group chat App'),
        actions: [
          // 添加设置图标按钮
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'server url setting',
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _nameController,
              onTap: () async {
                  await signaling.getRoomList();
              },
              decoration: const InputDecoration(
                labelText: 'your name:',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            if (_isCreatingRoom)
              TextField(
                controller: _groupNameController,
                
                decoration: const InputDecoration(
                  labelText: 'group number:',
                  border: OutlineInputBorder(),
                ),
              ),
            const SizedBox(height: 20),
            if (!_isCreatingRoom)
              Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  // if (textEditingValue.text.isEmpty) {
                  //   return const Iterable<String>.empty();
                  // }

                  return _options;
                },
                onSelected: (String selection) {
                  _roomController.text = selection.replaceAll("group number:", "");
                  print("选择了: ${_roomController.text}");
                },
                fieldViewBuilder: (
                  BuildContext context,
                  TextEditingController controller,
                  FocusNode focusNode,
                  VoidCallback onFieldSubmitted,
                ) {
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    onTap: () async {
                      await signaling.getRoomList();
                    },
                    decoration: InputDecoration(
                      labelText: "Group number to be joined:",
                      border: OutlineInputBorder(),
                    ),
                  );
                },
              ),
            // TextField(
            //     controller: _roomController,
            //     onTap: () {
            //       signaling.getRoomList();
            //       print("文本框被点击了！");
            //       // 可以在这里执行一些操作，比如弹出键盘、显示对话框等
            //     },
            //     decoration: const InputDecoration(
            //       labelText: '群ID',
            //       border: OutlineInputBorder(),
            //     ),
            // ),
            const SizedBox(height: 20),
            if (!_isCreatingRoom)
              ElevatedButton(
                onPressed: () async {
                  if (_nameController.text.isNotEmpty &&
                      _roomController.text.isNotEmpty) {
                    await signaling.connect(_nameController.text);
                    await signaling.joinRoom(_roomController.text);
                    Navigator.pushNamed(context, '/chat');
                  }else{
                    String message = "";
                    if(_nameController.text.isEmpty) message = "Your name cannot be empty";
                    if(_roomController.text.isEmpty) message = "Group number cannot be empty";
                    showTip(message);
                  }
                },
                child: const Text('Join group chat'),
              ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                setState(() {
                  _isCreatingRoom = !_isCreatingRoom;
                });
              },
              child: Text(_isCreatingRoom ? 'Already have a group? Join' : 'create group chat'),
            ),
            if (_isCreatingRoom)
              ElevatedButton(
                onPressed: () async {
                  if (_nameController.text.isNotEmpty) {
                    await signaling.connect(_nameController.text);
                    if (_groupNameController.text.isEmpty) {
                      _groupNameController.text = "new group";
                    }
                    await signaling.createRoom(_groupNameController.text);
                    _groupNameController.text = "new group";
                    Navigator.pushNamed(context, '/chat');
                  }else{
                    String message = "";
                    if(_nameController.text.isEmpty) message = "Your name cannot be empty";
                    showTip(message);
                  }
                },
                child: const Text('create group chat'),
              ),
          ],
        ),
      ),
    );
  }
}
