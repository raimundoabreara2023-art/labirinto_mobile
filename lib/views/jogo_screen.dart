import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../controllers/jogo_controller.dart';
import 'widgets/painel_status.dart';
import 'widgets/grid_labirinto.dart';

class JogoScreen extends StatefulWidget {
  const JogoScreen({super.key});

  @override
  State<JogoScreen> createState() => _JogoScreenState();
}

class _JogoScreenState extends State<JogoScreen> {
  final JogoController _controller = JogoController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _mover(int dL, int dC) {
    setState(() {
      _controller.mover(dL, dC);
    });
  }

  void _reiniciar() {
    setState(() {
      _controller.reiniciar();
    });
    FocusScope.of(context).requestFocus(_focusNode);
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowUp ||
          event.logicalKey == LogicalKeyboardKey.keyW) {
        _mover(-1, 0);
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown ||
                 event.logicalKey == LogicalKeyboardKey.keyS) {
        _mover(1, 0);
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
                 event.logicalKey == LogicalKeyboardKey.keyA) {
        _mover(0, -1);
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight ||
                 event.logicalKey == LogicalKeyboardKey.keyD) {
        _mover(0, 1);
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    FocusScope.of(context).requestFocus(_focusNode);

    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'O LABIRINTO VIVO — ARQUITETURA POO',
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2),
          ),
          centerTitle: true,
          backgroundColor: const Color(0xFF20281E),
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final tamanhoMaximo = min(constraints.maxWidth - 24, constraints.maxHeight - 190);
              final tamanhoGrid = tamanhoMaximo.clamp(320.0, 720.0).toDouble();

              return SingleChildScrollView(
                padding: const EdgeInsets.all(8),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 750),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _controller.mensagem,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.amberAccent, fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        PainelStatus(
                          movimentos: _controller.movimentos,
                          mudaEm: _controller.venceu || _controller.gameOver ? '—' : '${_controller.movimentosParaMudanca}',
                          chaveTempo: _controller.turnosChaveTempo > 0 ? '${_controller.turnosChaveTempo}' : 'OFF',
                        ),
                        const SizedBox(height: 10),
                        GridLabirinto(
                          controller: _controller,
                          tamanhoGrid: tamanhoGrid,
                        ),
                        const SizedBox(height: 10),
                        if (_controller.venceu || _controller.gameOver)
                          Text(
                            _controller.venceu ? 'VOCÊ ESCAPOU!' : 'GAME OVER - O CENTAURO TE PEGOU',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _controller.venceu ? Colors.greenAccent : Colors.redAccent,
                            ),
                          ),
                        const SizedBox(height: 6),
                        const Text(
                          'CONTROLES (SETAS OU W, A, S, D)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1.2),
                        ),
                        const SizedBox(height: 4),
                        _linhaControles([
                          _botaoMovimento(Icons.arrow_upward, 'Mover para cima', () => _mover(-1, 0)),
                        ]),
                        _linhaControles([
                          _botaoMovimento(Icons.arrow_back, 'Mover para esquerda', () => _mover(0, -1)),
                          const SizedBox(width: 8),
                          _botaoMovimento(Icons.arrow_downward, 'Mover para baixo', () => _mover(1, 0)),
                          const SizedBox(width: 8),
                          _botaoMovimento(Icons.arrow_forward, 'Mover para direita', () => _mover(0, 1)),
                        ]),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          key: const Key('reiniciar'),
                          onPressed: _reiniciar,
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text('REINICIAR PARTIDA'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _linhaControles(List<Widget> botoes) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: botoes),
    );
  }

  Widget _botaoMovimento(IconData icone, String descricao, VoidCallback acao) {
    return SizedBox(
      width: 50,
      height: 38,
      child: ElevatedButton(
        key: Key(descricao),
        onPressed: _controller.venceu || _controller.gameOver ? null : acao,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF394532),
          foregroundColor: Colors.white,
          padding: EdgeInsets.zero,
        ),
        child: Icon(icone, size: 18),
      ),
    );
  }
}