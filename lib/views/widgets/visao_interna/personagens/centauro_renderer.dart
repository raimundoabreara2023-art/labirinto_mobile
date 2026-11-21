import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Desenha o minotauro (PNG sem fundo) em pé no chão do labirinto.
///
/// O raycasting entrega [centro] e [tamanho] já calculados pela perspectiva:
/// a base do tamanho (centro.dy + tamanho / 2) é exatamente a linha do chão
/// onde o minotauro pisa. Aqui só ancoramos os cascos nessa linha, projetamos
/// uma sombra e aplicamos a luz da tocha conforme a distância.
class CentauroRenderer {
  /// Altura do minotauro em relação ao [tamanho] recebido.
  /// O sprite chega com 70% da altura da parede; 1.25 deixa o minotauro
  /// com cerca de 87% da altura do corredor.
  static const double _fatorAltura = 1.25;

  void desenhar(
    Canvas canvas, {
    required Offset centro,
    required double tamanho,
    required IconData icone,
    required Color cor,
    required Color corBrilho,
    required ui.Image? imagem,
    required double distancia,
    bool andando = false,
    double fase = 0,
  }) {
    if (imagem == null) return;

    final proporcao = imagem.width / imagem.height;
    final altura = tamanho * _fatorAltura;
    final largura = altura * proporcao;

    // Ponto onde os cascos tocam o chão.
    final pesX = centro.dx;
    final pesY = centro.dy + tamanho / 2;

    // Luz da tocha: mais longe, mais escuro (mesma curva usada nos sprites).
    final luz = cor.a.clamp(0.4, 1.0).toDouble();

    // Sombra de contato no chão, sempre colada nos pés.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(pesX, pesY - altura * 0.01),
        width: largura * 0.75,
        height: altura * 0.07,
      ),
      Paint()
        ..color = Color.fromRGBO(0, 0, 0, 0.5 * luz)
        ..isAntiAlias = true,
    );

    // Balanço de caminhada: sobe e desce a cada passo e inclina de leve.
    final pulo = andando ? sin(fase * 4 * pi).abs() * altura * 0.015 : 0.0;
    final balanco = andando ? sin(fase * 2 * pi) * 0.025 : 0.0;

    canvas.save();
    canvas.translate(pesX, pesY - pulo);
    canvas.rotate(balanco);

    final paint = Paint()
      ..isAntiAlias = true
      ..filterQuality = FilterQuality.high
      ..colorFilter = ColorFilter.mode(
        Color.fromRGBO(
          (255 * luz).round(),
          (240 * luz).round(),
          (230 * luz).round(),
          1.0,
        ),
        BlendMode.modulate,
      );

    canvas.drawImageRect(
      imagem,
      Rect.fromLTWH(0, 0, imagem.width.toDouble(), imagem.height.toDouble()),
      Rect.fromLTWH(-largura / 2, -altura, largura, altura),
      paint,
    );

    canvas.restore();
  }
}