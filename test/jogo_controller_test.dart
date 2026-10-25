import 'package:flutter_test/flutter_test.dart';
import 'package:labirinto_mobile/controllers/jogo_controller.dart';
import 'package:labirinto_mobile/models/centauro.dart';

void main() {
  test('jogador que entra na célula de um centauro perde', () {
    final controller = JogoController();
    controller.centauros = [
      Centauro(
        id: 1,
        estrategia: EstrategiaCentauro.rastreador,
        linha: 1,
        coluna: 2,
      ),
    ];

    controller.mover(0, 1);

    expect(controller.gameOver, isTrue);
  });

  test('centauro que chega até o jogador causa game over', () {
    final controller = JogoController();
    controller.centauros = [
      Centauro(
        id: 1,
        estrategia: EstrategiaCentauro.rastreador,
        linha: 1,
        coluna: 3,
      ),
    ];

    controller.atualizarPerseguicaoCentauro();
    expect(controller.gameOver, isFalse);

    controller.atualizarPerseguicaoCentauro();
    expect(controller.gameOver, isTrue);
  });
}