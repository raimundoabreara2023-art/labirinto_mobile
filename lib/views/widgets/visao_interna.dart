import 'dart:math';

import 'package:flutter/material.dart';

import '../../controllers/jogo_controller.dart';

import 'visao_interna/personagens/guerreiro_renderer.dart';
import 'visao_interna/personagens/centauro_renderer.dart';

/// Visão em terceira pessoa: o labirinto visto de dentro (raycasting), com a
/// câmera um pouco atrás do jogador para que o avatar apareça de costas.
/// Registros informando que este código foi gerado com o auxílio de inteligência artificial.
class VisaoInterna extends StatefulWidget {
  final JogoController controller;
  final double largura;
  final double altura;

  const VisaoInterna({
    super.key,
    required this.controller,
    required this.largura,
    required this.altura,
  });

  @override
  State<VisaoInterna> createState() => _VisaoInternaState();
}

class _VisaoInternaState extends State<VisaoInterna>
    with SingleTickerProviderStateMixin {
  /// Relógio da animação de corrida do avatar (um ciclo de passada = 500 ms).
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  )..repeat();

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CustomPaint(
        size: Size(widget.largura, widget.altura),
        painter: _VisaoInternaPainter(widget.controller, _anim),
      ),
    );
  }
}

class _Sprite {
  final double x;
  final double y;
  final IconData icone;
  final Color cor;
  final double escala;
  final double elevacao;
  final bool ameaca;
  final bool avatar;

  _Sprite({
    required this.x,
    required this.y,
    required this.icone,
    required this.cor,
    required this.escala,
    required this.elevacao,
    this.ameaca = false,
    this.avatar = false,
  });
}

class _Projecao {
  final _Sprite sprite;
  final double profundidade;
  final double lateral;

  _Projecao(this.sprite, this.profundidade, this.lateral);
}

class _VisaoInternaPainter extends CustomPainter {
  final JogoController controller;
  final Animation<double> fase;

  _VisaoInternaPainter(this.controller, this.fase) : super(repaint: fase);

  static const double _larguraFaixa = 2;

  /// Distância máxima que a câmera fica atrás do jogador (em células).
  static const double _recuoMaximo = 1.1;

  /// Pedras do labirinto: arenito, calcário, basalto escuro e pedra com musgo.
  static const List<List<int>> _pedras = [
    [168, 148, 112],
    [140, 134, 122],
    [96, 90, 86],
    [112, 122, 88],
  ];

  /// Paredes que podem se mover: bronze antigo.
  static const List<int> _bronze = [138, 98, 54];

  static int _hash(int a, int b, int c) {
    var x = (a * 374761393 + b * 668265263 + c * 2654435) & 0x7fffffff;
    x = ((x ^ (x >> 13)) * 2654435) & 0x7fffffff;
    return x ^ (x >> 16);
  }

  static int _canal(double v) => v.round().clamp(0, 255).toInt();

