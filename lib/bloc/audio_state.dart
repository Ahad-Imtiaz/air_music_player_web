class AudioState {
  final Duration position;
  final Duration duration;
  final bool isPlaying;
  final String songName;

  AudioState({
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.isPlaying = false,
    this.songName = "No song loaded",
  });

  AudioState copyWith({
    Duration? position,
    Duration? duration,
    bool? isPlaying,
    String? songName,
  }) {
    return AudioState(
      position: position ?? this.position,
      duration: duration ?? this.duration,
      isPlaying: isPlaying ?? this.isPlaying,
      songName: songName ?? this.songName,
    );
  }
}
