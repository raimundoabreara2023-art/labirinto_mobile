import 'dart:math';

class LabirintoService {
  static const int linhas = 21;
  static const int colunas = 21;

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
    return mapaInicial.map((linha) => linha.split('')).toList();
  }

  void transformarDinamico(List<List<String>> mapa, int jogadorLinha, int jogadorColuna, int centauroLinha, int centauroColuna, Random random) {
    List<Point<int>> paredesInternas = [];
    List<Point<int>> corredoresInternos = [];

    for (int r = 1; r < linhas - 1; r++) {
      for (int c = 1; c < colunas - 1; c++) {
        if ((r == jogadorLinha && c == jogadorColuna) ||
            (r == centauroLinha && c == centauroColuna) ||
            mapa[r][c] == 'S') {
          continue;
        }

        if (mapa[r][c] == '#') {
          paredesInternas.add(Point(r, c));
        } else if (mapa[r][c] == '.') {
          corredoresInternos.add(Point(r, c));
        }
      }
    }

    if (paredesInternas.isNotEmpty && corredoresInternos.isNotEmpty) {
      final paredeParaAbrir = paredesInternas[random.nextInt(paredesInternas.length)];
      final corredorParaFechar = corredoresInternos[random.nextInt(corredoresInternos.length)];

      mapa[paredeParaAbrir.x][paredeParaAbrir.y] = '.';
      mapa[corredorParaFechar.x][corredorParaFechar.y] = '#';
    }
  }
}