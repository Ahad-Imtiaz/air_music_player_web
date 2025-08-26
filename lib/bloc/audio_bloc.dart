import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'audio_event.dart';
import 'audio_state.dart';
import 'package:file_picker/file_picker.dart';

class AudioBloc extends Bloc<AudioEvent, AudioState> {
  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<PlayerState>? _playerStateSub;

  AudioBloc() : super(AudioState()) {
    // Listen to player state to fix play/pause lag
    _playerStateSub = _player.playerStateStream.listen((playerState) {
      final isPlaying = playerState.playing;
      add(UpdatePlayingStateEvent(isPlaying: isPlaying));
    });

    on<LoadAudioEvent>((event, emit) async {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
      );
      if (result != null && result.files.single.bytes != null) {
        final bytes = result.files.single.bytes!;
        final name = result.files.single.name;

        await _player.setAudioSource(
          AudioSource.uri(Uri.dataFromBytes(bytes, mimeType: 'audio/mpeg')),
        );

        emit(state.copyWith(
          duration: _player.duration ?? Duration.zero,
          songName: name,
        ));

        _positionSub?.cancel();
        _positionSub = _player.positionStream.listen((pos) {
          add(UpdatePositionEvent(position: pos));
        });
      }
    });

    on<PlayAudioEvent>((event, emit) async {
      await _player.play();
      // no emit here, UI will update via _playerStateSub
    });

    on<PauseAudioEvent>((event, emit) async {
      await _player.pause();
      // no emit here, UI will update via _playerStateSub
    });

    on<SeekAudioEvent>((event, emit) async {
      await _player.seek(event.position);
      emit(state.copyWith(position: event.position));
    });

    on<UpdatePositionEvent>((event, emit) {
      emit(state.copyWith(position: event.position));
    });

    on<UpdatePlayingStateEvent>((event, emit) {
      emit(state.copyWith(isPlaying: event.isPlaying));
    });
  }

  @override
  Future<void> close() {
    _positionSub?.cancel();
    _playerStateSub?.cancel();
    _player.dispose();
    return super.close();
  }
}
