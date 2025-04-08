import 'package:flutter_webrtc/flutter_webrtc.dart';

class Peer {
  final String id;
  final String name;
  RTCPeerConnection? pc;
  RTCDataChannel? dataChannel;

  Peer({
    required this.id,
    required this.name,
    this.pc,
    this.dataChannel,
  });
}