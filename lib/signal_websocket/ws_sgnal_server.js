// signaling-server.js
const WebSocket = require('ws');

const wss = new WebSocket.Server({ port: 18080 });
const rooms = new Map();
const users = new Map();

wss.on('connection', (ws) => {
  let userId = null;
  let userName = null;
  let roomId = null;

  ws.on('message', (message) => {
    console.log("message:" + message);
    const data = JSON.parse(message);    
    switch (data.type) {
      case 'register':
        userId = data.userId;
        userName = data.name;
        users.set(userId, { ws, name: userName });
        break;
        
      case 'createRoom':
        roomId = generateId();
        rooms.set(roomId, {
          name: data.roomName,
          peers: [userId],
        });
        ws.send(JSON.stringify({
          type: 'roomCreated',
          roomId,
        }));
        break;
        
      case 'joinRoom':
        roomId = data.roomId;
        userId =  data.userId;
        userName = data.name;
        if (rooms.has(roomId)) {
          const room = rooms.get(roomId);
          room.peers.push(userId);
          
          // 通知现有成员有新成员加入
          room.peers.forEach((peerId) => {
            if (peerId !== userId && users.has(peerId)) {
              users.get(peerId).ws.send(JSON.stringify({
                type: 'peerJoined',
                peerId: userId,
                peerName: userName,
              }));
            }
          });
          
          ws.send(JSON.stringify({
            type: 'joinedRoom',
            roomId,
            peers: room.peers.filter(id => id !== userId).map(id => ({
              peerId: id,
              peerName: users.get(id).name,
            })),
          }));
        }
        break;
        
      case 'offer':
      case 'answer':
      case 'iceCandidate':
        if (users.has(data.peerId)) {
          users.get(data.peerId).ws.send(JSON.stringify({
            ...data,
            userId,
          }));
        }
        break;
      case 'listRoom':
        break;
      case 'leaveRoom':
        if (rooms.has(roomId)) {
          const room = rooms.get(roomId);
          room.peers = room.peers.filter(id => id !== userId);
          
          // 通知其他成员
          room.peers.forEach(peerId => {
            if (users.has(peerId)) {
              users.get(peerId).ws.send(JSON.stringify({
                type: 'peerLeft',
                peerId: userId,
              }));
            }
          });
          
          if (room.peers.length === 0) {
            rooms.delete(roomId);
          }
        }
        break;
    }
  });

  ws.on('close', () => {
    if (roomId && rooms.has(roomId)) {
      const room = rooms.get(roomId);
      room.peers = room.peers.filter(id => id !== userId);
      
      room.peers.forEach(peerId => {
        if (users.has(peerId)) {
          users.get(peerId).ws.send(JSON.stringify({
            type: 'peerLeft',
            peerId: userId,
          }));
        }
      });
      
      if (room.peers.length === 0) {
        rooms.delete(roomId);
      }
    }
    
    if (userId) {
      users.delete(userId);
    }
  });
});

function generateId() {
  return Math.random().toString(36).substring(2, 10);
}

console.log('Signaling server running on ws://localhost:18080');