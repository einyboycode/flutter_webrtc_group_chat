import 'package:flutter/material.dart';

import '../models/peer.dart';

class PeerList extends StatelessWidget {
  final List<Peer> peers;

  const PeerList({Key? key, required this.peers}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '在线成员',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            itemCount: peers.length,
            itemBuilder: (context, index) {
              final peer = peers[index];
              return ListTile(
                leading: const Icon(Icons.person),
                title: Text(peer.name),
                subtitle: Text(peer.id.substring(0, 8)),
              );
            },
          ),
        ],
      ),
    );
  }
}