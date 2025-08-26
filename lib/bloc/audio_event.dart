import 'package:equatable/equatable.dart';

abstract class AudioEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadAudioEvent extends AudioEvent {}

class PlayAudioEvent extends AudioEvent {}

class PauseAudioEvent extends AudioEvent {}

class SeekAudioEvent extends AudioEvent {
  final Duration position;
  SeekAudioEvent({required this.position});
  @override
  List<Object?> get props => [position];
}

class UpdatePositionEvent extends AudioEvent {
  final Duration position;
  UpdatePositionEvent({required this.position});
  @override
  List<Object?> get props => [position];
}

class UpdatePlayingStateEvent extends AudioEvent {
  final bool isPlaying;
  UpdatePlayingStateEvent({required this.isPlaying});
  @override
  List<Object?> get props => [isPlaying];
}