  /// Quanto a câmera pode recuar atrás do jogador sem atravessar uma parede.
  double _recuoCamera(
    List<List<String>> mapa,
    double x,
    double y,
    double dx,
    double dy,
  ) {
    var d = 0.0;
    while (d < _recuoMaximo) {
      final cx = (x - dx * (d + 0.1)).floor();
      final cy = (y - dy * (d + 0.1)).floor();
      if (cy < 0 ||
          cy >= mapa.length ||
          cx < 0 ||
          cx >= mapa[0].length ||
          mapa[cy][cx] == '#') {
        break;
      }
      d += 0.1;
    }
    return max(0.0, d - 0.15);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final tela = Rect.fromLTWH(0, 0, w, h);

    // --- TETO: Céu Aberto com Estrelas e Efeito de Brilho (Glow) ---
    final tetoArea = Rect.fromLTWH(0, 0, w, h / 2);
    canvas.drawRect(
      tetoArea,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF020308),
            Color(0xFF080D1D),
            Color(0xFF141C36),
          ],
          stops: [0.0, 0.5, 1.0],
        ).createShader(tetoArea),
    );

    final estrelaPaint = Paint();
    final glowPaint = Paint();

    for (var s = 0; s < 50; s++) {
      final sx = (_hash(s, 101, 17) % w.toInt()).toDouble();
      final sy = (_hash(s, 47, 11) % (h * 0.42).toInt()).toDouble();

      final alfaEstrela = (_hash(s, 73, 5) % 100 + 155).toDouble();
      final raioEstrela = (s % 4 == 0) ? 2.0 : 1.2;

      // Efeito de Halo/Glow nas estrelas maiores
      if (s % 4 == 0) {
        glowPaint.color = Color.fromARGB(40, 200, 220, 255);
        canvas.drawCircle(Offset(sx, sy), raioEstrela * 2.8, glowPaint);
      }

      estrelaPaint.color = Color.fromARGB(alfaEstrela.toInt(), 255, 255, 255);
      canvas.drawCircle(Offset(sx, sy), raioEstrela, estrelaPaint);
    }

    final mapa = controller.mapa;
    final totalLinhas = mapa.length;
    final totalColunas = mapa[0].length;

    final dirX = controller.direcaoColuna.toDouble();
    final dirY = controller.direcaoLinha.toDouble();
    final campo = (w / (2 * h)).clamp(0.5, 1.1).toDouble();
    final planoX = -dirY * campo;
    final planoY = dirX * campo;

    // Posição real do jogador e posição da câmera (um pouco atrás dele).
    final jogadorX = controller.jogador.coluna + 0.5;
    final jogadorY = controller.jogador.linha + 0.5;
    final recuo = _recuoCamera(mapa, jogadorX, jogadorY, dirX, dirY);
    final posX = jogadorX - dirX * recuo;
    final posY = jogadorY - dirY * recuo;

    final faixas = (w / _larguraFaixa).ceil();
    final profundidades = List<double>.filled(faixas, 0);
    final pincel = Paint();

    for (var i = 0; i < faixas; i++) {
      final cameraX = 2 * i / faixas - 1;
      final raioX = dirX + planoX * cameraX;
      final raioY = dirY + planoY * cameraX;

      var mapaX = posX.floor();
      var mapaY = posY.floor();
      final deltaX = raioX == 0 ? 1e30 : (1 / raioX).abs();
      final deltaY = raioY == 0 ? 1e30 : (1 / raioY).abs();
      final passoX = raioX < 0 ? -1 : 1;
      final passoY = raioY < 0 ? -1 : 1;
      var distX = raioX < 0 ? (posX - mapaX) * deltaX : (mapaX + 1 - posX) * deltaX;
      var distY = raioY < 0 ? (posY - mapaY) * deltaY : (mapaY + 1 - posY) * deltaY;

      var lado = 0;
      for (var passo = 0; passo < 64; passo++) {
        if (distX < distY) {
          distX += deltaX;
          mapaX += passoX;
          lado = 0;
        } else {
          distY += deltaY;
          mapaY += passoY;
          lado = 1;
        }
        if (mapaX < 0 ||
            mapaX >= totalColunas ||
            mapaY < 0 ||
            mapaY >= totalLinhas ||
            mapa[mapaY][mapaX] == '#') {
          break;
        }
      }

      var distancia = lado == 0 ? distX - deltaX : distY - deltaY;
      if (distancia < 0.05) {
        distancia = 0.05;
      }
      profundidades[i] = distancia;

      final pontoNaParede = lado == 0 ? posY + distancia * raioY : posX + distancia * raioX;
      final posicaoNaParede = pontoNaParede - pontoNaParede.floor();

      final movel = (mapaX + mapaY) % 2 == 1 &&
          mapaX > 0 &&
          mapaY > 0 &&
          mapaX < totalColunas - 1 &&
          mapaY < totalLinhas - 1;

      final alturaParede = h / distancia;
      _desenharParede(
        canvas,
        pincel,
        x: i * _larguraFaixa,
        topo: h / 2 - alturaParede / 2,
        altura: alturaParede,
        distancia: distancia,
        lado: lado,
        posicaoNaParede: posicaoNaParede,
        celulaX: mapaX,
        celulaY: mapaY,
        movel: movel,
      );
    }

    // Brilho da tocha
    canvas.drawRect(
      tela,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(0, 0.2),
          radius: 0.8,
          colors: [Color(0x33FF9A3C), Colors.transparent],
        ).createShader(tela),
    );

    // Sprites (Itens, Centauros e o avatar do jogador)
    final sprites = <_Sprite>[];
    for (var r = 0; r < totalLinhas; r++) {
      for (var col = 0; col < totalColunas; col++) {
        final celula = mapa[r][col];
        if (celula == 'S') {
          sprites.add(_Sprite(
            x: col + 0.5,
            y: r + 0.5,
            icone: Icons.door_front_door,
            cor: Colors.lightGreenAccent,
            escala: 0.9,
            elevacao: 0,
          ));
        } else if (celula == 'T') {
          sprites.add(_Sprite(
            x: col + 0.5,
            y: r + 0.5,
            icone: Icons.key,
            cor: Colors.cyanAccent,
            escala: 0.35,
            elevacao: 0.12,
          ));
        } else if (celula == 'V') {
          sprites.add(_Sprite(
            x: col + 0.5,
            y: r + 0.5,
            icone: Icons.bolt,
            cor: Colors.yellowAccent,
            escala: 0.35,
            elevacao: 0.12,
          ));
        }
      }
    }

    const coresCentauros = [Colors.redAccent, Colors.deepOrangeAccent, Colors.purpleAccent];
    const iconesCentauros = [Icons.pets, Icons.directions_run, Icons.track_changes];
    for (var i = 0; i < controller.centauros.length; i++) {
      final centauro = controller.centauros[i];
      sprites.add(_Sprite(
        x: centauro.coluna + 0.5,
        y: centauro.linha + 0.5,
        icone: iconesCentauros[i % iconesCentauros.length],
        cor: coresCentauros[i % coresCentauros.length],
        escala: 0.7,
        elevacao: 0,
        ameaca: true,
      ));
    }

    // O avatar do jogador, visto de costas.
    sprites.add(_Sprite(
      x: jogadorX,
      y: jogadorY,
      icone: Icons.person,
      cor: Colors.amber,
      escala: 0.6,
      elevacao: 0,
      avatar: true,
    ));

    final invDet = 1.0 / (planoX * dirY - dirX * planoY);
    final projetados = <_Projecao>[];
    for (final sprite in sprites) {
      final relX = sprite.x - posX;
      final relY = sprite.y - posY;
      final lateral = invDet * (dirY * relX - dirX * relY);
      final profundidade = invDet * (-planoY * relX + planoX * relY);
      if (profundidade > 0.3 && profundidade < 14) {
        projetados.add(_Projecao(sprite, profundidade, lateral));
      }
    }
    projetados.sort((a, b) => b.profundidade.compareTo(a.profundidade));

    for (final p in projetados) {
      final alturaParede = h / p.profundidade;
      final tamanho = alturaParede * p.sprite.escala;
      final centroX = (w / 2) * (1 + p.lateral / p.profundidade);
      final chao = h / 2 + alturaParede / 2;
      final centroY = chao - tamanho / 2 - alturaParede * p.sprite.elevacao;

      final cor = p.sprite.cor.withValues(
        alpha: (1 / (1 + p.profundidade * 0.12)).clamp(0.4, 1.0).toDouble(),
      );
      final desenho = (p.sprite.avatar || p.sprite.ameaca)
          ? null
          : (TextPainter(
              text: TextSpan(
                text: String.fromCharCode(p.sprite.icone.codePoint),
                style: TextStyle(
                  fontFamily: p.sprite.icone.fontFamily,
                  package: p.sprite.icone.fontPackage,
                  fontSize: tamanho,
                  color: cor,
                  height: 1,
                ),
              ),
              textDirection: TextDirection.ltr,
            )..layout());

      final esquerda = centroX - tamanho / 2;
      final direita = centroX + tamanho / 2;
      final inicio = max(0, (esquerda / _larguraFaixa).floor());
      final fim = min(faixas - 1, (direita / _larguraFaixa).floor());

      int? inicioTrecho;
      for (var i = inicio; i <= fim + 1; i++) {
        final visivel = i <= fim && profundidades[i] > p.profundidade;
        if (visivel && inicioTrecho == null) {
          inicioTrecho = i;
        } else if (!visivel && inicioTrecho != null) {
          canvas.save();
          canvas.clipRect(
            Rect.fromLTRB(inicioTrecho * _larguraFaixa, 0, i * _larguraFaixa, h),
          );
          if (p.sprite.avatar) {
            GuerreiroRenderer().desenhar(
              canvas,
              Offset(centroX, centroY),
              tamanho,
              correndo: controller.correndo,
              fase: fase.value,
            );
          } else if (p.sprite.ameaca) {
            CentauroRenderer().desenhar(
              canvas,
              centro: Offset(centroX, centroY),
              tamanho: tamanho,
              icone: p.sprite.icone,
              cor: cor,
              corBrilho: p.sprite.cor,
            );
          } else {
            desenho!.paint(
              canvas,
              Offset(centroX - desenho.width / 2, centroY - desenho.height / 2),
            );
          }
          canvas.restore();
          inicioTrecho = null;
        }
      }
    }

    // Bordas escurecidas
    canvas.drawRect(
      tela,
      Paint()
        ..shader = const RadialGradient(
          colors: [Colors.transparent, Color(0xAA000000)],
          stops: [0.55, 1.0],
          radius: 1.0,
        ).createShader(tela),
    );

    // Alerta de perigo
    var menor = 99;
    for (final centauro in controller.centauros) {
      final distancia = (centauro.linha - controller.jogador.linha).abs() +
          (centauro.coluna - controller.jogador.coluna).abs();
      if (distancia < menor) menor = distancia;
    }
    if (menor <= 4) {
      final intensidade = (5 - menor) / 5;
      canvas.drawRect(
        tela,
        Paint()
          ..shader = RadialGradient(
            colors: [Colors.transparent, Colors.red.withValues(alpha: 0.55 * intensidade)],
            stops: const [0.5, 1.0],
            radius: 1.0,
          ).createShader(tela),
      );
    }

    if (controller.tempoCongelado) {
      canvas.drawRect(
        tela,
        Paint()..color = Colors.cyanAccent.withValues(alpha: 0.10),
      );
    }
  }
  
  /// Desenha o herói grego de costas com armadura completa, elmo coríntio ornamentado,
  /// crista vermelha volumosa, escudo espartano detalhado e espada curta (gládio).
  /// Registros informando que este código foi gerado com o auxílio de inteligência artificial.


  void _desenharParede(
    Canvas canvas,
    Paint pincel, {
    required double x,
    required double topo,
    required double altura,
    required double distancia,
    required int lado,
    required double posicaoNaParede,
    required int celulaX,
    required int celulaY,
    required bool movel,
  }) {
    final tom = movel ? _bronze : _pedras[_hash(celulaX, celulaY, 1) % _pedras.length];

    final luz = 1 / (1 + distancia * 0.40);
    final lateral = lado == 1 ? 0.68 : 1.0;
    final intensidade = (0.10 + 0.95 * luz) * lateral;
    final fatorR = 0.85 + 0.30 * luz;
    final fatorG = 0.85 + 0.05 * luz;
    final fatorB = 0.95 - 0.35 * luz;

    const fileiras = 6;
    final alturaFileira = altura / fileiras;
    final detalhado = distancia < 8;
    final espessuraJunta = max(1.0, altura * 0.02);

    for (var k = 0; k < fileiras; k++) {
      final deslocamento = k.isEven ? 0.0 : 0.25;
      final u = (posicaoNaParede + deslocamento) % 1.0;
      final bloco = (u * 2).floor();
      final fracao = (u * 2) % 1.0;
      final juntaVertical = detalhado && (fracao < 0.05 || fracao > 0.97);

      final variacao = 0.86 + (_hash(celulaX * 7 + bloco, celulaY * 5 + k, lado) % 25) / 100;
      final fator = juntaVertical ? 0.35 : variacao;

      pincel.color = Color.fromARGB(
        255,
        _canal(tom[0] * intensidade * fatorR * fator),
        _canal(tom[1] * intensidade * fatorG * fator),
        _canal(tom[2] * intensidade * fatorB * fator),
      );
      final y = topo + k * alturaFileira;
      canvas.drawRect(
        Rect.fromLTWH(x, y, _larguraFaixa + 0.5, alturaFileira + 0.5),
        pincel,
      );

      if (detalhado && k > 0) {
        pincel.color = Color.fromARGB(
          255,
          _canal(tom[0] * intensidade * 0.3),
          _canal(tom[1] * intensidade * 0.3),
          _canal(tom[2] * intensidade * 0.3),
        );
        canvas.drawRect(
          Rect.fromLTWH(x, y, _larguraFaixa + 0.5, espessuraJunta),
          pincel,
        );
      }
    }

    if (movel && (posicaoNaParede * 8).floor().isEven) {
      final alfa = (210 * (0.35 + 0.65 * luz)).round().clamp(0, 255).toInt();
      pincel.color = Color.fromARGB(alfa, 255, 176, 64);
      canvas.drawRect(
        Rect.fromLTWH(x, topo + altura * 0.44, _larguraFaixa + 0.5, altura * 0.12),
        pincel,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}