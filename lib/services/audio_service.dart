import 'package:audioplayers/audioplayers.dart';

class AudioService {
  final AudioPlayer _player = AudioPlayer();
  DateTime _ultimoSom = DateTime.fromMillisecondsSinceEpoch(0);
  static const Duration _intervalo = Duration(seconds: 2);

  Future<void> tocarMugido({double volume = 1.0}) async {
    final agora = DateTime.now();
    if (agora.difference(_ultimoSom) < _intervalo) return;
    _ultimoSom = agora;

    try {
      await _player.stop();
      await _player.setVolume(volume.clamp(0.0, 1.0).toDouble());
      // Toca o arquivo real armazenado nos assets do projeto
      await _player.play(
        AssetSource('audio/Video_Project_3.m4a'),
        );
    } catch (_) {
      // Ignora falhas em testes unitários ou restrições de autoplay
    }
  }

  void dispose() {
    _player.dispose();
  }
}