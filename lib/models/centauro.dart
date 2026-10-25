import 'dart:collection';
import 'dart:math';

import 'entidade.dart';

/// Estratégia usada por cada centauro para evitar que os três sigam em fila.
enum EstrategiaCentauro {
  rastreador,
  flanqueador,
  interceptador,
}

/// Um inimigo que calcula sua própria rota pelo labirinto.
class Centauro extends Entidade {
  final int id;
  final EstrategiaCentauro estrategia;

  Centauro({
    required this.id,
    required this.estrategia,
    required super.linha,
    required super.coluna,
  });

  /// Calcula e executa um passo.
  ///
  /// [ocupadas] contém as posições dos outros centauros. O jogador não deve
  /// ser incluído nessa lista, pois o rastreador precisa conseguir capturá-lo.
  void perseguir(
    int jogadorLinha,
    int jogadorColuna,
    List<List<String>> mapa, {
    List<Point<int>> ocupadas = const [],
    Point<int>? alvoPrevisto,
  }) {
    final inicio = Point<int>(linha, coluna);
    final jogador = Point<int>(jogadorLinha, jogadorColuna);
    final bloqueadas = ocupadas.where((p) => p != inicio).toSet();

    if (inicio == jogador) return;

    switch (estrategia) {
      case EstrategiaCentauro.rastreador:
        // Procura capturar o jogador pelo menor caminho disponível.
        final passo = _primeiroPasso(inicio, jogador, mapa, bloqueadas);
        if (passo != null) moverPara(passo.x, passo.y);
        break;

      case EstrategiaCentauro.flanqueador:
        // Tenta ocupar uma célula adjacente ao jogador, aproximando-se por
        // outro lado em vez de escolher sempre a célula do próprio jogador.
        final alvos = _vizinhos(jogador, mapa)
            .where((p) => !bloqueadas.contains(p))
            .toList();

        Point<int>? melhorAlvo;
        Point<int>? melhorPasso;
        var menorDistancia = 1 << 30;

        for (final alvo in alvos) {
          final passo = _primeiroPasso(inicio, alvo, mapa, bloqueadas);
          if (passo == null) continue;

          final distancia = _distancia(inicio, alvo, mapa, bloqueadas);
          if (distancia < menorDistancia) {
            menorDistancia = distancia;
            melhorAlvo = alvo;
            melhorPasso = passo;
          }
        }

        if (melhorAlvo != null && melhorPasso != null) {
          moverPara(melhorPasso.x, melhorPasso.y);
        }
        break;

      case EstrategiaCentauro.interceptador:
        // Tenta ocupar a próxima posição provável do jogador. Se ela não for
        // viável, volta a perseguir a posição atual.
        final alvo = alvoPrevisto != null &&
                _celulaLivre(alvoPrevisto, mapa) &&
                !bloqueadas.contains(alvoPrevisto)
            ? alvoPrevisto
            : jogador;

        final passo = _primeiroPasso(inicio, alvo, mapa, bloqueadas);
        if (passo != null) moverPara(passo.x, passo.y);
        break;
    }
  }

  List<Point<int>> _vizinhos(Point<int> ponto, List<List<String>> mapa) {
    const direcoes = <Point<int>>[
      Point(-1, 0),
      Point(1, 0),
      Point(0, -1),
      Point(0, 1),
    ];

    return direcoes
        .map((d) => Point<int>(ponto.x + d.x, ponto.y + d.y))
        .where((p) => _celulaLivre(p, mapa))
        .toList();
  }

  bool _celulaLivre(Point<int> p, List<List<String>> mapa) {
    return p.x >= 0 &&
        p.x < mapa.length &&
        p.y >= 0 &&
        p.y < mapa[0].length &&
        mapa[p.x][p.y] != '#';
  }

  /// Retorna o primeiro passo de uma rota BFS até [destino].
  Point<int>? _primeiroPasso(
    Point<int> inicio,
    Point<int> destino,
    List<List<String>> mapa,
    Set<Point<int>> bloqueadas,
  ) {
    if (!_celulaLivre(destino, mapa) && destino != inicio) return null;
    if (bloqueadas.contains(destino)) return null;
    if (inicio == destino) return null;

    final fila = Queue<Point<int>>()..add(inicio);
    final anterior = <Point<int>, Point<int>?>{inicio: null};
    const direcoes = <Point<int>>[
      Point(-1, 0),
      Point(1, 0),
      Point(0, -1),
      Point(0, 1),
    ];

    while (fila.isNotEmpty) {
      final atual = fila.removeFirst();
      if (atual == destino) break;

      for (final d in direcoes) {
        final proxima = Point<int>(atual.x + d.x, atual.y + d.y);
        if (!_celulaLivre(proxima, mapa) ||
            bloqueadas.contains(proxima) ||
            anterior.containsKey(proxima)) {
          continue;
        }
        anterior[proxima] = atual;
        fila.add(proxima);
      }
    }

    if (!anterior.containsKey(destino)) return null;

    var passo = destino;
    while (anterior[passo] != inicio) {
      final pai = anterior[passo];
      if (pai == null) return null;
      passo = pai;
    }
    return passo;
  }

  int _distancia(
    Point<int> inicio,
    Point<int> destino,
    List<List<String>> mapa,
    Set<Point<int>> bloqueadas,
  ) {
    final fila = Queue<Point<int>>()..add(inicio);
    final distancias = <Point<int>, int>{inicio: 0};
    const direcoes = <Point<int>>[
      Point(-1, 0),
      Point(1, 0),
      Point(0, -1),
      Point(0, 1),
    ];

    while (fila.isNotEmpty) {
      final atual = fila.removeFirst();
      if (atual == destino) return distancias[atual]!;

      for (final d in direcoes) {
        final proxima = Point<int>(atual.x + d.x, atual.y + d.y);
        if (!_celulaLivre(proxima, mapa) ||
            bloqueadas.contains(proxima) ||
            distancias.containsKey(proxima)) {
          continue;
        }
        distancias[proxima] = distancias[atual]! + 1;
        fila.add(proxima);
      }
    }

    return 1 << 30;
  }
}
