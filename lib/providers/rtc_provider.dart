import 'package:flutter/foundation.dart';

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
}