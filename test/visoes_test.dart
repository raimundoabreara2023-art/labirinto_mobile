import 'package:flutter_test/flutter_test.dart';
import 'package:labirinto_mobile/controllers/jogo_controller.dart';

void main() {
  test('virar gira a direção em ciclo', () {
    final controller = JogoController();
    expect(controller.direcao, 1);

    controller.virar(1);
    expect(controller.direcao, 2);
    controller.virar(1);
    controller.virar(1);
    expect(controller.direcao, 0);
    controller.virar(-1);
    expect(controller.direcao, 3);
  });

  test('avançar e recuar andam conforme a direção do olhar', () {
    final controller = JogoController();

    controller.avancar();
    expect(controller.jogador.coluna, 2);

    controller.recuar();
    expect(controller.jogador.coluna, 1);

    controller.virar(1); // agora olhando para baixo
    controller.avancar();
    expect(controller.jogador.linha, 2);
  });

  test('no mapa aéreo o jogo inteiro fica pausado', () {
    final controller = JogoController();
    List<String> posicoes() =>
        controller.centauros.map((c) => '${c.linha},${c.coluna}').toList();

    controller.alternarVisao();
    expect(controller.visaoAerea, isTrue);

    final antes = posicoes();
    controller.atualizarPerseguicaoCentauro();
    controller.avancar();
    controller.virar(1);

    expect(posicoes(), antes);
    expect(controller.jogador.coluna, 1);
    expect(controller.movimentos, 0);
    expect(controller.direcao, 1);

    controller.alternarVisao();
    controller.avancar();
    expect(controller.jogador.coluna, 2);
  });
}