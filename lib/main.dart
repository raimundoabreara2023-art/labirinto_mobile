import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const LabirintoApp());
}

class LabirintoApp extends StatelessWidget {
  const LabirintoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'O Labirinto Vivo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF101510),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFC99A45),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const JogoScreen(),
    );
  }
}

class JogoScreen extends StatefulWidget {
  const JogoScreen({super.key});

  @override
  State<JogoScreen> createState() => _JogoScreenState();
}

class _JogoScreenState extends State<JogoScreen> {
  static const int linhas = 9;
  static const int colunas = 9;
  static const int movimentosPorMudanca = 3;

  static const List<String> mapaInicial = [
    '#########',
    '#P....T.#',
    '#.#####.#',
    '#.#...#.#',
    '#.#C#.#.#',
    '#...#...#',
    '###.###V#',
    '#...V..S#',
    '#########',
  ];

  static const List<List<List<int>>> transformacoes = [
    [
      [3, 2],
      [3, 3],
    ],
    [
      [4, 4],
      [5, 4],
    ],
    [
      [2, 4],
      [2, 5],
    ],
  ];

  late List<List<String>> mapa;
  int jogadorLinha = 1;
  int jogadorColuna = 1;
  
  int centauroLinha = 4;
  int centauroColuna = 3;

  int movimentos = 0;
  int movimentosParaMudanca = movimentosPorMudanca;
  int numeroTransformacao = 0;
  
  int turnosChaveTempo = 0;
  int turnosVelocidade = 0;

  bool venceu = false;
  bool gameOver = false;
  String mensagem = 'O labirinto respira... Use as setas do teclado ou os botões!';

  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _restaurarMapa();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _restaurarMapa() {
    mapa = mapaInicial.map((linha) => linha.split('')).toList();
    jogadorLinha = 1;
    jogadorColuna = 1;
    centauroLinha = 4;
    centauroColuna = 3;
  }

  void mover(int deltaLinha, int deltaColuna) {
    if (venceu || gameOver) return;

    final novaLinha = jogadorLinha + deltaLinha;
    final novaColuna = jogadorColuna + deltaColuna;

    if (novaLinha < 0 ||
        novaLinha >= linhas ||
        novaColuna < 0 ||
        novaColuna >= colunas ||
        mapa[novaLinha][novaColuna] == '#') {
      mensagem = 'Caminho bloqueado por parede!';
      setState(() {});
      return;
    }

    setState(() {
      jogadorLinha = novaLinha;
      jogadorColuna = novaColuna;
      movimentos++;

      if (mapa[jogadorLinha][jogadorColuna] == 'S') {
        venceu = true;
        mensagem = 'Você encontrou a saída e escapou da Fúria do Labirinto!';
        return;
      } else if (mapa[jogadorLinha][jogadorColuna] == 'T') {
        turnosChaveTempo = 6;
        mapa[jogadorLinha][jogadorColuna] = '.';
        mensagem = '🔑 Chave do Tempo coletada! Labirinto congelado por 6 turnos.';
      } else if (mapa[jogadorLinha][jogadorColuna] == 'V') {
        turnosVelocidade = 4;
        mapa[jogadorLinha][jogadorColuna] = '.';
        mensagem = '⚡ Poção de Velocidade! Seus passos estão mais ágeis.';
      }

      _moverCentauro();

      if (jogadorLinha == centauroLinha && jogadorColuna == centauroColuna) {
        gameOver = true;
        mensagem = 'O Centauro te alcançou! GAME OVER.';
        return;
      }

      if (turnosChaveTempo > 0) {
        turnosChaveTempo--;
        mensagem += ' (Tempo congelado: restam $turnosChaveTempo ativações)';
      } else {
        movimentosParaMudanca--;
        if (movimentosParaMudanca == 0) {
          _transformarLabirinto();
          movimentosParaMudanca = movimentosPorMudanca;
        }
      }

      if (turnosVelocidade > 0) {
        turnosVelocidade--;
      }
    });
  }

  void _moverCentauro() {
    int dLinha = 0;
    int dColuna = 0;

    if (centauroLinha < jogadorLinha) dLinha = 1;
    else if (centauroLinha > jogadorLinha) dLinha = -1;

    if (centauroColuna < jogadorColuna) dColuna = 1;
    else if (centauroColuna > jogadorColuna) dColuna = -1;

    int proximaL = centauroLinha + dLinha;
    int proximaC = centauroColuna;

    if (proximaL >= 0 && proximaL < linhas && mapa[proximaL][proximaC] != '#') {
      centauroLinha = proximaL;
    } else {
      int altC = centauroColuna + dColuna;
      if (altC >= 0 && altC < colunas && mapa[centauroLinha][altC] != '#') {
        centauroColuna = altC;
      }
    }
  }

  void _transformarLabirinto() {
    final transformacao =
        transformacoes[numeroTransformacao % transformacoes.length];

    final abrir = transformacao[0];
    final fechar = transformacao[1];

    if ((jogadorLinha == fechar[0] && jogadorColuna == fechar[1]) ||
        (centauroLinha == fechar[0] && centauroColuna == fechar[1])) {
      numeroTransformacao++;
      mensagem = 'O labirinto tentou se mover, mas há corpos bloqueando a passagem!';
      return;
    }

    mapa[abrir[0]][abrir[1]] = '.';
    mapa[fechar[0]][fechar[1]] = '#';
    numeroTransformacao++;
    mensagem = '⚠️ O labirinto se moveu (Estilo Fúria de Titãs)! As paredes mudaram de lugar.';
  }

