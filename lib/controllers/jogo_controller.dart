import 'dart:math';
import '../models/jogador.dart';
import '../models/centauro.dart';
import '../services/labirinto_service.dart';

class JogoController {
  final LabirintoService _labirintoService = LabirintoService();
  
  late List<List<String>> mapa;
  late Jogador jogador;
  late Centauro centauro;

  int movimentos = 0;
  int movimentosParaMudanca = 3;
  int turnosChaveTempo = 0;
  int turnosVelocidade = 0;

  bool venceu = false;
  bool gameOver = false;
  String mensagem = 'Labirinto Vivo e Dinâmico! Cuidado com o Centauro.';

  final Random _random = Random();

  JogoController() {
    reiniciar();
  }

  void reiniciar() {
    mapa = _labirintoService.criarMapa();
    jogador = Jogador(linha: 1, coluna: 1);
    centauro = Centauro(linha: 5, coluna: 8);
    movimentos = 0;
    movimentosParaMudanca = 3;
    turnosChaveTempo = 0;
    turnosVelocidade = 0;
    venceu = false;
    gameOver = false;
    mensagem = 'Nova partida iniciada. O labirinto é imprevisível!';
  }

  void mover(int deltaLinha, int deltaColuna) {
    if (venceu || gameOver) return;

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
    movimentos++;

    if (mapa[jogador.linha][jogador.coluna] == 'S') {
      venceu = true;
      mensagem = 'Parabéns! Você escapou do labirinto!';
      return;
    } else if (mapa[jogador.linha][jogador.coluna] == 'T') {
      turnosChaveTempo = 6;
      mapa[jogador.linha][jogador.coluna] = '.';
      mensagem = '🔑 Chave do Tempo coletada! Labirinto congelado por 6 turnos.';
    } else if (mapa[jogador.linha][jogador.coluna] == 'V') {
      turnosVelocidade = 4;
      mapa[jogador.linha][jogador.coluna] = '.';
      mensagem = '⚡ Poção de Velocidade ativada!';
    }

    centauro.perseguir(jogador.linha, jogador.coluna, mapa);

    if (jogador.linha == centauro.linha && jogador.coluna == centauro.coluna) {
      gameOver = true;
      mensagem = 'O Centauro te pegou! GAME OVER.';
      return;
    }

    if (turnosChaveTempo > 0) {
      turnosChaveTempo--;
      mensagem += ' (Tempo congelado: restam $turnosChaveTempo)';
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
}