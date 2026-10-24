import 'dart:collection';
import 'dart:math';

class LabirintoService {
  static const int linhas = 21;
  static const int colunas = 21;
  static const int tentativasMaximas = 60;

  static const List<String> mapaInicial = [
    '#####################',
    '#P......T.....#.....#',
    '#.#####.#####.#.###.#',
    '#.#...#.#...#.#.#.#.#',
    '#.#.#.#.#.#.#.#.#.#.#',
    '#...#...C...#...#...#',
    '###.###.###.###.###.#',
    '#...#.......S.#...#.#',
    '###.###.###.###.###.#',
    '#.#.....V...#.#...#.#',
    '#.#.###.###.#.#.###.#',
    '#.#.#...#...#.#.#...#',
    '#.#.#####.###.#####.#',
    '#.............#.....#',
    '#.###########.#####.#',
    '#.#.........#.....#.#',
    '#.#.#######.#####.#.#',
    '#.#.......#.....#.#.#',
    '#.#######.#####.#.#.#',
    '#.#.............#...#',
    '#####################',
  ];

  List<List<String>> criarMapa() {
    return mapaInicial
        .map((linha) => linha.replaceAll('P', '.').replaceAll('C', '.').split(''))
        .toList();
  }

  /// Diz se existe caminho livre (sem paredes) da posição informada até a saída 'S'.
  bool existeCaminho(List<List<String>> mapa, int linhaInicial, int colunaInicial) {
    final totalLinhas = mapa.length;
    final totalColunas = mapa[0].length;
    final visitado = List.generate(
      totalLinhas,
      (_) => List.filled(totalColunas, false),
    );
    final fila = Queue<Point<int>>();
    const direcoes = <Point<int>>[
      Point(-1, 0),
      Point(1, 0),
      Point(0, -1),
      Point(0, 1),
    ];

    visitado[linhaInicial][colunaInicial] = true;
    fila.add(Point(linhaInicial, colunaInicial));

    while (fila.isNotEmpty) {
      final atual = fila.removeFirst();

      if (mapa[atual.x][atual.y] == 'S') {
        return true;
      }

      for (final d in direcoes) {
        final novaLinha = atual.x + d.x;
        final novaColuna = atual.y + d.y;

        if (novaLinha < 0 ||
            novaLinha >= totalLinhas ||
            novaColuna < 0 ||
            novaColuna >= totalColunas) {
          continue;
        }
        if (visitado[novaLinha][novaColuna] || mapa[novaLinha][novaColuna] == '#') {
          continue;
        }

        visitado[novaLinha][novaColuna] = true;
        fila.add(Point(novaLinha, novaColuna));
      }
    }

    return false;
  }

  /// Troca uma parede por um corredor (e vice-versa), mexendo só nas passagens
  /// e mantendo a troca apenas se ainda existir caminho até a saída.
  /// Retorna true se o labirinto mudou.
  bool transformarDinamico(
    List<List<String>> mapa,
    int jogadorLinha,
    int jogadorColuna,
    int centauroLinha,
    int centauroColuna,
    Random random,
  ) {
    final totalLinhas = mapa.length;
    final totalColunas = mapa[0].length;
    final paredes = <Point<int>>[];
    final corredores = <Point<int>>[];

    for (int r = 1; r < totalLinhas - 1; r++) {
      for (int c = 1; c < totalColunas - 1; c++) {
        // Pilares (linha e coluna pares) e cruzamentos (ímpares) ficam fixos.
        if ((r + c) % 2 == 0) {
          continue;
        }
        if ((r == jogadorLinha && c == jogadorColuna) ||
            (r == centauroLinha && c == centauroColuna)) {
          continue;
        }

        if (mapa[r][c] == '#') {
          paredes.add(Point(r, c));
        } else if (mapa[r][c] == '.') {
          corredores.add(Point(r, c));
        }
      }
    }

    if (paredes.isEmpty || corredores.isEmpty) {
      return false;
    }

    for (int tentativa = 0; tentativa < tentativasMaximas; tentativa++) {
      final abrir = paredes[random.nextInt(paredes.length)];
      final fechar = corredores[random.nextInt(corredores.length)];

      mapa[abrir.x][abrir.y] = '.';
      mapa[fechar.x][fechar.y] = '#';

      if (existeCaminho(mapa, jogadorLinha, jogadorColuna)) {
        return true;
      }

      // Fechou a única rota: desfaz a troca e tenta outra.
      mapa[abrir.x][abrir.y] = '#';
      mapa[fechar.x][fechar.y] = '.';
    }

    return false;
  }
}