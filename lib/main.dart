import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/rtc_provider.dart';
import 'providers/signaling_provider.dart';
import 'screens/chat_screen.dart';
import 'screens/join_screen.dart';
import 'screens/setting.dart';

void main() async {
  //final signaling = SignalingProvider();
  //await signaling.loadSavedSettings();
  

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SignalingProvider()),
        ChangeNotifierProvider(create: (_) => RTCProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WebRTC 群聊',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) =>  JoinScreen(),
        '/chat': (context) => ChatScreen(),
        '/settings': (context) => SettingsPage(),
      },
    );
  }
}