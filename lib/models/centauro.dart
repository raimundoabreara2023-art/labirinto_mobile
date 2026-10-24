import 'entidade.dart';

class Centauro extends Entidade {
  Centauro({required super.linha, required super.coluna});

  void perseguir(int jogadorLinha, int jogadorColuna, List<List<String>> mapa) {
    int dLinha = 0;
    int dColuna = 0;

    if (linha < jogadorLinha) {
      dLinha = 1;
    } else if (linha > jogadorLinha) {
      dLinha = -1;
    }

    if (coluna < jogadorColuna) {
      dColuna = 1;
    } else if (coluna > jogadorColuna) {
      dColuna = -1;
    }

    final proximaL = linha + dLinha;

    if (proximaL >= 0 && proximaL < mapa.length && mapa[proximaL][coluna] != '#') {
      linha = proximaL;
    } else {
      final altC = coluna + dColuna;
      if (altC >= 0 && altC < mapa[0].length && mapa[linha][altC] != '#') {
        coluna = altC;
      }
    }
  }
}