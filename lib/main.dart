import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lan_quiz/classes.dart';
import 'package:lan_quiz/screens/home_menu_screen.dart';
import 'package:lan_quiz/screens/host_settings_screen.dart';
import 'package:lan_quiz/screens/leaderboard_screen.dart';
import 'package:lan_quiz/screens/player_waiting_screen.dart';
import 'package:lan_quiz/screens/quiz_question_screen.dart';
import 'package:provider/provider.dart';
import 'package:bonsoir/bonsoir.dart';
import 'gameState/host_game_state.dart';
import 'dart:async';
import 'package:html/parser.dart';


void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    ChangeNotifierProvider(
      create: (context) => HostGameState(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LAN Quiz',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const HomeScreen(),
    );
  }
}


