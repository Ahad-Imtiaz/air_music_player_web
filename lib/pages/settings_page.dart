import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: const Center(
        child: Text(
          'Web does not support folder paths for saving files.\nEdited songs will be downloaded to your default download folder.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
