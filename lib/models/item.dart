enum TipoItem { chaveTempo, pocaoVelocidade }

class Item {
  final int linha;
  final int coluna;
  final TipoItem tipo;

  Item({required this.linha, required this.coluna, required this.tipo});
}