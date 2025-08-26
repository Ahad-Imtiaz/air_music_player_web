import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:air_music_player_web/bloc/audio_bloc.dart';
import 'package:air_music_player_web/bloc/audio_event.dart';
import 'package:air_music_player_web/bloc/audio_state.dart';
import 'package:air_music_player_web/utils/format_time.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final audioBloc = BlocProvider.of<AudioBloc>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Air Music Player Web'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: BlocBuilder<AudioBloc, AudioState>(
            builder: (context, state) {
              final duration = state.duration.inMilliseconds.toDouble();
              final position = state.position.inMilliseconds.toDouble();
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () => audioBloc.add(LoadAudioEvent()),
                    child: const Text('Load Audio'),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    state.songName,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  Slider(
                    value: position.clamp(0, duration),
                    max: duration > 0 ? duration : 1,
                    onChanged: (value) {
                      audioBloc.add(
                        SeekAudioEvent(position: Duration(milliseconds: value.toInt())),
                      );
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(formatTime(state.position)),
                      Text(formatTime(state.duration)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  IconButton(
                    iconSize: 60,
                    icon: Icon(
                      state.isPlaying ? Icons.pause_circle : Icons.play_circle,
                      color: Colors.deepPurpleAccent,
                    ),
                    onPressed: () {
                      if (state.isPlaying) {
                        audioBloc.add(PauseAudioEvent());
                      } else {
                        audioBloc.add(PlayAudioEvent());
                      }
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
