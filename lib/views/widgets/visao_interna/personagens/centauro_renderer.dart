import 'package:flutter/material.dart';

/// Responsável pelo desenho visual dos indicadores dos centauros na visão interna.
///
/// A posição, a profundidade, a escala e o recorte pelas paredes continuam sob
/// responsabilidade de VisaoInternaPainter. Esta classe preserva o visual atual
/// (ícone e halo) e isola sua renderização para futuras melhorias.
class CentauroRenderer {
  void desenhar(
    Canvas canvas, {
    required Offset centro,
    required double tamanho,
    required IconData icone,
    required Color cor,
    required Color corBrilho,
  }) {
    canvas.drawCircle(
      centro,
      tamanho * 0.7,
      Paint()..color = corBrilho.withValues(alpha: 0.22),
    );

    final desenho = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icone.codePoint),
        style: TextStyle(
          fontFamily: icone.fontFamily,
          package: icone.fontPackage,
          fontSize: tamanho,
          color: cor,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    desenho.paint(
      canvas,
      Offset(
        centro.dx - desenho.width / 2,
        centro.dy - desenho.height / 2,
      ),
    );
  }
}