  void reiniciar() {
    setState(() {
      _restaurarMapa();
      movimentos = 0;
      movimentosParaMudanca = movimentosPorMudanca;
      numeroTransformacao = 0;
      turnosChaveTempo = 0;
      turnosVelocidade = 0;
      venceu = false;
      gameOver = false;
      mensagem = 'Nova partida iniciada. Cuidado com o Centauro!';
    });
    // Re-foca no teclado após reiniciar
    FocusScope.of(context).requestFocus(_focusNode);
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowUp || 
          event.logicalKey == LogicalKeyboardKey.keyW) {
        mover(-1, 0);
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown || 
                 event.logicalKey == LogicalKeyboardKey.keyS) {
        mover(1, 0);
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft || 
                 event.logicalKey == LogicalKeyboardKey.keyA) {
        mover(0, -1);
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight || 
                 event.logicalKey == LogicalKeyboardKey.keyD) {
        mover(0, 1);
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    // Garante o foco no teclado ao abrir a tela
    FocusScope.of(context).requestFocus(_focusNode);

    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'O LABIRINTO VIVO',
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2),
          ),
          centerTitle: true,
          backgroundColor: const Color(0xFF20281E),
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final tamanho = (constraints.maxWidth - 32).clamp(0.0, 480.0).toDouble();

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Column(
                      children: [
                        Text(
                          mensagem,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.amberAccent, fontSize: 13),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            _indicador('MOVIMENTOS', '$movimentos'),
                            const SizedBox(width: 8),
                            _indicador('MUDA EM', venceu || gameOver ? '—' : '$movimentosParaMudanca'),
                            const SizedBox(width: 8),
                            _indicador('CHAVE TEMPO', turnosChaveTempo > 0 ? '$turnosChaveTempo' : 'OFF'),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: tamanho,
                          height: tamanho,
                          child: GridView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: linhas * colunas,
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: colunas,
                            ),
                            itemBuilder: (context, index) {
                              final linha = index ~/ colunas;
                              final coluna = index % colunas;
                              
                              final parede = mapa[linha][coluna] == '#';
                              final saida = mapa[linha][coluna] == 'S';
                              final chave = mapa[linha][coluna] == 'T';
                              final velocidade = mapa[linha][coluna] == 'V';
                              
                              final jogador = linha == jogadorLinha && coluna == jogadorColuna;
                              final centauro = linha == centauroLinha && coluna == centauroColuna;

                              Color corFundo = parede ? const Color(0xFF51564A) : const Color(0xFF202A20);
                              if (centauro) corFundo = Colors.red.withOpacity(0.4);

                              return Container(
                                margin: const EdgeInsets.all(1),
                                decoration: BoxDecoration(
                                  color: corFundo,
                                  border: Border.all(color: const Color(0xFF111711), width: 1),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Center(
                                  child: jogador
                                      ? const Icon(Icons.person, color: Colors.amber, size: 22)
                                      : centauro
                                          ? const Icon(Icons.pets, color: Colors.redAccent, size: 20)
                                          : saida
                                              ? const Icon(Icons.door_front_door, color: Colors.lightGreenAccent, size: 20)
                                              : chave
                                                  ? const Icon(Icons.key, color: Colors.cyanAccent, size: 18)
                                                  : velocidade
                                                      ? const Icon(Icons.bolt, color: Colors.yellowAccent, size: 18)
                                                      : parede
                                                          ? const Icon(Icons.texture, color: Colors.white12, size: 14)
                                                          : null,
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (venceu || gameOver)
                          Text(
                            venceu ? 'VOCÊ ESCAPOU!' : 'GAME OVER - O CENTAURO TE PEGOU',
                            key: const Key('resultado'),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: venceu ? Colors.greenAccent : Colors.redAccent,
                            ),
                          ),
                        const SizedBox(height: 12),
                        const Text('CONTROLES (SETAS OU W, A, S, D)', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2)),
                        const SizedBox(height: 10),
                        _linhaControles([
                          _botaoMovimento(Icons.arrow_upward, 'Mover para cima', () => mover(-1, 0)),
                        ]),
                        _linhaControles([
                          _botaoMovimento(Icons.arrow_back, 'Mover para esquerda', () => mover(0, -1)),
                          const SizedBox(width: 12),
                          _botaoMovimento(Icons.arrow_downward, 'Mover para baixo', () => mover(1, 0)),
                          const SizedBox(width: 12),
                          _botaoMovimento(Icons.arrow_forward, 'Mover para direita', () => mover(0, 1)),
                        ]),
                        const SizedBox(height: 14),
                        OutlinedButton.icon(
                          key: const Key('reiniciar'),
                          onPressed: reiniciar,
                          icon: const Icon(Icons.refresh),
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

  Widget _indicador(String titulo, String valor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF20281E),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          children: [
            Text(titulo, textAlign: TextAlign.center, style: const TextStyle(fontSize: 9, color: Colors.white60)),
            const SizedBox(height: 3),
            Text(valor, key: Key(titulo), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amber)),
          ],
        ),
      ),
    );
  }

  Widget _linhaControles(List<Widget> botoes) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: botoes),
    );
  }

  Widget _botaoMovimento(IconData icone, String descricao, VoidCallback acao) {
    return SizedBox(
      width: 60,
      height: 50,
      child: ElevatedButton(
        key: Key(descricao),
        onPressed: venceu || gameOver ? null : acao,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF394532),
          foregroundColor: Colors.white,
          padding: EdgeInsets.zero,
        ),
        child: Icon(icone),
      ),
    );
  }
}