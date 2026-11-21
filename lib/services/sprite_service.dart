import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Qual animação o minotauro está executando.
enum EstadoMinotauro { parado, andando, corrida, rugido, ataque }

/// O que desenhar agora: o quadro, em que animação está e em que ponto (0 a 1)
/// do ciclo dessa animação. O renderer usa [fase] para o balanço do corpo.
class QuadroMinotauro {
  final ui.Image? imagem;
  final EstadoMinotauro estado;
  final double fase;

  const QuadroMinotauro(this.imagem, this.estado, this.fase);
}

/// Carrega e mantém em memória os quadros do minotauro (PNGs com transparência).
///
/// Arquivos em assets/minotauro_sprites/:
///   minotauro_parado.png        -> quadro parado (obrigatório, serve de reserva)
///   minotauro_andando_1..6.png  -> ciclo de caminhada, em ordem
///   minotauro_corrida_1..6.png  -> ciclo de corrida, em ordem
///   minotauro_ataque_1..6.png   -> sequência do golpe de machado, em ordem
///   minotauro_rugido.png        -> boca aberta, usado de perto
///
/// Tudo exceto o quadro parado é opcional: se algum arquivo faltar, o serviço
/// usa a animação mais próxima que existir.
class SpriteService {
  static const String _pasta = 'assets/minotauro_sprites/';
  static const int _maximoQuadros = 6;

  /// Distâncias (em células de profundidade) que decidem o estado.
  static const double distanciaAtaque = 1.6;
  static const double distanciaRugido = 3.0;
  static const double distanciaCorrida = 6.0;

  /// Duração de um ciclo completo (todos os quadros) de cada animação, em ms.
  /// Aumente para deixar mais lento, diminua para deixar mais rápido.
  static const int cicloAndandoMs = 1400;
  static const int cicloCorridaMs = 900;
  static const int cicloAtaqueMs = 1200;
  static const int cicloRugidoMs = 1000;
  static const int cicloParadoMs = 1000;

  /// Ciclo (lento) que alterna rugido e corrida quando ele está perto.
  static const int _cicloDecisaoMs = 1800;

  ui.Image? imagemMinotauro; // parado
  ui.Image? imagemRugido;
  final List<ui.Image> quadrosAndando = [];
  final List<ui.Image> quadrosCorrida = [];
  final List<ui.Image> quadrosAtaque = [];

  bool _carregado = false;
  bool get carregado => _carregado;

  Future<void> carregarSprites() async {
    if (_carregado) return;

    try {
      imagemMinotauro = await _carregarImagem('${_pasta}minotauro_parado.png');
      imagemRugido = await _tentarCarregar('${_pasta}minotauro_rugido.png');

      await Future.wait([
        _carregarSequencia('andando', quadrosAndando),
        _carregarSequencia('corrida', quadrosCorrida),
        _carregarSequencia('ataque', quadrosAtaque),
      ]);

      _carregado = true;
    } catch (e) {
      debugPrint('Erro ao carregar imagens do minotauro: $e');
    }
  }

  /// Decide a animação. Função pura (não usa imagens), então é testável.
  ///
  /// [fase] vai de 0 a 1 em cada ciclo; [distancia] é a profundidade em
  /// células; [andando] é false com o tempo congelado; [capturou] é true no
  /// game over, quando o minotauro que te pegou golpeia.
  static EstadoMinotauro estadoPara({
    required double fase,
    required double distancia,
    required bool andando,
    bool capturou = false,
  }) {
    if (capturou && distancia < distanciaAtaque) return EstadoMinotauro.ataque;
    if (!andando) return EstadoMinotauro.parado;
    if (distancia < distanciaAtaque) return EstadoMinotauro.ataque;
    if (distancia < distanciaRugido && fase < 0.5) return EstadoMinotauro.rugido;
    if (distancia < distanciaCorrida) return EstadoMinotauro.corrida;
    return EstadoMinotauro.andando;
  }

  static int _cicloDe(EstadoMinotauro estado) {
    switch (estado) {
      case EstadoMinotauro.andando:
        return cicloAndandoMs;
      case EstadoMinotauro.corrida:
        return cicloCorridaMs;
      case EstadoMinotauro.ataque:
        return cicloAtaqueMs;
      case EstadoMinotauro.rugido:
        return cicloRugidoMs;
      case EstadoMinotauro.parado:
        return cicloParadoMs;
    }
  }

  /// Escolhe o quadro certo para o momento atual.
  ///
  /// O ritmo vem do relógio (não do ciclo de 500 ms da tocha), com um tempo
  /// próprio para cada animação. [defasagem] (0 a 1) tira os minotauros de
  /// sincronia. [agora] existe para facilitar testes.
  QuadroMinotauro quadroPara({
    required double distancia,
    required bool andando,
    bool capturou = false,
    double defasagem = 0,
    DateTime? agora,
  }) {
    final ms = (agora ?? DateTime.now()).millisecondsSinceEpoch;

    final faseDecisao = ((ms % _cicloDecisaoMs) / _cicloDecisaoMs + defasagem) % 1.0;
    final estado = estadoPara(
      fase: faseDecisao,
      distancia: distancia,
      andando: andando,
      capturou: capturou,
    );

    final ciclo = _cicloDe(estado);
    final fase = ((ms % ciclo) / ciclo + defasagem) % 1.0;

    final ui.Image? imagem;
    switch (estado) {
      case EstadoMinotauro.ataque:
        imagem = _doCiclo(quadrosAtaque, fase) ??
            _doCiclo(quadrosCorrida, fase) ??
            _doCiclo(quadrosAndando, fase) ??
            imagemMinotauro;
      case EstadoMinotauro.rugido:
        imagem = imagemRugido ??
            _doCiclo(quadrosCorrida, fase) ??
            _doCiclo(quadrosAndando, fase) ??
            imagemMinotauro;
      case EstadoMinotauro.corrida:
        imagem = _doCiclo(quadrosCorrida, fase) ??
            _doCiclo(quadrosAndando, fase) ??
            imagemMinotauro;
      case EstadoMinotauro.andando:
        imagem = _doCiclo(quadrosAndando, fase) ?? imagemMinotauro;
      case EstadoMinotauro.parado:
        imagem = imagemMinotauro ??
            (quadrosAndando.isNotEmpty ? quadrosAndando.first : null);
    }

    return QuadroMinotauro(imagem, estado, fase);
  }

  ui.Image? _doCiclo(List<ui.Image> quadros, double fase) {
    if (quadros.isEmpty) return null;
    final indice = (fase * quadros.length).floor() % quadros.length;
    return quadros[indice];
  }

  /// Lê `minotauro_NOME_1.png`, `_2.png`... até o primeiro que não existir.
  Future<void> _carregarSequencia(String nome, List<ui.Image> destino) async {
    for (var i = 1; i <= _maximoQuadros; i++) {
      final quadro = await _tentarCarregar('${_pasta}minotauro_${nome}_$i.png');
      if (quadro == null) break;
      destino.add(quadro);
    }
  }

  Future<ui.Image?> _tentarCarregar(String caminho) async {
    try {
      return await _carregarImagem(caminho);
    } catch (_) {
      return null; // arquivo ainda não existe
    }
  }

  Future<ui.Image> _carregarImagem(String caminho) async {
    final ByteData data = await rootBundle.load(caminho);
    final Uint8List bytes = data.buffer.asUint8List();
    final ui.Codec codec = await ui.instantiateImageCodec(bytes);
    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    return frameInfo.image;
  }
}