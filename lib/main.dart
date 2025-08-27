import 'package:air_music_player_web/widgets/slider/wave_slider.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart'; // for kIsWeb
import 'widgets/glowing_button.dart';
import 'widgets/glowing_3d_button.dart';
import 'dart:html' as html;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Audio Player',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: Colors.deepPurpleAccent,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1F1F1F),
          foregroundColor: Colors.deepPurpleAccent,
          elevation: 2,
        ),
        sliderTheme: SliderThemeData(
          activeTrackColor: Colors.deepPurpleAccent,
          inactiveTrackColor: Colors.white24,
          thumbColor: Colors.deepPurpleAccent,
          overlayColor: Colors.deepPurpleAccent.withOpacity(0.2),
          trackHeight: 4,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
          overlayShape: const RoundSliderOverlayShape(overlayRadius: 24),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurpleAccent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.white70),
          bodyLarge: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.deepPurpleAccent),
      ),
      home: const AudioPlayerPage(),
    );
  }
}

class AudioPlayerPage extends StatefulWidget {
  const AudioPlayerPage({super.key});

  @override
  State<AudioPlayerPage> createState() => _AudioPlayerPageState();
}

class _AudioPlayerPageState extends State<AudioPlayerPage> {
  final AudioPlayer _player = AudioPlayer();
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isPlaying = false;
  bool _isRepeating = false;
  String _songName = "No song loaded";

  double? _dragValue;

  @override
  void initState() {
    super.initState();

    // Only one positionStream listener
    _player.positionStream.listen((pos) async {
      if (_dragValue == null) {
        setState(() {
          _position = pos;
        });
      }
      // Seamless repeat: seek to start just before the end
      if (_isRepeating &&
          _duration > Duration.zero &&
          (_duration.inMilliseconds - pos.inMilliseconds) <= 200 &&
          _player.playing) {
        await _player.seek(Duration.zero);
        await _player.play();
        setState(() {
          _position = Duration.zero;
          _dragValue = null;
        });
      }
    });

    // Listen for end of track when repeat is off
    _player.playerStateStream.listen((state) async {
      if (state.processingState == ProcessingState.completed && !_isRepeating) {
        setState(() {
          _isPlaying = false;
          _dragValue = null;
          _position = _duration; // Keep at end
        });
      } else if (state.playing != _isPlaying) {
        setState(() {
          _isPlaying = state.playing;
        });
      }
    });

    _player.durationStream.listen((dur) {
      setState(() {
        _duration = dur ?? Duration.zero;
      });
    });
  }

  String formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  Future<void> _loadAudio() async {
    if (kIsWeb) {
      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.audio);
      if (result != null && result.files.single.bytes != null) {
        final name = result.files.single.name;
        final bytes = result.files.single.bytes!;

        // Create a blob URL
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);

        await _player.setAudioSource(AudioSource.uri(Uri.parse(url)));

        setState(() => _songName = name);
      }
    } else {
      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.audio);
      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;
        final name = result.files.single.name;
        await _player.setFilePath(path);
        setState(() => _songName = name);
      }
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final audioDuration = _duration.inMilliseconds.toDouble().clamp(1, double.infinity);
    final clampedPosition = _position > _duration ? _duration : _position;
    final audioDurationPosition = (_dragValue ?? clampedPosition.inMilliseconds.toDouble()).clamp(0, audioDuration);

    return Scaffold(
      appBar: AppBar(title: const Text("Simple Audio Player")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Glowing3DButton(
                onPressed: _loadAudio,
                text: "Load Audio",
              ),
              const SizedBox(height: 20),
              GlowingWidget(
                onPressed: _loadAudio,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    "Load Audio",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _songName,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),
              WaveSlider(
                value: audioDuration > 0 ? audioDurationPosition / audioDuration : 0,
                enabled: _duration > Duration.zero,
                width: MediaQuery.of(context).size.width * 0.90,
                color: Colors.deepPurpleAccent,
                onChanged: (value) {
                  setState(() {
                    _dragValue = value * _duration.inMilliseconds;
                  });
                },
                onChangeEnd: (value) {
                  final newPos = Duration(milliseconds: (value * _duration.inMilliseconds).toInt());
                  _player.seek(newPos);
                  setState(() {
                    _dragValue = null;
                  });
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(formatTime(clampedPosition)),
                  Text(formatTime(_duration)),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GlowingWidget(
                    borderRadius: 100,
                    onPressed: () {
                      if (_duration > Duration.zero) {
                        if (_isPlaying) {
                          _player.pause();
                          setState(() => _isPlaying = false);
                        } else {
                          _player.play();
                          setState(() => _isPlaying = true);
                        }
                      }
                    },
                    child: Icon(
                      _isPlaying ? Icons.pause_circle : Icons.play_circle,
                      size: 60,
                      color: Colors.deepPurpleAccent,
                    ),
                  ),
                  const SizedBox(width: 20),
                  IconButton(
                    iconSize: 40,
                    icon: Icon(
                      Icons.repeat,
                      color: _isRepeating ? Colors.deepPurpleAccent : Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _isRepeating = !_isRepeating;
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
