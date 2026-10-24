
import 'dart:collection';
import 'dart:math';

import 'entidade.dart';

/// Representa o Centauro, responsável por perseguir o jogador
/// pelos corredores livres do labirinto.
class Centauro extends Entidade {
  Centauro({required super.linha, required super.coluna});

  /// Tenta avançar uma célula em direção ao jogador,
  /// utilizando o menor caminho disponível.
  ///
  /// Se não existir uma rota livre, o Centauro permanece parado.
  void perseguir(
    int jogadorLinha,
    int jogadorColuna,
    List<List<String>> mapa,
  ) {
    final inicio = Point<int>(linha, coluna);
    final destino = Point<int>(jogadorLinha, jogadorColuna);

    if (inicio == destino) return;

    final fila = Queue<Point<int>>();
    final visitados = <Point<int>>{inicio};

    // Registra de qual posição cada célula foi alcançada.
    final anterior = <Point<int>, Point<int>?>{
      inicio: null,
    };

    const direcoes = <Point<int>>[
      Point(-1, 0), // Cima
      Point(1, 0),  // Baixo
      Point(0, -1), // Esquerda
      Point(0, 1),  // Direita
    ];

    fila.add(inicio);

    while (fila.isNotEmpty) {
      final atual = fila.removeFirst();

      if (atual == destino) break;

      for (final direcao in direcoes) {
        final novaLinha = atual.x + direcao.x;
        final novaColuna = atual.y + direcao.y;

        if (novaLinha < 0 ||
            novaLinha >= mapa.length ||
            novaColuna < 0 ||
            novaColuna >= mapa[0].length) {
          continue;
        }

        // O Centauro só pode atravessar células sem paredes.
        if (mapa[novaLinha][novaColuna] == '#') {
          continue;
        }

        final proxima = Point<int>(novaLinha, novaColuna);

        if (visitados.contains(proxima)) continue;

        visitados.add(proxima);
        anterior[proxima] = atual;
        fila.add(proxima);
      }
    }

    // Não existe caminho até o jogador neste momento.
    if (!visitados.contains(destino)) return;

    // Reconstrói a rota de trás para frente até encontrar
    // a primeira célula à frente do Centauro.
    var passo = destino;

    while (anterior[passo] != inicio) {
      final pai = anterior[passo];

      if (pai == null) return;

      passo = pai;
    }

    moverPara(passo.x, passo.y);
  }
}
