import 'package:just_audio/just_audio.dart';
import 'package:file_picker/file_picker.dart';

Future<Map<String, dynamic>?> loadAudio(AudioPlayer player) async {
  FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.audio);
  if (result != null && result.files.single.path != null) {
    final path = result.files.single.path!;
    final name = result.files.single.name;
    await player.setFilePath(path);
    return {'player': player, 'name': name};
  }
  return null;
}
