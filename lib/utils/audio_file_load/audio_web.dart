// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:just_audio/just_audio.dart';
import 'package:file_picker/file_picker.dart';

Future<Map<String, dynamic>?> loadAudio(AudioPlayer player) async {
  FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.audio);
  if (result != null && result.files.single.bytes != null) {
    final name = result.files.single.name;
    final bytes = result.files.single.bytes!;
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    await player.setAudioSource(AudioSource.uri(Uri.parse(url)));
    return {'player': player, 'name': name};
  }
  return null;
}
