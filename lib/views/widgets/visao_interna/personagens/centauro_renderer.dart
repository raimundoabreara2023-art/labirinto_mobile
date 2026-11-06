import 'dart:math';

import 'package:flutter/material.dart';

/// Renderiza um minotauro na visão interna do Labirinto Vivo.
/// Mantém a assinatura usada pela visão interna, com dois parâmetros
/// opcionais novos ([andando] e [fase]) para animar as pernas.
class CentauroRenderer {
  void desenhar(
    Canvas canvas, {
    required Offset centro,
    required double tamanho,
    required IconData icone,
    required Color cor,
    required Color corBrilho,
    bool andando = false,
    double fase = 0,
  }) {
    // Escala do minotauro em relação ao sprite.
    final s = tamanho * 0.55;

    // Ciclo de passada (0 a 2π) e leve balanço do corpo ao andar.
    final t = fase * 2 * pi;
    final balanco = andando ? sin(t * 2).abs() * s * 0.02 : 0.0;

    canvas.save();
    // Ancora os cascos no chão (o chão fica tamanho / 2 abaixo do centro do
    // sprite e os cascos terminam em s * 0.42 abaixo da origem do desenho).
    canvas.translate(centro.dx, centro.dy + tamanho * 0.5 - s * 0.42 - balanco);

    Paint tinta(Color cor) => Paint()
      ..color = cor
      ..isAntiAlias = true;

    Paint linha(Color cor, double espessura) => Paint()
      ..color = cor
      ..strokeWidth = espessura
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    final pelo = const Color(0xFF392116);
    final peloClaro = const Color(0xFF65402A);
    final peloSombra = const Color(0xFF21130D);
    final couro = const Color(0xFF24150D);
    final bronze = const Color(0xFFB17A36);
    final bronzeClaro = const Color(0xFFE1B65D);
    final bronzeEscuro = const Color(0xFF593719);
    final metal = const Color(0xFF9CA7AD);

    // Sombra de contato no chão.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, s * 0.43),
        width: s * 0.90,
        height: s * 0.17,
      ),
      tinta(const Color(0x88000000)),
    );

    // Brilho achatado no chão: usa a cor da visão interna sem formar uma
    // "nuvem" em volta das pernas.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, s * 0.42),
        width: s * 1.1,
        height: s * 0.22,
      ),
      tinta(corBrilho.withValues(alpha: 0.18)),
    );

    // ---------------------------------------------------------
    // 1. PERNAS DE TOURO ANIMADAS
    // ---------------------------------------------------------
    // Uma perna levanta enquanto a outra apoia no chão.

    for (final lado in [-1.0, 1.0]) {
      final passo = andando ? sin(t + (lado > 0 ? 0 : pi)) : 0.0;
      final levanta = max(0.0, passo) * s * 0.07;
      final x = lado * s * 0.115;

      final quadril = Offset(x, -s * 0.14);
      final joelho = Offset(x + lado * s * 0.05, s * 0.07 - levanta * 0.6);
      final tornozelo = Offset(x + lado * s * 0.015, s * 0.31 - levanta);
      final pe = Offset(x + lado * s * 0.025, s * 0.385 - levanta);

      // Coxa musculosa.
      canvas.drawLine(quadril, joelho, linha(peloSombra, s * 0.15));
      canvas.drawLine(quadril, joelho, linha(pelo, s * 0.125));
      canvas.drawLine(
        quadril + Offset(-lado * s * 0.02, 0),
        joelho + Offset(-lado * s * 0.02, 0),
        linha(peloClaro, s * 0.035),
      );

      // Joelho.
      canvas.drawCircle(joelho, s * 0.055, tinta(pelo));
      canvas.drawCircle(joelho, s * 0.055, linha(peloSombra, s * 0.008));
      canvas.drawCircle(
        joelho + Offset(0, -s * 0.01),
        s * 0.025,
        tinta(peloClaro),
      );

      // Canela mais fina.
      canvas.drawLine(joelho, tornozelo, linha(peloSombra, s * 0.095));
      canvas.drawLine(joelho, tornozelo, linha(pelo, s * 0.075));

      // Tufo de pelo no tornozelo.
      canvas.drawCircle(tornozelo, s * 0.035, tinta(peloSombra));

      // Casco bipartido.
      for (final d in [-1.0, 1.0]) {
        final dedo = Path()
          ..moveTo(tornozelo.dx + d * s * 0.005, tornozelo.dy)
          ..lineTo(pe.dx + d * s * 0.05, pe.dy + s * 0.03)
          ..lineTo(pe.dx + d * s * 0.005, pe.dy + s * 0.035)
          ..close();

        canvas.drawPath(dedo, tinta(couro));
        canvas.drawPath(dedo, linha(bronzeEscuro, s * 0.006));
      }
    }

    // ---------------------------------------------------------
    // 2. BRAÇOS MUSCULOSOS
    // ---------------------------------------------------------

    canvas.drawLine(
      Offset(-s * 0.19, -s * 0.43),
      Offset(-s * 0.34, -s * 0.22),
      linha(peloSombra, s * 0.105),
    );

    canvas.drawLine(
      Offset(-s * 0.19, -s * 0.43),
      Offset(-s * 0.34, -s * 0.22),
      linha(peloClaro, s * 0.075),
    );

    canvas.drawCircle(
      Offset(-s * 0.34, -s * 0.22),
      s * 0.052,
      tinta(pelo),
    );

    canvas.drawLine(
      Offset(s * 0.19, -s * 0.43),
      Offset(s * 0.35, -s * 0.30),
      linha(peloSombra, s * 0.105),
    );

    canvas.drawLine(
      Offset(s * 0.19, -s * 0.43),
      Offset(s * 0.35, -s * 0.30),
      linha(peloClaro, s * 0.073),
    );

    // ---------------------------------------------------------
    // 3. TRONCO E OMBROS
    // ---------------------------------------------------------

    final torso = Path()
      ..moveTo(-s * 0.16, -s * 0.18)
      ..quadraticBezierTo(-s * 0.27, -s * 0.31, -s * 0.29, -s * 0.49)
      ..quadraticBezierTo(-s * 0.25, -s * 0.58, -s * 0.12, -s * 0.57)
      ..lineTo(s * 0.12, -s * 0.57)
      ..quadraticBezierTo(s * 0.25, -s * 0.58, s * 0.29, -s * 0.49)
      ..quadraticBezierTo(s * 0.27, -s * 0.31, s * 0.16, -s * 0.18)
      ..close();

    canvas.drawPath(torso, tinta(pelo));
    canvas.drawPath(
      torso,
      linha(peloSombra, s * 0.012),
    );

    // Volume dos músculos do peito.
    for (final lado in [-1.0, 1.0]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(lado * s * 0.105, -s * 0.44),
          width: s * 0.20,
          height: s * 0.15,
        ),
        tinta(peloClaro.withValues(alpha: 0.65)),
      );
    }

    // Peitoral de bronze.
    final peitoral = Path()
      ..moveTo(-s * 0.19, -s * 0.51)
      ..lineTo(-s * 0.15, -s * 0.35)
      ..lineTo(-s * 0.09, -s * 0.32)
      ..lineTo(0, -s * 0.36)
      ..lineTo(s * 0.09, -s * 0.32)
      ..lineTo(s * 0.15, -s * 0.35)
      ..lineTo(s * 0.19, -s * 0.51)
      ..lineTo(s * 0.10, -s * 0.54)
      ..lineTo(-s * 0.10, -s * 0.54)
      ..close();

    canvas.drawPath(peitoral, tinta(bronzeEscuro));
    canvas.drawPath(
      peitoral,
      linha(bronzeClaro, s * 0.009),
    );

    // Reflexo central no metal.
    canvas.drawLine(
      Offset(0, -s * 0.51),
      Offset(0, -s * 0.38),
      linha(bronzeClaro.withValues(alpha: 0.8), s * 0.009),
    );

    // Cinto e fivela.
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(0, -s * 0.17),
        width: s * 0.39,
        height: s * 0.075,
      ),
      tinta(couro),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(0, -s * 0.17),
          width: s * 0.075,
          height: s * 0.08,
        ),
        Radius.circular(s * 0.012),
      ),
      tinta(bronzeClaro),
    );

    // Tiras de couro da cintura.
    for (var i = -2; i <= 2; i++) {
      canvas.drawLine(
        Offset(i * s * 0.065, -s * 0.12),
        Offset(i * s * 0.075, s * 0.015),
        linha(couro, s * 0.025),
      );
    }

    // ---------------------------------------------------------
    // 4. PESCOÇO, JUBA E ORELHAS
    // ---------------------------------------------------------

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(0, -s * 0.59),
          width: s * 0.24,
          height: s * 0.20,
        ),
        Radius.circular(s * 0.065),
      ),
      tinta(peloSombra),
    );

    // Juba atrás da cabeça.
    final juba = Path()
      ..moveTo(-s * 0.18, -s * 0.56)
      ..lineTo(-s * 0.23, -s * 0.67)
      ..lineTo(-s * 0.17, -s * 0.65)
      ..lineTo(-s * 0.20, -s * 0.73)
      ..lineTo(-s * 0.08, -s * 0.68)
      ..lineTo(0, -s * 0.73)
      ..lineTo(s * 0.08, -s * 0.68)
      ..lineTo(s * 0.20, -s * 0.73)
      ..lineTo(s * 0.17, -s * 0.65)
      ..lineTo(s * 0.23, -s * 0.67)
      ..lineTo(s * 0.18, -s * 0.56)
      ..close();

    canvas.drawPath(juba, tinta(peloClaro));

    for (final lado in [-1.0, 1.0]) {
      final orelha = Path()
        ..moveTo(lado * s * 0.13, -s * 0.67)
        ..lineTo(lado * s * 0.25, -s * 0.71)
        ..lineTo(lado * s * 0.19, -s * 0.61)
        ..close();

      canvas.drawPath(orelha, tinta(pelo));
      canvas.drawPath(
        orelha,
        linha(bronzeEscuro, s * 0.006),
      );
    }

    
    // ---------------------------------------------------------
    // 5. CABEÇA DO MINOTAURO — ANATOMIA E EXPRESSÃO AGRESSIVA
    // ---------------------------------------------------------

    // 5.1 — Chifres: desenhados primeiro para ficarem atrás da cabeça.

    for (final lado in [-1.0, 1.0]) {
      final chifre = Path()
        ..moveTo(lado * s * 0.105, -s * 0.805)
        ..cubicTo(
          lado * s * 0.19, -s * 0.87,
          lado * s * 0.30, -s * 0.86,
          lado * s * 0.37, -s * 0.985,
        )
        ..cubicTo(
          lado * s * 0.33, -s * 0.92,
          lado * s * 0.27, -s * 0.79,
          lado * s * 0.15, -s * 0.735,
        )
        ..close();

      // Sombra externa do chifre.
      canvas.drawPath(
        chifre,
        tinta(const Color(0xFF49301F)),
      );

      // Marfim envelhecido.
      final marfimGradiente = Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFE9BD),
            Color(0xFFC8AE80),
            Color(0xFF72583C),
          ],
        ).createShader(
          Rect.fromCenter(
            center: Offset(lado * s * 0.25, -s * 0.85),
            width: s * 0.30,
            height: s * 0.25,
          ),
        )
        ..isAntiAlias = true;

      canvas.drawPath(chifre, marfimGradiente);

      // Linha de iluminação acompanhando a curvatura.
      final reflexo = Path()
        ..moveTo(lado * s * 0.14, -s * 0.805)
        ..quadraticBezierTo(
          lado * s * 0.27, -s * 0.85,
          lado * s * 0.355, -s * 0.955,
        );

      canvas.drawPath(
        reflexo,
        linha(const Color(0xFFFFE9C4), s * 0.009),
      );

      // Anéis escuros na base dos chifres.
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(lado * s * 0.135, -s * 0.795),
          width: s * 0.085,
          height: s * 0.055,
        ),
        tinta(const Color(0xFF29180F)),
      );

      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(lado * s * 0.135, -s * 0.795),
          width: s * 0.065,
          height: s * 0.035,
        ),
        tinta(const Color(0xFF755035)),
      );
    }

    // 5.2 — Orelhas.

    for (final lado in [-1.0, 1.0]) {
      final orelha = Path()
        ..moveTo(lado * s * 0.13, -s * 0.70)
        ..quadraticBezierTo(
          lado * s * 0.27, -s * 0.76,
          lado * s * 0.34, -s * 0.69,
        )
        ..quadraticBezierTo(
          lado * s * 0.25, -s * 0.63,
          lado * s * 0.15, -s * 0.65,
        )
        ..close();

      canvas.drawPath(orelha, tinta(peloSombra));
      canvas.drawPath(orelha, tinta(peloClaro));

      canvas.drawLine(
        Offset(lado * s * 0.17, -s * 0.68),
        Offset(lado * s * 0.29, -s * 0.69),
        linha(const Color(0xFF9A6342), s * 0.012),
      );
    }

    // 5.3 — Cabeça e volume da mandíbula.

    final cabeca = Path()
      ..moveTo(-s * 0.16, -s * 0.73)
      ..cubicTo(
        -s * 0.23, -s * 0.84,
        -s * 0.14, -s * 0.91,
        0, -s * 0.91,
      )
      ..cubicTo(
        s * 0.14, -s * 0.91,
        s * 0.23, -s * 0.84,
        s * 0.16, -s * 0.73,
      )
      ..lineTo(s * 0.18, -s * 0.63)
      ..quadraticBezierTo(
        s * 0.14, -s * 0.55,
        0, -s * 0.56,
      )
      ..quadraticBezierTo(
        -s * 0.14, -s * 0.55,
        -s * 0.18, -s * 0.63,
      )
      ..close();

    canvas.drawPath(cabeca, tinta(peloSombra));

    canvas.drawPath(
      cabeca.shift(Offset(0, -s * 0.008)),
      tinta(pelo),
    );

    canvas.drawPath(
      cabeca,
      linha(const Color(0xFF160D09), s * 0.013),
    );

    // Volume lateral do rosto.
    for (final lado in [-1.0, 1.0]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(lado * s * 0.105, -s * 0.70),
          width: s * 0.12,
          height: s * 0.19,
        ),
        tinta(peloClaro.withValues(alpha: 0.55)),
      );
    }

    // 5.4 — Testa e musculatura facial.

    final testa = Path()
      ..moveTo(-s * 0.115, -s * 0.84)
      ..quadraticBezierTo(
        0, -s * 0.89,
        s * 0.115, -s * 0.84,
      )
      ..lineTo(s * 0.075, -s * 0.765)
      ..quadraticBezierTo(
        0, -s * 0.735,
        -s * 0.075, -s * 0.765,
      )
      ..close();

    canvas.drawPath(
      testa,
      tinta(peloClaro.withValues(alpha: 0.85)),
    );

    // Sobrancelhas inclinadas para dar expressão agressiva.
    for (final lado in [-1.0, 1.0]) {
      final sobrancelha = Path()
        ..moveTo(lado * s * 0.025, -s * 0.785)
        ..quadraticBezierTo(
          lado * s * 0.09, -s * 0.83,
          lado * s * 0.145, -s * 0.785,
        );

      canvas.drawPath(
        sobrancelha,
        linha(peloSombra, s * 0.042),
      );

      canvas.drawPath(
        sobrancelha,
        linha(peloClaro, s * 0.018),
      );
    }

    // 5.5 — Cavidades oculares.

    for (final lado in [-1.0, 1.0]) {
      final olho = Offset(lado * s * 0.078, -s * 0.765);

      canvas.drawOval(
        Rect.fromCenter(
          center: olho,
          width: s * 0.085,
          height: s * 0.060,
        ),
        tinta(const Color(0xFF120906)),
      );

      // Brilho vermelho externo.
      canvas.drawCircle(
        olho,
        s * 0.032,
        tinta(const Color(0xFFFF180D).withValues(alpha: 0.25)),
      );

      // Íris incandescente.
      canvas.drawOval(
        Rect.fromCenter(
          center: olho,
          width: s * 0.043,
          height: s * 0.027,
        ),
        tinta(const Color(0xFFFF3020)),
      );

      // Pupila vertical.
      canvas.drawOval(
        Rect.fromCenter(
          center: olho,
          width: s * 0.009,
          height: s * 0.025,
        ),
        tinta(const Color(0xFF080403)),
      );

      canvas.drawCircle(
        olho + Offset(-lado * s * 0.008, -s * 0.006),
        s * 0.006,
        tinta(const Color(0xFFFFE4A5)),
      );
    }

    // 5.6 — Focinho bovino projetado.

    final focinho = Path()
      ..moveTo(-s * 0.125, -s * 0.69)
      ..quadraticBezierTo(
        -s * 0.16, -s * 0.64,
        -s * 0.13, -s * 0.60,
      )
      ..quadraticBezierTo(
        0, -s * 0.565,
        s * 0.13, -s * 0.60,
      )
      ..quadraticBezierTo(
        s * 0.16, -s * 0.64,
        s * 0.125, -s * 0.69,
      )
      ..quadraticBezierTo(
        0, -s * 0.725,
        -s * 0.125, -s * 0.69,
      )
      ..close();

    canvas.drawPath(
      focinho.shift(Offset(0, s * 0.012)),
      tinta(const Color(0xFF140B08)),
    );

    canvas.drawPath(
      focinho,
      tinta(const Color(0xFF76503A)),
    );

    canvas.drawPath(
      focinho,
      linha(const Color(0xFF28170F), s * 0.009),
    );

    // Plano de iluminação do focinho.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, -s * 0.65),
        width: s * 0.22,
        height: s * 0.07,
      ),
      tinta(const Color(0xFF9B7054).withValues(alpha: 0.65)),
    );

    // Narinas profundas.
    for (final lado in [-1.0, 1.0]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(lado * s * 0.061, -s * 0.65),
          width: s * 0.041,
          height: s * 0.033,
        ),
        tinta(const Color(0xFF100806)),
      );

      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(lado * s * 0.061, -s * 0.641),
          width: s * 0.014,
          height: s * 0.008,
        ),
        tinta(const Color(0xFFB18462)),
      );
    }

    // 5.7 — Boca ameaçadora e mandíbula.

    final boca = Path()
      ..moveTo(-s * 0.095, -s * 0.598)
      ..quadraticBezierTo(
        0, -s * 0.575,
        s * 0.095, -s * 0.598,
      )
      ..quadraticBezierTo(
        s * 0.065, -s * 0.55,
        0, -s * 0.55,
      )
      ..quadraticBezierTo(
        -s * 0.065, -s * 0.55,
        -s * 0.095, -s * 0.598,
      )
      ..close();

    canvas.drawPath(
      boca,
      tinta(const Color(0xFF100503)),
    );

    canvas.drawLine(
      Offset(-s * 0.065, -s * 0.584),
      Offset(s * 0.065, -s * 0.584),
      linha(const Color(0xFFBE8D68), s * 0.008),
    );

    // Presas inferiores.
    for (final lado in [-1.0, 1.0]) {
      final presa = Path()
        ..moveTo(lado * s * 0.065, -s * 0.585)
        ..lineTo(lado * s * 0.045, -s * 0.55)
        ..lineTo(lado * s * 0.082, -s * 0.57)
        ..close();

      canvas.drawPath(
        presa,
        tinta(const Color(0xFFFFE2B4)),
      );
    }

    // 5.8 — Detalhes de pelo na face.

    for (final lado in [-1.0, 1.0]) {
      for (var i = 0; i < 3; i++) {
        canvas.drawLine(
          Offset(
            lado * s * (0.115 + i * 0.012),
            -s * (0.735 - i * 0.025),
          ),
          Offset(
            lado * s * (0.14 + i * 0.008),
            -s * (0.715 - i * 0.025),
          ),
          linha(
            const Color(0xFF9A6541).withValues(alpha: 0.8),
            s * 0.008,
          ),
        );
      }
    }


    // ---------------------------------------------------------
    // 6. MACHADO DE GUERRA
    // ---------------------------------------------------------

    // Cabo atrás da lâmina.
    canvas.drawLine(
      Offset(s * 0.36, -s * 0.61),
      Offset(s * 0.38, -s * 0.09),
      linha(couro, s * 0.036),
    );

    canvas.drawLine(
      Offset(s * 0.35, -s * 0.52),
      Offset(s * 0.36, -s * 0.28),
      linha(bronze, s * 0.009),
    );

    final machado = Path()
      ..moveTo(s * 0.37, -s * 0.59)
      ..quadraticBezierTo(
        s * 0.53,
        -s * 0.64,
        s * 0.56,
        -s * 0.51,
      )
      ..quadraticBezierTo(
        s * 0.58,
        -s * 0.43,
        s * 0.49,
        -s * 0.40,
      )
      ..lineTo(s * 0.39, -s * 0.45)
      ..close();

    canvas.drawPath(machado, tinta(metal));
    canvas.drawPath(
      machado,
      linha(bronzeEscuro, s * 0.008),
    );

    // Fio da lâmina.
    canvas.drawLine(
      Offset(s * 0.53, -s * 0.57),
      Offset(s * 0.53, -s * 0.46),
      linha(Colors.white.withValues(alpha: 0.85), s * 0.007),
    );

    canvas.restore();
  }
}