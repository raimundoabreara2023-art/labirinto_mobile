import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:labirinto_mobile/services/labirinto_service.dart';

void main() {
  final service = LabirintoService();

  test('o mapa inicial tem caminho do jogador até a saída', () {
    final mapa = service.criarMapa();
    expect(service.existeCaminho(mapa, 1, 1), isTrue);
  });

  test('sem passagem para a saída, não existe caminho', () {
    final mapa = service.criarMapa();
    mapa[7][11] = '#';
    expect(service.existeCaminho(mapa, 1, 1), isFalse);
  });

  test('depois de várias mudanças o caminho e os pilares continuam', () {
    final mapa = service.criarMapa();
    final random = Random(42);

    for (int i = 0; i < 200; i++) {
      service.transformarDinamico(mapa, 1, 1, 5, 8, random);
      expect(service.existeCaminho(mapa, 1, 1), isTrue);
    }

    for (int r = 0; r < mapa.length; r += 2) {
      for (int c = 0; c < mapa[0].length; c += 2) {
        expect(mapa[r][c], '#');
      }
    }
  });
}