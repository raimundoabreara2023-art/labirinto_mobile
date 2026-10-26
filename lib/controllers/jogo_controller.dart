import 'dart:math';

import '../models/jogador.dart';
import '../models/centauro.dart';
import '../services/labirinto_service.dart';

class JogoController {
  final LabirintoService _labirintoService = LabirintoService();

  late List<List<String>> mapa;
  late Jogador jogador;
  late List<Centauro> centauros;

  /// Mantém o primeiro centauro disponível para compatibilidade com trechos
  /// do projeto que ainda consultem a propriedade singular.
  Centauro get centauro => centauros.first;

  int movimentos = 0;
  int movimentosParaMudanca = 3;
  int turnosChaveTempo = 0;
  int turnosVelocidade = 0;

  bool venceu = false;
  bool gameOver = false;
  String mensagem = 'Labirinto Vivo e Dinâmico! Cuidado com os Centauros.';

  /// true = mapa aéreo (tudo pausado); false = visão interna (primeira pessoa).
  bool visaoAerea = false;

  /// Para onde o jogador olha: 0 = cima, 1 = direita, 2 = baixo, 3 = esquerda.
  int direcao = 1;

  static const List<int> _deltaLinhaPorDirecao = [-1, 0, 1, 0];
  static const List<int> _deltaColunaPorDirecao = [0, 1, 0, -1];

  int get direcaoLinha => _deltaLinhaPorDirecao[direcao];
  int get direcaoColuna => _deltaColunaPorDirecao[direcao];

  final Random _random = Random();
  int _ultimaDirecaoLinha = 0;
  int _ultimaDirecaoColuna = 0;

  JogoController() {
    reiniciar();
  }

  /// Enquanto a chave do tempo está ativa, labirinto e centauros ficam parados.
  bool get tempoCongelado => turnosChaveTempo > 0;

  void reiniciar() {
    mapa = _labirintoService.criarMapa();
    jogador = Jogador(linha: 1, coluna: 1);

    // Posições iniciais distintas e em corredores livres do mapa atual.
    centauros = [
      Centauro(
        id: 1,
        estrategia: EstrategiaCentauro.rastreador,
        linha: 5,
        coluna: 8,
      ),
      Centauro(
        id: 2,
        estrategia: EstrategiaCentauro.flanqueador,
        linha: 9,
        coluna: 9,
      ),
      Centauro(
        id: 3,
        estrategia: EstrategiaCentauro.interceptador,
        linha: 13,
        coluna: 2,
      ),
    ];

    movimentos = 0;
    movimentosParaMudanca = 3;
    turnosChaveTempo = 0;
    turnosVelocidade = 0;
    _ultimaDirecaoLinha = 0;
    _ultimaDirecaoColuna = 0;
    direcao = 1;
    visaoAerea = false;
    venceu = false;
    gameOver = false;
    mensagem = 'Nova partida iniciada. Três centauros estão à sua caça!';
  }

  /// Alterna entre a visão interna e o mapa aéreo (que pausa o jogo).
  void alternarVisao() {
    visaoAerea = !visaoAerea;
    mensagem = visaoAerea
        ? 'Visão aérea: o tempo parou.'
        : 'De volta ao labirinto. Os centauros voltaram a caçar!';
  }

  /// Vira o jogador: +1 para a direita, -1 para a esquerda.
  void virar(int sentido) {
    if (venceu || gameOver || visaoAerea) return;
    direcao = (direcao + sentido) % 4;
  }

  void avancar() => mover(direcaoLinha, direcaoColuna);

  void recuar() => mover(-direcaoLinha, -direcaoColuna);

