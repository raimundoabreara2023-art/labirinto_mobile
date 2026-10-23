import 'package:flutter/material.dart';

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

  // # = parede, . = corredor, P = jogador e S = saída.
  // Este mapa possui um caminho contínuo entre o início e a saída.
  static const List<String> mapaInicial = [
    '#########',
    '#P......#',
    '#.#####.#',
    '#.#...#.#',
    '#.#.#.#.#',
    '#...#...#',
    '###.###.#',
    '#......S#',
    '#########',
  ];

  // Cada transformação troca um par de células: uma abre e outra fecha.
  // As posições foram escolhidas para criar alternativas sem alterar
  // as bordas, o início ou a saída.
  static const List<List<List<int>>> transformacoes = [
    [
      [3, 2], // abre uma passagem
      [3, 3], // fecha uma passagem alternativa
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
  int movimentos = 0;
  int movimentosParaMudanca = movimentosPorMudanca;
  int numeroTransformacao = 0;
  bool venceu = false;
  bool gameOver = false;
  String mensagem = 'Cada escolha aproxima você do perigo.';

  @override
  void initState() {
    super.initState();
    _restaurarMapa();
  }

  void _restaurarMapa() {
    mapa = mapaInicial.map((linha) => linha.split('')).toList();
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
      return;
    }

    setState(() {
      jogadorLinha = novaLinha;
      jogadorColuna = novaColuna;
      movimentos++;

      if (mapa[jogadorLinha][jogadorColuna] == 'S') {
        venceu = true;
        mensagem = 'Você encontrou a saída do labirinto.';
        return;
      }

      movimentosParaMudanca--;

      if (movimentosParaMudanca == 0) {
        _transformarLabirinto();
        movimentosParaMudanca = movimentosPorMudanca;
      }
    });
  }

  void _transformarLabirinto() {
    final transformacao =
        transformacoes[numeroTransformacao % transformacoes.length];

    final abrir = transformacao[0];
    final fechar = transformacao[1];

    // Nunca fecha a célula ocupada pelo jogador.
    if (jogadorLinha == fechar[0] && jogadorColuna == fechar[1]) {
      // Se o jogador estiver na célula que seria fechada, apenas inverte
      // a ordem de transformação para a próxima jogada.
      numeroTransformacao++;
      mensagem = 'O labirinto treme, mas a passagem permanece aberta!';
      return;
    }

    mapa[abrir[0]][abrir[1]] = '.';
    mapa[fechar[0]][fechar[1]] = '#';
    numeroTransformacao++;
    mensagem = 'O labirinto se moveu! Encontre uma nova rota.';
  }

  void reiniciar() {
    setState(() {
      _restaurarMapa();
      jogadorLinha = 1;
      jogadorColuna = 1;
      movimentos = 0;
      movimentosParaMudanca = movimentosPorMudanca;
      numeroTransformacao = 0;
      venceu = false;
      gameOver = false;
      mensagem = 'Cada escolha aproxima você do perigo.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'O LABIRINTO VIVO',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF20281E),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final tamanho = (constraints.maxWidth - 32)
                .clamp(0.0, 480.0)
                .toDouble();

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    children: [
                      const Text(
                        'ENCONTRE A SAÍDA',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        mensagem,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          _indicador('MOVIMENTOS', '$movimentos'),
                          const SizedBox(width: 12),
                          _indicador(
                            'PRÓXIMA MUDANÇA',
                            venceu || gameOver
                                ? '—'
                                : '$movimentosParaMudanca',
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: tamanho,
                        height: tamanho,
                        child: GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: linhas * colunas,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: colunas,
                          ),
                          itemBuilder: (context, index) {
                            final linha = index ~/ colunas;
                            final coluna = index % colunas;
                            final parede = mapa[linha][coluna] == '#';
                            final saida = mapa[linha][coluna] == 'S';
                            final jogador = linha == jogadorLinha &&
                                coluna == jogadorColuna;

                            return Container(
                              margin: const EdgeInsets.all(1),
                              decoration: BoxDecoration(
                                color: parede
                                    ? const Color(0xFF51564A)
                                    : const Color(0xFF202A20),
                                border: Border.all(
                                  color: const Color(0xFF111711),
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Center(
                                child: jogador
                                    ? const Icon(
                                        Icons.person,
                                        color: Colors.amber,
                                        size: 24,
                                      )
                                    : saida
                                        ? const Icon(
                                            Icons.door_front_door,
                                            color: Colors.lightGreenAccent,
                                            size: 22,
                                          )
                                        : parede
                                            ? const Icon(
                                                Icons.texture,
                                                color: Colors.white12,
                                                size: 15,
                                              )
                                            : null,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (venceu || gameOver)
                        Text(
                          venceu ? 'VOCÊ ESCAPOU!' : 'GAME OVER',
                          key: const Key('resultado'),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber,
                          ),
                        ),
                      const SizedBox(height: 12),
                      const Text(
                        'CONTROLES',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _linhaControles([
                        _botaoMovimento(
                          Icons.arrow_upward,
                          'Mover para cima',
                          () => mover(-1, 0),
                        ),
                      ]),
                      _linhaControles([
                        _botaoMovimento(
                          Icons.arrow_back,
                          'Mover para esquerda',
                          () => mover(0, -1),
                        ),
                        const SizedBox(width: 12),
                        _botaoMovimento(
                          Icons.arrow_downward,
                          'Mover para baixo',
                          () => mover(1, 0),
                        ),
                        const SizedBox(width: 12),
                        _botaoMovimento(
                          Icons.arrow_forward,
                          'Mover para direita',
                          () => mover(0, 1),
                        ),
                      ]),
                      const SizedBox(height: 18),
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
    );
  }

  Widget _indicador(String titulo, String valor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF20281E),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          children: [
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, color: Colors.white60),
            ),
            const SizedBox(height: 5),
            Text(
              valor,
              key: Key(titulo),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.amber,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _linhaControles(List<Widget> botoes) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: botoes,
      ),
    );
  }

  Widget _botaoMovimento(
    IconData icone,
    String descricao,
    VoidCallback acao,
  ) {
    return SizedBox(
      width: 64,
      height: 54,
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
