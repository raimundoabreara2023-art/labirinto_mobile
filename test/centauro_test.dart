import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:labirinto_mobile/models/centauro.dart';
import 'package:labirinto_mobile/services/labirinto_service.dart';

void main() {
  final service = LabirintoService();

  test('o rastreador alcança um jogador parado sem atravessar paredes', () {
    final mapa = service.criarMapa();
    final centauro = Centauro(
      id: 1,
      estrategia: EstrategiaCentauro.rastreador,
      linha: 5,
      coluna: 8,
    );

    for (var i = 0; i < 30; i++) {
      centauro.perseguir(1, 1, mapa);
      expect(mapa[centauro.linha][centauro.coluna], isNot('#'));
    }

    expect(centauro.linha, 1);
    expect(centauro.coluna, 1);
  });

  test('o centauro nunca entra na célula de outro centauro', () {
    final mapa = service.criarMapa();
    final centauro = Centauro(
      id: 2,
      estrategia: EstrategiaCentauro.flanqueador,
      linha: 1,
      coluna: 3,
    );

    centauro.perseguir(1, 1, mapa, ocupadas: [const Point(1, 2)]);

    expect(Point(centauro.linha, centauro.coluna), isNot(const Point(1, 2)));
  });

    test('a posição visual desliza da célula anterior até a atual', () {
    final centauro = Centauro(
      id: 1,
      estrategia: EstrategiaCentauro.rastreador,
      linha: 1,
      coluna: 3,
    );
    centauro.moverPara(1, 4);

    final inicio = centauro.posicaoVisual(centauro.ultimoPasso);
    expect(inicio.coluna, closeTo(3.0, 0.01));

    final fim = centauro.posicaoVisual(
      centauro.ultimoPasso.add(Centauro.duracaoPasso),
    );
    expect(fim.coluna, closeTo(4.0, 0.01));
    expect(fim.linha, closeTo(1.0, 0.01));
  });

  test('o centauro só anima enquanto percorre um passo', () {
  final centauro = Centauro(
    id: 1,
    estrategia: EstrategiaCentauro.rastreador,
    linha: 1,
    coluna: 3,
  );

  expect(
    centauro.estaSeMovendo(DateTime.now()),
    isFalse,
  );

  centauro.moverPara(1, 4);

  expect(
    centauro.estaSeMovendo(centauro.ultimoPasso),
    isTrue,
  );

  expect(
    centauro.estaSeMovendo(
      centauro.ultimoPasso.add(Centauro.duracaoPasso),
    ),
    isFalse,
  );
});
}