  void mover(int deltaLinha, int deltaColuna) {
    if (venceu || gameOver || visaoAerea) return;

    final novaLinha = jogador.linha + deltaLinha;
    final novaColuna = jogador.coluna + deltaColuna;

    if (novaLinha < 0 ||
        novaLinha >= LabirintoService.linhas ||
        novaColuna < 0 ||
        novaColuna >= LabirintoService.colunas ||
        mapa[novaLinha][novaColuna] == '#') {
      mensagem = 'Caminho bloqueado por parede!';
      return;
    }

    jogador.moverPara(novaLinha, novaColuna);
    _ultimaDirecaoLinha = deltaLinha;
    _ultimaDirecaoColuna = deltaColuna;
    movimentos++;

    // Entrar na posição de um centauro também causa captura.
    if (_jogadorCapturado) {
      _encerrarPorCaptura();
      return;
    }

    var pegouChave = false;

    if (mapa[jogador.linha][jogador.coluna] == 'S') {
      venceu = true;
      mensagem = 'Parabéns! Você escapou do labirinto!';
      return;
    } else if (mapa[jogador.linha][jogador.coluna] == 'T') {
      turnosChaveTempo = 6;
      pegouChave = true;
      mapa[jogador.linha][jogador.coluna] = '.';
      mensagem = '🔑 Chave do Tempo! Labirinto e centauros congelados por 6 movimentos.';
    } else if (mapa[jogador.linha][jogador.coluna] == 'V') {
      turnosVelocidade = 4;
      mapa[jogador.linha][jogador.coluna] = '.';
      mensagem = '⚡ Poção de Velocidade ativada!';
    }

    if (tempoCongelado) {
      // No movimento em que pegou a chave, a contagem ainda não gasta nenhum
      // dos 6 movimentos de congelamento.
      if (!pegouChave) {
        turnosChaveTempo--;
        mensagem = tempoCongelado
            ? '❄️ Tempo congelado: restam $turnosChaveTempo movimentos.'
            : '⌛ O tempo voltou a correr!';
      }
    } else {
      movimentosParaMudanca--;
      if (movimentosParaMudanca == 0) {
        final mudou = _labirintoService.transformarDinamico(
          mapa,
          jogador.linha,
          jogador.coluna,
          centauro.linha,
          centauro.coluna,
          _random,
          outrasOcupadas: centauros
              .skip(1)
              .map((c) => Point<int>(c.linha, c.coluna))
              .toList(),
        );
        movimentosParaMudanca = 3;
        mensagem = mudou
            ? '⚠️ O labirinto vivo mudou de forma!'
            : 'O labirinto tentou se mover, mas manteve o caminho.';
      }
    }

    if (turnosVelocidade > 0) {
      turnosVelocidade--;
    }
  }

  bool get _jogadorCapturado => centauros.any(
        (c) => c.linha == jogador.linha && c.coluna == jogador.coluna,
      );

  void _encerrarPorCaptura() {
    gameOver = true;
    mensagem = 'Os centauros te pegaram! GAME OVER.';
  }

  /// Executa um turno autônomo: cada centauro calcula seu movimento usando
  /// uma estratégia diferente e evita as posições dos outros dois.
  /// Com a chave do tempo ativa ou no mapa aéreo, nenhum centauro se move.
  void atualizarPerseguicaoCentauro() {
    if (venceu || gameOver || tempoCongelado || visaoAerea) return;


    final previsto = Point<int>(
      jogador.linha + _ultimaDirecaoLinha,
      jogador.coluna + _ultimaDirecaoColuna,
    );
    final alvoPrevisto = previsto.x >= 0 &&
            previsto.x < mapa.length &&
            previsto.y >= 0 &&
            previsto.y < mapa[0].length &&
            mapa[previsto.x][previsto.y] != '#'
        ? previsto
        : Point<int>(jogador.linha, jogador.coluna);

    for (final atual in centauros) {
      final ocupadas = centauros
          .where((outro) => !identical(outro, atual))
          .map((outro) => Point<int>(outro.linha, outro.coluna))
          .toList();

      atual.perseguir(
        jogador.linha,
        jogador.coluna,
        mapa,
        ocupadas: ocupadas,
        alvoPrevisto: alvoPrevisto,
      );

      if (atual.linha == jogador.linha && atual.coluna == jogador.coluna) {
        _encerrarPorCaptura();
        return;
      }
    }
  }
}