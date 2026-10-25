import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:labirinto_mobile/controllers/jogo_controller.dart';
import 'package:labirinto_mobile/services/labirinto_service.dart';

void main() {
  test('com o tempo congelado os centauros não se movem', () {
    final controller = JogoController();
    List<String> posicoes() =>
        controller.centauros.map((c) => '${c.linha},${c.coluna}').toList();

    controller.turnosChaveTempo = 3;
    final antes = posicoes();
    controller.atualizarPerseguicaoCentauro();
    expect(posicoes(), antes);

    controller.turnosChaveTempo = 0;
    controller.atualizarPerseguicaoCentauro();
    expect(posicoes(), isNot(equals(antes)));
  });

  test('a chave do tempo congela por 6 movimentos e depois acaba', () {
    final controller = JogoController();
    controller.jogador.moverPara(1, 7);

    controller.mover(0, 1); // pega a chave em (1, 8)
    expect(controller.turnosChaveTempo, 6);

    for (var i = 0; i < 6; i++) {
      controller.mover(0, i.isEven ? -1 : 1);
    }

    expect(controller.turnosChaveTempo, 0);
    expect(controller.gameOver, isFalse);
  });

  test('o labirinto não fecha parede em cima de outros centauros', () {
    final service = LabirintoService();
    final mapa = service.criarMapa();
    final random = Random(7);

    for (var i = 0; i < 200; i++) {
      service.transformarDinamico(
        mapa,
        1,
        1,
        5,
        8,
        random,
        outrasOcupadas: const [Point(2, 7)],
      );
      expect(mapa[2][7], '.');
    }
  });
}