import 'package:air_music_player_web/bloc/audio_bloc.dart';
import 'package:air_music_player_web/pages/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() {
  runApp(
    BlocProvider(
      create: (_) => AudioBloc(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Air Music Player Web',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.deepPurple,
        scaffoldBackgroundColor: const Color(0xFF121212),
        sliderTheme: const SliderThemeData(
          thumbColor: Colors.deepPurpleAccent,
          activeTrackColor: Colors.deepPurple,
          inactiveTrackColor: Colors.grey,
        ),
      ),
      home: const HomePage(),
    );
  }
}
