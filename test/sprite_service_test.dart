import 'package:flutter_test/flutter_test.dart';
import 'package:labirinto_mobile/services/sprite_service.dart';

void main() {
  EstadoMinotauro estado(double distancia,
      {double fase = 0.0, bool andando = true, bool capturou = false}) {
    return SpriteService.estadoPara(
      fase: fase,
      distancia: distancia,
      andando: andando,
      capturou: capturou,
    );
  }

  test('longe, o minotauro anda', () {
    expect(estado(10), EstadoMinotauro.andando);
  });

  test('a média distância ele corre', () {
    expect(estado(4.5), EstadoMinotauro.corrida);
  });

  test('de perto ele ruge na primeira metade do ciclo e corre na segunda', () {
    expect(estado(2.5, fase: 0.2), EstadoMinotauro.rugido);
    expect(estado(2.5, fase: 0.8), EstadoMinotauro.corrida);
  });

  test('colado no jogador ele ataca', () {
    expect(estado(1.0), EstadoMinotauro.ataque);
  });

  test('com o tempo congelado ele fica parado', () {
    expect(estado(1.0, andando: false), EstadoMinotauro.parado);
    expect(estado(8.0, andando: false), EstadoMinotauro.parado);
  });

  test('no game over, o minotauro colado golpeia mesmo sem andar', () {
    expect(estado(1.0, andando: false, capturou: true), EstadoMinotauro.ataque);
  });
}