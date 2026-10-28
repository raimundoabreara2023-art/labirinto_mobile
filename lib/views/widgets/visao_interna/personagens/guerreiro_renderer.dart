import 'dart:math';

import 'package:flutter/material.dart';

/// Renderiza visualmente o guerreiro grego na visão em terceira pessoa.
/// Recebe apenas os dados necessários para desenhar e animar o personagem.
class GuerreiroRenderer {
  void desenhar(Canvas canvas, Offset c, double s, {
    required bool correndo,
    required double fase,
  }) {
    final t = fase;
    final balanco = correndo ? sin(t * 2 * pi) : 0.0;
    final pulo = correndo ? sin(t * 4 * pi).abs() * s * 0.025 : 0.0;

    final bronzeEscuro = const Color(0xFF4A3018);
    final bronze = const Color(0xFF9A672E);
    final bronzeClaro = const Color(0xFFD4A359);
    final ouro = const Color(0xFFE5C158);
    final couro = const Color(0xFF3A2315);
    final pele = const Color(0xFFC8936D);

    Paint tinta(Color cor) => Paint()
      ..color = cor
      ..isAntiAlias = true;

    Paint degrade(Rect area, List<Color> cores) => Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: cores,
      ).createShader(area)
      ..isAntiAlias = true;

    Paint linha(Color cor, double espessura) => Paint()
      ..color = cor
      ..strokeWidth = espessura
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    canvas.save();
    canvas.translate(c.dx, c.dy - pulo);

    // Ajuste de escala e proporção do herói
    canvas.translate(0, s * 0.46);
    canvas.scale(0.68);
    canvas.translate(0, -s * 0.46);

