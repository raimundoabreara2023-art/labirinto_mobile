import 'dart:math';

import 'package:flutter/material.dart';

import '../../controllers/jogo_controller.dart';

import 'visao_interna/personagens/guerreiro_renderer.dart';
import 'visao_interna/personagens/centauro_renderer.dart';

/// Visão em terceira pessoa: o labirinto visto de dentro (raycasting), com a
/// câmera um pouco atrás do jogador para que o avatar apareça de costas.
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

  /// Quanto a tocha fica afastada da parede, em células.
  static const double _afastamentoTocha = 0.12;

  /// Pedras do labirinto: arenito, calcário, basalto escuro e pedra com musgo.
  static const List<List<int>> _pedras = [
    [168, 148, 112],
    [140, 134, 122],
    [ 96,  90,  86],
    [112, 122,  88],
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

  /// Chão de lajotas em perspectiva: degradê com luz por distância e juntas
  /// desenhadas como linhas (transversais e laterais), só com chamadas baratas.
  void _desenharChao(
    Canvas canvas,
    double w,
    double h, {
    required double posX,
    required double posY,
    required double dirX,
    required double dirY,
    required double campo,
    required double tremor,
  }) {
    final horizonte = h / 2;
    final area = Rect.fromLTWH(0, horizonte, w, horizonte);

    // Degradê: t = 0 no horizonte e t = 1 na base da tela (distância = 1 / t).
    const amostras = 10;
    const tom = [96, 86, 66];
    final cores = <Color>[];
    final posicoes = <double>[];
    for (var i = 0; i <= amostras; i++) {
      final t = i / amostras;
      final luz = t / (t + 0.4);
      // A luz da tocha oscila mais perto do jogador do que ao longe.
      final intensidade = (0.10 + 0.95 * luz) * (1 + (tremor - 1) * luz);
      cores.add(Color.fromARGB(
        255,
        _canal(tom[0] * intensidade),
        _canal(tom[1] * intensidade),
        _canal(tom[2] * intensidade),
      ));
      posicoes.add(t);
    }
    canvas.drawRect(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: cores,
          stops: posicoes,
        ).createShader(area),
    );

    // As juntas ficam nas coordenadas inteiras do mapa (bordas das células).
    final profundidadeCamera = posX * dirX + posY * dirY;
    final lateralCamera = -posX * dirY + posY * dirX;
    final junta = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..isAntiAlias = true;
    final faixa = Paint()..color = const Color(0x24000000);

    // Faixas alternadas (claro/escuro) e juntas transversais: uma por célula
    // de profundidade.
    for (var n = profundidadeCamera.floor();; n++) {
      final d = n - profundidadeCamera;
      if (d > 14) break;

      if (d > 0 && n.isOdd) {
        final yPerto = d < 1 ? h : horizonte + horizonte / d;
        final yLonge = horizonte + horizonte / (d + 1);
        if (yLonge < yPerto) {
          canvas.drawRect(Rect.fromLTRB(0, yLonge, w, yPerto), faixa);
        }
      }

      if (d >= 1) {
        final y = horizonte + horizonte / d;
        junta.color = Color.fromRGBO(0, 0, 0, 0.75 / (1 + d * 0.18));
        canvas.drawLine(Offset(0, y), Offset(w, y), junta);
      }
    }

    // Juntas laterais: retas que convergem para o ponto de fuga.
    const profundidadeFinal = 14.0;
    junta.color = const Color(0x66000000);
    final yFundo = horizonte + horizonte / profundidadeFinal;
    final limite = 14 * campo;
    for (var k = (lateralCamera - limite).floor();
        k <= (lateralCamera + limite).ceil();
        k++) {
      final s = k - lateralCamera;
      final xFundo = w / 2 * (1 + s / (campo * profundidadeFinal));
      final xBase = w / 2 * (1 + s / campo);
      canvas.drawLine(Offset(xFundo, yFundo), Offset(xBase, h), junta);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final tela = Rect.fromLTWH(0, 0, w, h);

    // Tremor da chama: soma de ondas com frequências inteiras, para o ciclo de
    // 500 ms da animação se repetir sem "pulo". Varia entre ~0,86 e ~1,14.
    final ciclo = fase.value * 2 * pi;
    final tremor = 1 +
        0.07 * sin(ciclo * 3) +
        0.04 * sin(ciclo * 5 + 1.3) +
        0.03 * sin(ciclo * 8 + 2.1);

    // Aviso de mudança: quando faltam 2 movimentos as paredes móveis (bronze)
    // brilham de leve; com 1 movimento restante pulsam forte. Sem aviso se o
    // tempo estiver congelado ou a partida tiver acabado.
    final restantes = controller.movimentosParaMudanca;
    final nivelAviso =
        (controller.tempoCongelado || controller.venceu || controller.gameOver)
            ? 0.0
            : restantes == 1
                ? 1.0
                : restantes == 2
                    ? 0.3
                    : 0.0;
    final aviso = nivelAviso * (0.5 + 0.5 * sin(ciclo));

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

    _desenharChao(
      canvas,
      w,
      h,
      posX: posX,
      posY: posY,
      dirX: dirX,
      dirY: dirY,
      campo: campo,
      tremor: tremor,
    );

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

      // Paralaxe da tocha: como ela está à frente da parede, sua posição
      // aparente muda conforme o ângulo do raio que atinge a parede.
      final ortogonal = (lado == 0 ? raioX : raioY).abs();
      final paralela = lado == 0 ? raioY : raioX;
      final paralaxe = ortogonal < 1e-6
          ? 0.0
          : (_afastamentoTocha * paralela / ortogonal)
              .clamp(-0.6, 0.6)
              .toDouble();

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
        tremor: tremor,
        aviso: aviso,
        ciclo: ciclo,
        paralaxe: paralaxe,
      );
    }

    // Brilho da tocha: intensidade e alcance oscilam junto com a chama.
    final alfaTocha = (0x33 * tremor).round().clamp(0, 255).toInt();
    canvas.drawRect(
      tela,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, 0.2),
          radius: 0.8 + (tremor - 1) * 0.5,
          colors: [Color.fromARGB(alfaTocha, 0xFF, 0x9A, 0x3C), Colors.transparent],
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
    required double tremor,
    required double aviso,
    required double ciclo,
    required double paralaxe,
  }) {
    final tom = movel ? _bronze : _pedras[_hash(celulaX, celulaY, 1) % _pedras.length];

    final luz = 1 / (1 + distancia * 0.40);
    final lateral = lado == 1 ? 0.68 : 1.0;
    // Paredes móveis ficam mais claras enquanto o aviso pulsa.
    final realce = movel ? 1 + 0.35 * aviso : 1.0;
    // A chama oscila mais nas paredes próximas do que nas distantes.
    final intensidade =
        (0.10 + 0.95 * luz) * lateral * (1 + (tremor - 1) * luz) * realce;
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

    // Brilho laranja sobre a parede inteira enquanto o aviso pulsa.
    if (movel && aviso > 0) {
      final alfaAviso =
          (130 * aviso * (0.4 + 0.6 * luz)).round().clamp(0, 255).toInt();
      pincel.color = Color.fromARGB(alfaAviso, 255, 140, 40);
      canvas.drawRect(
        Rect.fromLTWH(x, topo, _larguraFaixa + 0.5, altura),
        pincel,
      );
    }

    // Toda parede móvel carrega uma tocha acesa no centro da face.
    if (movel && altura > 8) {
      _desenharTocha(
        canvas,
        pincel,
        x: x,
        topo: topo,
        altura: altura,
        u: posicaoNaParede,
        paralaxe: paralaxe,
        luz: luz,
        ciclo: ciclo,
        semente: _hash(celulaX, celulaY, lado),
      );
    }

    // Sombra de contato: escurece o pé da parede para "fechar" o canto com o chão.
    final alturaSombra = altura * 0.07;
    pincel.color = const Color(0x55000000);
    canvas.drawRect(
      Rect.fromLTWH(x, topo + altura - alturaSombra, _larguraFaixa + 0.5, alturaSombra),
      pincel,
    );
  }

  /// Desenha a tocha como um perfil vertical por faixa. [u] é a posição da faixa
  /// na face da parede (0 a 1); a tocha fica no centro (u = 0,5).
  ///
  /// A tocha está afastada da parede por um braço de metal. Por isso há duas
  /// posições: a da parede (halo, sombra, placa e braço) e a da própria tocha
  /// (copa, haste e chama), deslocada por [paralaxe] conforme o ângulo de visão.
  /// É esse deslocamento que dá a sensação de profundidade ao andar e girar.
  void _desenharTocha(
    Canvas canvas,
    Paint pincel, {
    required double x,
    required double topo,
    required double altura,
    required double u,
    required double paralaxe,
    required double luz,
    required double ciclo,
    required int semente,
  }) {
    const meiaLargura = 0.05; // metade da largura da chama, em fração da face
    final largura = _larguraFaixa + 0.5;
    final defasagem = (semente % 628) / 100;

    final nxParede = (u - 0.5) / meiaLargura; // visto a partir da parede
    final axParede = nxParede.abs();
    final nx = (u - paralaxe - 0.5) / meiaLargura; // visto a partir da tocha
    final ax = nx.abs();

    // Cada tocha tem a sua própria defasagem, para não tremularem em uníssono.
    final flick = 1 +
        0.14 * sin(ciclo * 3 + defasagem) +
        0.08 * sin(ciclo * 5 + defasagem * 1.7) +
        0.05 * sin(ciclo * 8 + defasagem * 0.6);
    final altChama = altura * 0.20 * flick;
    final inclina = 0.35 * sin(ciclo * 2 + defasagem);

    final base = topo + altura * 0.43; // onde a chama nasce (topo da copa)
    final alturaCopa = altura * 0.07;
    final yBraco = base + altura * 0.15; // altura da placa e do braço
    final metal = 0.4 + 0.6 * luz;

    // --- Halo de luz sobre a parede (camadas concêntricas suaves) ---
    final brilho = (0.5 + 0.5 * luz) * (0.9 + 0.1 * sin(ciclo * 3 + defasagem));
    final centroHalo = base - altura * 0.08;
    const halos = [
      [2.8, 14.0],
      [2.0, 22.0],
      [1.4, 34.0],
    ];
    for (final halo in halos) {
      final raio = halo[0];
      if (axParede >= raio) continue;
      final meia =
          altura * 0.42 * sqrt(1 - (axParede / raio) * (axParede / raio));
      pincel.color = Color.fromARGB(
        (halo[1] * brilho).round().clamp(0, 255).toInt(),
        255,
        150,
        50,
      );
      canvas.drawRect(
        Rect.fromLTRB(x, centroHalo - meia, x + largura, centroHalo + meia),
        pincel,
      );
    }

    // --- Sombra do suporte projetada na parede, logo abaixo da placa ---
    if (axParede < 1.6) {
      final meia =
          altura * 0.15 * sqrt(1 - (axParede / 1.6) * (axParede / 1.6));
      final centro = base + altura * 0.27;
      pincel.color = Color.fromARGB(
        (80 * (0.4 + 0.6 * luz)).round().clamp(0, 255).toInt(),
        0,
        0,
        0,
      );
      canvas.drawRect(
        Rect.fromLTRB(x, centro - meia, x + largura, centro + meia),
        pincel,
      );
    }

    // --- Placa de metal presa à parede ---
    if (axParede < 0.95) {
      final k = axParede / 0.95;
      final meia = altura * 0.065 * sqrt(1 - k * k * k * k);
      pincel.color = Color.fromARGB(
        255,
        _canal(96 * metal),
        _canal(68 * metal),
        _canal(34 * metal),
      );
      canvas.drawRect(
        Rect.fromLTRB(x, yBraco - meia, x + largura, yBraco + meia),
        pincel,
      );
    }

    // --- Braço horizontal que liga a placa à tocha ---
    // Na vista de frente ele some atrás da haste; de lado aparece inteiro.
    const meiaBraco = 0.012;
    final minimo = min(0.5, 0.5 + paralaxe) - meiaBraco;
    final maximo = max(0.5, 0.5 + paralaxe) + meiaBraco;
    if (u >= minimo && u <= maximo) {
      final espessura = max(1.5, altura * 0.018);
      pincel.color = Color.fromARGB(
        255,
        _canal(70 * metal),
        _canal(48 * metal),
        _canal(24 * metal),
      );
      canvas.drawRect(
        Rect.fromLTRB(x, yBraco - espessura, x + largura, yBraco + espessura),
        pincel,
      );
    }

    // --- Haste curta e copa (na posição da tocha, à frente da parede) ---
    if (ax < 0.22) {
      pincel.color = Color.fromARGB(
        255,
        _canal(70 * metal),
        _canal(48 * metal),
        _canal(24 * metal),
      );
      canvas.drawRect(
        Rect.fromLTRB(x, base + alturaCopa, x + largura, yBraco + altura * 0.02),
        pincel,
      );
    }
    if (ax < 0.9) {
      final t = ((0.9 - ax) / 0.4).clamp(0.0, 1.0).toDouble();
      pincel.color = Color.fromARGB(
        255,
        _canal(86 * metal),
        _canal(60 * metal),
        _canal(30 * metal),
      );
      canvas.drawRect(
        Rect.fromLTRB(x, base, x + largura, base + alturaCopa * t),
        pincel,
      );
      // Friso claro na borda da copa.
      pincel.color = Color.fromARGB(
        255,
        _canal(170 * metal),
        _canal(120 * metal),
        _canal(60 * metal),
      );
      canvas.drawRect(
        Rect.fromLTRB(x, base, x + largura, base + max(1.0, alturaCopa * 0.18)),
        pincel,
      );
    }

    // --- Chama: três camadas em forma de gota, com leve inclinação ---
    if (ax < 1) {
      final h = altChama *
          pow(1 - ax * ax, 1.25).toDouble() *
          (1 + inclina * nx * 0.6);
      pincel.color = const Color(0xF0FF6E1E);
      canvas.drawRect(
        Rect.fromLTRB(x, base - max(0.0, h), x + largura, base + 1),
        pincel,
      );
    }
    final axMeio = ax / 0.62;
    if (axMeio < 1) {
      final h = altChama *
          0.72 *
          pow(1 - axMeio * axMeio, 1.2).toDouble() *
          (1 + inclina * nx * 0.5);
      pincel.color = const Color(0xFFFFBE3C);
      canvas.drawRect(
        Rect.fromLTRB(x, base - max(0.0, h), x + largura, base + 1),
        pincel,
      );
    }
    final axNucleo = ax / 0.32;
    if (axNucleo < 1) {
      final h = altChama * 0.45 * pow(1 - axNucleo * axNucleo, 1.1).toDouble();
      pincel.color = const Color(0xFFFFF5BE);
      canvas.drawRect(
        Rect.fromLTRB(x, base - max(0.0, h), x + largura, base + 1),
        pincel,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}