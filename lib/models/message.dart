
enum SendMessageType {
  text,
  file,
}

class Message {
  final String id;
  final String senderId;
  final String content;
  final DateTime timestamp;
  final bool isMe;
  final String name;
  final SendMessageType type;
  final String? fileName;
  final int? fileSize;
  final String? fileData; // Base64 encoded data or file URL


  Message({
    required this.id,
    required this.senderId,
    required this.content,
    required this.timestamp,
    required this.isMe,
    required this.name,
    this.type = SendMessageType.text,
    this.fileName,
    this.fileSize,
    this.fileData,
  });

  factory Message.fromJson(Map<String, dynamic> json, String myId) {
    return Message(
      id: json['id'] ?? '',
      senderId: json['senderId'] ?? '',
      content: json['content'] ?? '',
      timestamp: DateTime.parse(json['timestamp']),
      isMe: json['senderId'] == myId,
      name: json['name'],
      type: SendMessageType.values.firstWhere(
        (e) => e.toString() == 'MessageType.${json['type']}',
        orElse: () => SendMessageType.text,
      ),
      fileName: json['fileName'],
      fileSize: json['fileSize'],
      fileData: json['fileData'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'content': content,
      'name': name,
      'timestamp': timestamp.toIso8601String(),
      'type': type.toString().split('.').last,
      'fileName': fileName,
      'fileSize': fileSize,
      'fileData': fileData,
    };
  }
}

