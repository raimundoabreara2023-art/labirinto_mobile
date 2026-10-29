import 'package:flutter/material.dart';

/// Renderizador visual do Minotauro proporcional à visão interna:
/// ligeiramente maior que o guerreiro espartano, mas perfeitamente contido no corredor.
/// Registros informando que este código foi gerado com o auxílio de inteligência artificial.
class CentauroRenderer {
  void desenhar(
    Canvas canvas, {
    required Offset centro,
    required double tamanho,
    required IconData icone,
    required Color cor,
    required Color corBrilho,
  }) {
    // Escala reduzida para ficar proporcional ao herói e menor que o corredor
    final s = tamanho * 0.42;

    canvas.save();
    canvas.translate(centro.dx, centro.dy);

    // Sombra projetada no chão
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, s * 0.48),
        width: s * 0.80,
        height: s * 0.20,
      ),
      Paint()..color = const Color(0x77000000),
    );

    // Brilho místico de alerta contido
    canvas.drawCircle(
      Offset.zero,
      s * 0.65,
      Paint()..color = corBrilho.withValues(alpha: 0.22),
    );

    final peloEscuro = const Color(0xFF2A1A12);
    final peloMedio = const Color(0xFF452B1E);
    final couro = const Color(0xFF1F120A);
    final bronze = const Color(0xFF9A672E);
    final bronzeEscuro = const Color(0xFF4A2E14);
    final marfimChifres = const Color(0xFFEFE6D5);

    Paint tinta(Color c) => Paint()
      ..color = c
      ..isAntiAlias = true;

    Paint linha(Color c, double esp) => Paint()
      ..color = c
      ..strokeWidth = esp
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    // --- 1. PERNAS ROBUSTAS ---
    for (final dir in [-1.0, 1.0]) {
      final offsetX = dir * s * 0.10;
      
      final perna = Path()
        ..moveTo(offsetX - s * 0.04, -s * 0.15)
        ..lineTo(offsetX + dir * s * 0.03, s * 0.38)
        ..lineTo(offsetX + dir * s * 0.09, s * 0.38)
        ..lineTo(offsetX + s * 0.04, -s * 0.15)
        ..close();
      canvas.drawPath(perna, tinta(peloEscuro));
      canvas.drawPath(perna, linha(bronzeEscuro, s * 0.006));

      // Cascos pesados
      canvas.drawRect(
        Rect.fromLTWH(offsetX + (dir > 0 ? 0 : -s * 0.04), s * 0.35, s * 0.09, s * 0.05),
        tinta(couro),
      );
    }

    // --- 2. TORSO HUMANOIDE ROBUSTO ---
    final torso = Path()
      ..moveTo(-s * 0.18, -s * 0.18)
      ..quadraticBezierTo(-s * 0.28, -s * 0.38, -s * 0.20, -s * 0.55)
      ..lineTo(s * 0.20, -s * 0.55)
      ..quadraticBezierTo(s * 0.28, -s * 0.38, s * 0.18, -s * 0.18)
      ..close();

    canvas.drawPath(torso, tinta(peloMedio));
    canvas.drawPath(torso, linha(bronzeEscuro, s * 0.01));

    // Peitoral de bronze
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(0, -s * 0.38), width: s * 0.34, height: s * 0.22),
        Radius.circular(s * 0.05),
      ),
      tinta(bronze),
    );

    // Cinto de couro
    canvas.drawRect(
      Rect.fromCenter(center: Offset(0, -s * 0.16), width: s * 0.40, height: s * 0.08),
      tinta(couro),
    );

    // --- 3. CABEÇA DE TOURO E CHIFRES ---
    final cabecaTouro = Path()
      ..moveTo(-s * 0.14, -s * 0.55)
      ..lineTo(-s * 0.18, -s * 0.75)
      ..lineTo(s * 0.18, -s * 0.75)
      ..lineTo(s * 0.14, -s * 0.55)
      ..close();
    canvas.drawPath(cabecaTouro, tinta(peloEscuro));
    canvas.drawPath(cabecaTouro, linha(bronzeEscuro, s * 0.008));

    canvas.drawOval(
      Rect.fromCenter(center: Offset(0, -s * 0.67), width: s * 0.20, height: s * 0.12),
      tinta(couro),
    );
    canvas.drawCircle(Offset(0, -s * 0.61), s * 0.03, linha(const Color(0xFFD4AF37), s * 0.012));

    canvas.drawCircle(Offset(-s * 0.07, -s * 0.70), s * 0.018, tinta(Colors.redAccent));
    canvas.drawCircle(Offset(s * 0.07, -s * 0.70), s * 0.018, tinta(Colors.redAccent));

    for (final dir in [-1.0, 1.0]) {
      final chifre = Path()
        ..moveTo(dir * s * 0.12, -s * 0.73)
        ..quadraticBezierTo(dir * s * 0.28, -s * 0.92, dir * s * 0.35, -s * 0.78)
        ..quadraticBezierTo(dir * s * 0.25, -s * 0.77, dir * s * 0.10, -s * 0.68)
        ..close();
      canvas.drawPath(chifre, tinta(marfimChifres));
      canvas.drawPath(chifre, linha(bronzeEscuro, s * 0.005));
    }

    // --- 4. BRAÇOS E MACHADO ---
    canvas.drawLine(
      Offset(-s * 0.20, -s * 0.45),
      Offset(-s * 0.40, -s * 0.28),
      linha(peloMedio, s * 0.07),
    );

    canvas.drawLine(
      Offset(s * 0.20, -s * 0.45),
      Offset(s * 0.38, -s * 0.55),
      linha(peloMedio, s * 0.07),
    );

    canvas.drawLine(
      Offset(s * 0.38, -s * 0.68),
      Offset(s * 0.38, -s * 0.18),
      linha(couro, s * 0.035),
    );

    final laminaMachado = Path()
      ..moveTo(s * 0.38, -s * 0.58)
      ..quadraticBezierTo(s * 0.55, -s * 0.63, s * 0.52, -s * 0.43)
      ..quadraticBezierTo(s * 0.45, -s * 0.48, s * 0.38, -s * 0.48)
      ..close();
    canvas.drawPath(laminaMachado, tinta(const Color(0xFFC0C0C0)));
    canvas.drawPath(laminaMachado, linha(bronzeEscuro, s * 0.006));

    canvas.restore();
  }
}