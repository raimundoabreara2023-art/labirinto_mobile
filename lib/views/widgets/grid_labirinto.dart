import 'package:flutter/material.dart';
import '../../controllers/jogo_controller.dart';
import '../../services/labirinto_service.dart';

class GridLabirinto extends StatelessWidget {
  final JogoController controller;
  final double tamanhoGrid;

  const GridLabirinto({
    super.key,
    required this.controller,
    required this.tamanhoGrid,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: tamanhoGrid,
      height: tamanhoGrid,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: LabirintoService.linhas * LabirintoService.colunas,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: LabirintoService.colunas,
        ),
        itemBuilder: (context, index) {
          final linha = index ~/ LabirintoService.colunas;
          final coluna = index % LabirintoService.colunas;

          final parede = controller.mapa[linha][coluna] == '#';
          final saida = controller.mapa[linha][coluna] == 'S';
          final chave = controller.mapa[linha][coluna] == 'T';
          final velocidade = controller.mapa[linha][coluna] == 'V';

          final jogador = linha == controller.jogador.linha && coluna == controller.jogador.coluna;
          final centauro = linha == controller.centauro.linha && coluna == controller.centauro.coluna;

          Color corFundo = parede ? const Color(0xFF51564A) : const Color(0xFF202A20);
          if (centauro) corFundo = Colors.red.withValues(alpha: 0.4);

          return Container(
            margin: const EdgeInsets.all(0.3),
            decoration: BoxDecoration(
              color: corFundo,
              border: Border.all(color: const Color(0xFF111711), width: 0.3),
              borderRadius: BorderRadius.circular(1.5),
            ),
            child: Center(
              child: jogador
                  ? const Icon(Icons.person, color: Colors.amber, size: 13)
                  : centauro
                      ? const Icon(Icons.pets, color: Colors.redAccent, size: 12)
                      : saida
                          ? const Icon(Icons.door_front_door, color: Colors.lightGreenAccent, size: 12)
                          : chave
                              ? const Icon(Icons.key, color: Colors.cyanAccent, size: 10)
                              : velocidade
                                  ? const Icon(Icons.bolt, color: Colors.yellowAccent, size: 10)
                                  : parede
                                      ? const Icon(Icons.texture, color: Colors.white12, size: 7)
                                      : null,
            ),
          );
        },
      ),
    );
  }
}