import 'package:flutter/material.dart';

class PainelStatus extends StatelessWidget {
  final int movimentos;
  final String mudaEm;
  final String chaveTempo;

  const PainelStatus({
    super.key,
    required this.movimentos,
    required this.mudaEm,
    required this.chaveTempo,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _indicador('MOVIMENTOS', '$movimentos'),
        const SizedBox(width: 6),
        _indicador('MUDA EM', mudaEm),
        const SizedBox(width: 6),
        _indicador('CHAVE TEMPO', chaveTempo),
      ],
    );
  }

  Widget _indicador(String titulo, String valor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: const Color(0xFF20281E),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          children: [
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 8, color: Colors.white60),
            ),
            const SizedBox(height: 2),
            Text(
              valor,
              key: Key(titulo),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.amber,
              ),
            ),
          ],
        ),
      ),
    );
  }
}