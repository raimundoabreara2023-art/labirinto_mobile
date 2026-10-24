abstract class Entidade {
  int linha;
  int coluna;

  Entidade({required this.linha, required this.coluna});

  void moverPara(int novaLinha, int novaColuna) {
    linha = novaLinha;
    coluna = novaColuna;
  }
}