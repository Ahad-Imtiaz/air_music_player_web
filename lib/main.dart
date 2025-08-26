import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart'; // for kIsWeb
import 'widgets/glowing_button.dart';
import 'widgets/glowing_3d_button.dart';

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
  String _songName = "No song loaded";

  double? _dragValue;

  @override
  void initState() {
    super.initState();

    _player.positionStream.listen((pos) {
      if (_dragValue == null) {
        setState(() {
          _position = pos;
        });
      }
    });

    _player.durationStream.listen((dur) {
      setState(() {
        _duration = dur ?? Duration.zero;
      });
    });

    _player.playerStateStream.listen((state) {
      setState(() {
        _isPlaying = state.playing;
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
        final bytes = result.files.single.bytes!;
        final name = result.files.single.name;
        await _player.setAudioSource(
          AudioSource.uri(Uri.dataFromBytes(bytes, mimeType: 'audio/mpeg')),
        );
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
    final max = _duration.inMilliseconds.toDouble();
    final pos = _dragValue ?? _position.inMilliseconds.toDouble();

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
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: Colors.deepPurpleAccent,
                    inactiveTrackColor: Colors.white24,
                    thumbColor: Colors.deepPurpleAccent,
                    overlayColor: Colors.deepPurpleAccent.withOpacity(0.3),
                    trackHeight: 4,
                  ),
                  child: Slider(
                    value: pos.clamp(0, max),
                    max: max > 0 ? max : 1,
                    onChanged: (value) {
                      setState(() {
                        _dragValue = value;
                      });
                    },
                    onChangeEnd: (value) {
                      _player.seek(Duration(milliseconds: value.toInt()));
                      setState(() {
                        _dragValue = null;
                      });
                    },
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(formatTime(_position)),
                  Text(formatTime(_duration)),
                ],
              ),
              const SizedBox(height: 20),
              GlowingWidget(
                borderRadius: 100,
                onPressed: () {
                  if (_duration > Duration.zero) {
                    if (_isPlaying) {
                      _player.pause();
                    } else {
                      _player.play();
                    }
                  }
                },
                child: Icon(
                  _isPlaying ? Icons.pause_circle : Icons.play_circle,
                  size: 60,
                  color: Colors.deepPurpleAccent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
