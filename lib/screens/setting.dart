import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/signaling_provider.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _serverUrlController;

  @override
  void initState() {
    super.initState();
    final signaling = Provider.of<SignalingProvider>(context, listen: false);
    _serverUrlController = TextEditingController(text: signaling.serverUrl);
  }

  @override
  void dispose() {
    _serverUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('服务器设置'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveSettings,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _serverUrlController,
                decoration: InputDecoration(
                  labelText: '信令服务器地址',
                  hintText: 'ws://your-server.com:8080',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.link),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入服务器地址';
                  }
                  if (!value.startsWith('ws://') && !value.startsWith('wss://')) {
                    return '地址必须以 ws:// 或 wss:// 开头';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              Text(
                '示例地址:',
                style: TextStyle(color: Colors.grey),
              ),
              SizedBox(height: 8),
              _buildExampleAddress('ws://localhost:8080'),
              _buildExampleAddress('wss://signaling.example.com'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExampleAddress(String address) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: InkWell(
        onTap: () {
          _serverUrlController.text = address;
        },
        child: Text(
          address,
          style: TextStyle(
            color: Colors.blue,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }

  void _saveSettings() {
    if (_formKey.currentState!.validate()) {
      final signaling = Provider.of<SignalingProvider>(context, listen: false);
      signaling.updateServerUrl(_serverUrlController.text);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('设置已保存')),
      );
      
      Navigator.pop(context);
    }
  }
}