    // Sombra projetada no chão
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, s * 0.48),
        width: s * 0.52,
        height: s * 0.10,
      ),
      tinta(const Color(0x77000000)),
    );

    // --- 1. PERNAS E SANDÁLIAS DE GUERRA (MARCHA CORRETA PARA FRENTE/COSTAS) ---
    for (final lado in [-1.0, 1.0]) {
      // Alternância de passada: quando um pé sobe (flexiona), o outro desce
      final fasePasso = correndo ? sin(t * 2 * pi + (lado > 0 ? 0 : pi)) : 0.0;
      final elevacaoPerna = correndo ? max(0.0, fasePasso) * s * 0.04 : 0.0;
      final balancoSutil = correndo ? fasePasso * s * 0.015 : 0.0;

      // Perna vista de costas com movimento vertical de passada (marcha)
      final perna = Path()
        ..moveTo(lado * s * 0.05 + balancoSutil, s * 0.14)
        ..quadraticBezierTo(
          lado * s * 0.055,
          s * 0.26,
          lado * s * 0.05 + balancoSutil,
          s * 0.38 - elevacaoPerna,
        )
        ..lineTo(lado * s * 0.085 + balancoSutil, s * 0.43 - elevacaoPerna)
        ..lineTo(lado * s * 0.015 + balancoSutil, s * 0.43 - elevacaoPerna)
        ..quadraticBezierTo(
          lado * s * 0.02,
          s * 0.28,
          lado * s * 0.025,
          s * 0.14,
        )
        ..close();

      canvas.drawPath(perna, tinta(pele));
      canvas.drawPath(perna, linha(const Color(0xFF5A3E2B), s * 0.008));

      // Grevas (caneleiras) de bronze acompanhando o movimento
      final greva = Path()
        ..moveTo(lado * s * 0.045, s * 0.18)
        ..quadraticBezierTo(lado * s * 0.05, s * 0.26, lado * s * 0.045 + balancoSutil, s * 0.36 - elevacaoPerna)
        ..lineTo(lado * s * 0.02 + balancoSutil, s * 0.36 - elevacaoPerna)
        ..quadraticBezierTo(lado * s * 0.025, s * 0.26, lado * s * 0.025, s * 0.18)
        ..close();

      canvas.drawPath(
        greva,
        degrade(
          Rect.fromCenter(center: Offset(lado * s * 0.035, s * 0.27 - elevacaoPerna * 0.5), width: s * 0.04, height: s * 0.18),
          [bronzeClaro, bronze, bronzeEscuro],
        ),
      );
      canvas.drawPath(greva, linha(ouro, s * 0.005));

      // Sandálias de couro alinhadas e levantando junto com o passo
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(lado * s * 0.05 + balancoSutil, s * 0.44 - elevacaoPerna),
          width: s * 0.085,
          height: s * 0.048,
        ),
        tinta(couro),
      );

      // Correias da sandália
      canvas.drawLine(
        Offset(lado * s * 0.02 + balancoSutil, s * 0.43 - elevacaoPerna),
        Offset(lado * s * 0.08 + balancoSutil, s * 0.45 - elevacaoPerna),
        linha(ouro, s * 0.008),
      );
    }

    // --- 2. TÚNICA (QUITON) E COURELA DE BRONZE (TÓRAX MUSCULOSO) ---
    final torax = Path()
      ..moveTo(-s * 0.08, -s * 0.18)
      ..quadraticBezierTo(-s * 0.13, -s * 0.18, -s * 0.165, -s * 0.11)
      ..lineTo(-s * 0.14, s * 0.08)
      ..quadraticBezierTo(-s * 0.12, s * 0.15, -s * 0.11, s * 0.19)
      ..lineTo(s * 0.11, s * 0.19)
      ..quadraticBezierTo(s * 0.12, s * 0.15, s * 0.14, s * 0.08)
      ..lineTo(s * 0.165, -s * 0.11)
      ..quadraticBezierTo(s * 0.13, -s * 0.18, s * 0.08, -s * 0.18)
      ..close();

    // Peitoral anatômico em bronze polido com relevo muscular
    canvas.drawPath(
      torax,
      degrade(
        Rect.fromCenter(center: Offset.zero, width: s * 0.33, height: s * 0.38),
        [const Color(0xFFD4A359), const Color(0xFF9A672E), const Color(0xFF5A381E)],
      ),
    );
    canvas.drawPath(torax, linha(ouro, s * 0.012));

    // Linhas musculares do peitoral no peito
    canvas.drawLine(Offset(0, -s * 0.12), Offset(0, -s * 0.02), linha(bronzeEscuro, s * 0.008));
    canvas.drawArc(
      Rect.fromCenter(center: Offset(-s * 0.045, -s * 0.08), width: s * 0.06, height: s * 0.05),
      0, pi, false, linha(bronzeEscuro, s * 0.007),
    );
    canvas.drawArc(
      Rect.fromCenter(center: Offset(s * 0.045, -s * 0.08), width: s * 0.06, height: s * 0.05),
      0, pi, false, linha(bronzeEscuro, s * 0.007),
    );

    // Pteruges (franjas de couro da armadura na cintura)
    for (var i = -4; i <= 4; i++) {
      final pX = i * s * 0.024;
      final abaPteruge = Path()
        ..moveTo(pX - s * 0.01, s * 0.19)
        ..lineTo(pX + s * 0.01, s * 0.19)
        ..lineTo(pX + s * 0.008, s * 0.25)
        ..lineTo(pX - s * 0.008, s * 0.25)
        ..close();
      canvas.drawPath(abaPteruge, tinta(couro));
      canvas.drawPath(abaPteruge, linha(bronzeEscuro, s * 0.004));
    }

    // Cinto de couro reforçado com fivela dourada
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(0, s * 0.175), width: s * 0.27, height: s * 0.038),
        Radius.circular(s * 0.01),
      ),
      tinta(couro),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(0, s * 0.175), width: s * 0.05, height: s * 0.034),
        Radius.circular(s * 0.006),
      ),
      linha(ouro, s * 0.012),
    );

    // --- 3. BRAÇO ESQUERDO E ESCUDO ESPARTANO (ASPIS) ---
    // Braço esquerdo segurando o escudo
    final bracoEsq = Path()
      ..moveTo(-s * 0.14, -s * 0.12)
      ..quadraticBezierTo(-s * 0.22, -s * 0.08, -s * 0.19, s * 0.02)
      ..lineTo(-s * 0.15, s * 0.03)
      ..quadraticBezierTo(-s * 0.17, -s * 0.04, -s * 0.12, -s * 0.08)
      ..close();
    canvas.drawPath(bracoEsq, tinta(pele));

    // Escudo Circular (Aspis / Hoplon) em destaque à esquerda com o símbolo Lambda (Λ) grego
    canvas.save();
    canvas.translate(-s * 0.17, s * 0.02);
    canvas.rotate(-0.08);

    final escudoRect = Rect.fromCenter(center: Offset.zero, width: s * 0.38, height: s * 0.38);
    // Sombra do escudo
    canvas.drawOval(escudoRect.shift(const Offset(4, 6)), tinta(const Color(0x66000000)));
    // Corpo principal do escudo em bronze reluzente
    canvas.drawOval(escudoRect, degrade(escudoRect, [const Color(0xFFF2D58A), const Color(0xFFB17A39), const Color(0xFF59391F)]));
    canvas.drawOval(escudoRect, linha(bronzeEscuro, s * 0.022));
    canvas.drawOval(escudoRect.deflate(s * 0.02), linha(ouro, s * 0.01));

    // Símbolo Lambda (Λ) espartano em preto/bronze escuro no centro do escudo
    final lambdaPath = Path()
      ..moveTo(0, -s * 0.11)
      ..lineTo(-s * 0.09, s * 0.09)
      ..lineTo(-s * 0.045, s * 0.09)
      ..lineTo(0, -s * 0.01)
      ..lineTo(s * 0.045, s * 0.09)
      ..lineTo(s * 0.09, s * 0.09)
      ..close();
    canvas.drawPath(lambdaPath, tinta(const Color(0xFF2A1A0C)));
    canvas.drawPath(lambdaPath, linha(ouro, s * 0.005));

    // Umboss central do escudo (relevo esférico)
    canvas.drawCircle(Offset(0, s * 0.02), s * 0.035, tinta(bronzeEscuro));
    canvas.drawCircle(
      Offset(0, s * 0.02),
      s * 0.024,
      degrade(
        Rect.fromCircle(center: Offset(0, s * 0.02), radius: s * 0.024),
        [const Color(0xFFFFE8A3), const Color(0xFF8C5522)],
      ),
    );

    canvas.restore();

    // --- 4. BRAÇO DIREITO E GLÁDIO (ESPADA CURTA) ---
    final passoDir = correndo ? -balanco * 1.0 : 0.0;
    canvas.save();
    canvas.translate(s * 0.155, -s * 0.10);
    canvas.rotate(passoDir * 0.25 - 0.2);

    final bracoDir = Path()
      ..moveTo(s * 0.02, -s * 0.04)
      ..quadraticBezierTo(s * 0.07, -s * 0.05, s * 0.09, s * 0.02)
      ..lineTo(s * 0.12, s * 0.14)
      ..quadraticBezierTo(s * 0.12, s * 0.18, s * 0.09, s * 0.19)
      ..quadraticBezierTo(s * 0.05, s * 0.19, s * 0.03, s * 0.14)
      ..lineTo(s * 0.0, s * 0.02)
      ..close();
    canvas.drawPath(bracoDir, tinta(pele));

    // Braçadeira de bronze (punho/antebraço)
    canvas.drawRect(Rect.fromLTWH(s * 0.07, s * 0.10, s * 0.045, s * 0.035), tinta(bronze));
    canvas.drawRect(Rect.fromLTWH(s * 0.07, s * 0.10, s * 0.045, s * 0.035), linha(ouro, s * 0.005));

    // Espada curta grega (Gládio) apontada para a frente/lado com lâmina prateada reluzente
    final gladio = Path()
      ..moveTo(s * 0.09, s * 0.17)
      ..lineTo(s * 0.07, s * 0.38)     // Ponta afiada da espada
      ..lineTo(s * 0.11, s * 0.36)
      ..lineTo(s * 0.12, s * 0.17)
      ..close();
    canvas.drawPath(gladio, degrade(Rect.fromLTWH(s * 0.07, s * 0.17, s * 0.05, s * 0.21), [const Color(0xFFFFFFFF), const Color(0xFFB0C4DE), const Color(0xFF708090)]));
    canvas.drawPath(gladio, linha(const Color(0xFF334455), s * 0.006));

    // Punho e Guarda da Espada
    canvas.drawRect(Rect.fromLTWH(s * 0.075, s * 0.14, s * 0.04, s * 0.035), tinta(ouro));
    canvas.drawCircle(Offset(s * 0.095, s * 0.13), s * 0.015, tinta(bronzeEscuro));

    canvas.restore();

    // --- 5. PESCOÇO, ELMO CORÍNTIO E CRISTA DE PLUMAS VERMELHAS ---
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(0, -s * 0.21), width: s * 0.09, height: s * 0.08),
        Radius.circular(s * 0.02),
      ),
      tinta(pele),
    );

    // Elmo Coríntio de bronze cobrindo a cabeça e a face
    final elmo = Path()
      ..moveTo(-s * 0.11, -s * 0.27)
      ..quadraticBezierTo(-s * 0.13, -s * 0.39, 0, -s * 0.42)
      ..quadraticBezierTo(s * 0.13, -s * 0.39, s * 0.11, -s * 0.27)
      ..lineTo(s * 0.09, -s * 0.22)
      ..lineTo(-s * 0.09, -s * 0.22)
      ..close();

    canvas.drawPath(
      elmo,
      degrade(
        Rect.fromCenter(center: Offset(0, -s * 0.31), width: s * 0.26, height: s * 0.22),
        [const Color(0xFFF2D58A), const Color(0xFFB17A39), const Color(0xFF63401F)],
      ),
    );
    canvas.drawPath(elmo, linha(const Color(0xFF3D2919), s * 0.012));

    // Abertura ocular e nasal clássica do Elmo Coríntio (revelando o olhar sombrio e determinado)
    final aberturaElmo = Path()
      ..moveTo(-s * 0.06, -s * 0.32)
      ..lineTo(s * 0.06, -s * 0.32)
      ..lineTo(s * 0.04, -s * 0.26)
      ..lineTo(-s * 0.04, -s * 0.26)
      ..close();
    canvas.drawPath(aberturaElmo, tinta(const Color(0xFF150D08)));

    // Brilho nos olhos dentro da máscara
    canvas.drawCircle(Offset(-s * 0.025, -s * 0.295), s * 0.005, tinta(const Color(0xFFFFD700)));
    canvas.drawCircle(Offset(s * 0.025, -s * 0.295), s * 0.005, tinta(const Color(0xFFFFD700)));

    // Crista de plumas vermelhas majestosa e volumosa (Crest)
    final cristaGeral = Path()
      ..moveTo(-s * 0.08, -s * 0.40)
      ..quadraticBezierTo(-s * 0.04, -s * 0.49, 0, -s * 0.51)
      ..quadraticBezierTo(s * 0.08, -s * 0.48, s * 0.11, -s * 0.38)
      ..quadraticBezierTo(s * 0.03, -s * 0.42, -s * 0.08, -s * 0.40)
      ..close();

    canvas.drawPath(
      cristaGeral,
      degrade(
        Rect.fromCenter(center: Offset(0, -s * 0.45), width: s * 0.20, height: s * 0.12),
        [const Color(0xFFE63946), const Color(0xFF9B2226), const Color(0xFF5D1013)],
      ),
    );
    canvas.drawPath(cristaGeral, linha(const Color(0xFF3A080A), s * 0.008));

    // Detalhes de cerdas/fios da crista
    for (var i = -3; i <= 3; i++) {
      canvas.drawLine(
        Offset(i * s * 0.015, -s * 0.42),
        Offset(i * s * 0.022 - s * 0.01, -s * 0.48 + (i.abs() * s * 0.005)),
        linha(const Color(0xFFFF6B6B).withValues(alpha: 0.85), s * 0.005),
      );
    }

    canvas.restore();
  }

}
