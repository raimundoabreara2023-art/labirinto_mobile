import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../controllers/jogo_controller.dart';
import 'widgets/painel_status.dart';
import 'widgets/grid_labirinto.dart';
import 'widgets/visao_interna.dart';

class JogoScreen extends StatefulWidget {
  const JogoScreen({super.key});

  @override
  State<JogoScreen> createState() => _JogoScreenState();
}

class _JogoScreenState extends State<JogoScreen> {
  final JogoController _controller = JogoController();
  final FocusNode _focusNode = FocusNode();
  Timer? _timerCentauro;

  @override
  void initState() {
    super.initState();

    _timerCentauro = Timer.periodic(
      const Duration(milliseconds: 700),
      (_) {
        if (!mounted) return;

        setState(() {
          _controller.atualizarPerseguicaoCentauro();
        });
      },
    );
  }

  @override
  void dispose() {
    _timerCentauro?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  void _avancar() {
    setState(() {
      _controller.avancar();
    });
  }

  void _recuar() {
    setState(() {
      _controller.recuar();
    });
  }

  void _virar(int sentido) {
    setState(() {
      _controller.virar(sentido);
    });
  }

  void _alternarVisao() {
    setState(() {
      _controller.alternarVisao();
    });
    FocusScope.of(context).requestFocus(_focusNode);
  }

  void _reiniciar() {
    setState(() {
      _controller.reiniciar();
    });
    FocusScope.of(context).requestFocus(_focusNode);
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      final tecla = event.logicalKey;
      if (tecla == LogicalKeyboardKey.arrowUp || tecla == LogicalKeyboardKey.keyW) {
        _avancar();
        return KeyEventResult.handled;
      } else if (tecla == LogicalKeyboardKey.arrowDown ||
          tecla == LogicalKeyboardKey.keyS) {
        _recuar();
        return KeyEventResult.handled;
      } else if (tecla == LogicalKeyboardKey.arrowLeft ||
          tecla == LogicalKeyboardKey.keyA) {
        _virar(-1);
        return KeyEventResult.handled;
      } else if (tecla == LogicalKeyboardKey.arrowRight ||
          tecla == LogicalKeyboardKey.keyD) {
        _virar(1);
        return KeyEventResult.handled;
      } else if (tecla == LogicalKeyboardKey.keyM) {
        _alternarVisao();
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
              // Tela larga (computador): a visão interna ocupa tudo e o resto
              // fica numa coluna à direita. Tela estreita (celular) ou mapa
              // aéreo pausado: layout em coluna.
              final telaLarga =
                  constraints.maxWidth >= 900 && !_controller.visaoAerea;
              return telaLarga ? _layoutLargo() : _layoutEmColuna(constraints);
            },
          ),
        ),
      ),
    );
  }

  /// Computador: visão interna gigante + coluna lateral com mapa e controles.
  Widget _layoutLargo() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          _mensagem(),
          const SizedBox(height: 8),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, area) => VisaoInterna(
                      controller: _controller,
                      largura: area.maxWidth,
                      altura: area.maxHeight,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 280,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _painel(),
                        const SizedBox(height: 8),
                        _mapaGuia(260),
                        const SizedBox(height: 8),
                        _resultado(),
                        ..._controles(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Celular ou mapa aéreo: tudo em uma coluna rolável.
  Widget _layoutEmColuna(BoxConstraints constraints) {
    final aerea = _controller.visaoAerea;
    final larguraUtil = constraints.maxWidth - 24;

    // Mapa aéreo grande (jogo pausado).
    final tamanhoMaximo = min(larguraUtil, constraints.maxHeight - 190);
    final tamanhoGrid = tamanhoMaximo.clamp(320.0, 720.0).toDouble();

    // Visão interna com o mapa guia embaixo.
    final larguraVisao = min(larguraUtil, 520.0);
    final alturaVisao = larguraVisao * 0.7;
    final tamanhoMapa = min(larguraUtil, 220.0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(8),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 750),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _mensagem(),
              const SizedBox(height: 8),
              _painel(),
              const SizedBox(height: 10),
              if (aerea) ...[
                const Padding(
                  padding: EdgeInsets.only(bottom: 6),
                  child: Text(
                    'MAPA AÉREO — TUDO PAUSADO',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: Colors.cyanAccent,
                    ),
                  ),
                ),
                GridLabirinto(
                  controller: _controller,
                  tamanhoGrid: tamanhoGrid,
                ),
              ] else ...[
                VisaoInterna(
                  controller: _controller,
                  largura: larguraVisao,
                  altura: alturaVisao,
                ),
                const SizedBox(height: 10),
                _mapaGuia(tamanhoMapa),
              ],
              const SizedBox(height: 10),
              _resultado(),
              ..._controles(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mensagem() {
    return Text(
      _controller.mensagem,
      textAlign: TextAlign.center,
      style: const TextStyle(color: Colors.amberAccent, fontSize: 12),
    );
  }

  Widget _painel() {
    return PainelStatus(
      movimentos: _controller.movimentos,
      mudaEm: _controller.venceu || _controller.gameOver ? '—' : '${_controller.movimentosParaMudanca}',
      chaveTempo: _controller.turnosChaveTempo > 0 ? '${_controller.turnosChaveTempo}' : 'OFF',
    );
  }

  Widget _resultado() {
    if (!_controller.venceu && !_controller.gameOver) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        _controller.venceu ? 'VOCÊ ESCAPOU!' : 'GAME OVER - OS CENTAUROS TE PEGARAM',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: _controller.venceu ? Colors.greenAccent : Colors.redAccent,
        ),
      ),
    );
  }

  /// Mapa ao vivo que acompanha a visão interna como guia.
  Widget _mapaGuia(double tamanho) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'MAPA GUIA — AO VIVO',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: Colors.cyanAccent,
          ),
        ),
        const SizedBox(height: 4),
        GridLabirinto(controller: _controller, tamanhoGrid: tamanho),
      ],
    );
  }

  /// Botões de movimento, de visão e de reinício.
  List<Widget> _controles() {
    final aerea = _controller.visaoAerea;
    return [
      const SizedBox(height: 6),
      const Text(
        'W AVANÇAR · S RECUAR · A/D VIRAR · M PAUSAR E VER MAPA',
        textAlign: TextAlign.center,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1.2),
      ),
      const SizedBox(height: 4),
      _linhaControles([
        _botaoMovimento(Icons.arrow_upward, 'Avançar', _avancar),
      ]),
      _linhaControles([
        _botaoMovimento(Icons.rotate_left, 'Virar à esquerda', () => _virar(-1)),
        const SizedBox(width: 8),
        _botaoMovimento(Icons.arrow_downward, 'Recuar', _recuar),
        const SizedBox(width: 8),
        _botaoMovimento(Icons.rotate_right, 'Virar à direita', () => _virar(1)),
      ]),
      const SizedBox(height: 8),
      OutlinedButton.icon(
        key: const Key('alternar visao'),
        onPressed: _alternarVisao,
        icon: Icon(aerea ? Icons.explore : Icons.map, size: 16),
        label: Text(aerea ? 'VOLTAR AO LABIRINTO (M)' : 'PAUSAR E VER MAPA (M)'),
      ),
      const SizedBox(height: 6),
      OutlinedButton.icon(
        key: const Key('reiniciar'),
        onPressed: _reiniciar,
        icon: const Icon(Icons.refresh, size: 16),
        label: const Text('REINICIAR PARTIDA'),
      ),
    ];
  }

  Widget _linhaControles(List<Widget> botoes) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: botoes),
    );
  }

  Widget _botaoMovimento(IconData icone, String descricao, VoidCallback acao) {
    final bloqueado = _controller.venceu || _controller.gameOver || _controller.visaoAerea;
    return SizedBox(
      width: 50,
      height: 38,
      child: ElevatedButton(
        key: Key(descricao),
        onPressed: bloqueado ? null : acao,
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