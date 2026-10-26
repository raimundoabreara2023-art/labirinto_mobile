import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:labirinto_mobile/main.dart';

void main() {
  Future<void> prepararTela(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('O jogo inicia com mapa e contador', (tester) async {
    await prepararTela(tester);
    await tester.pumpWidget(const LabirintoApp());

    expect(find.textContaining('LABIRINTO VIVO'), findsOneWidget);
    expect(find.textContaining('Nova partida iniciada'), findsOneWidget);
    expect(find.byKey(const Key('MOVIMENTOS')), findsOneWidget);
    expect(find.byKey(const Key('Avançar')), findsOneWidget);
  });

  testWidgets('O jogador consegue se movimentar', (tester) async {
    await prepararTela(tester);
    await tester.pumpWidget(const LabirintoApp());

    await tester.tap(find.byKey(const Key('Avançar')));
    await tester.pump();

    expect(find.byKey(const Key('MOVIMENTOS')), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('O botão alterna entre visão interna e mapa aéreo', (tester) async {
    await prepararTela(tester);
    await tester.pumpWidget(const LabirintoApp());

    expect(find.textContaining('TUDO PAUSADO'), findsNothing);

    await tester.tap(find.byKey(const Key('alternar visao')));
    await tester.pump();
    expect(find.textContaining('TUDO PAUSADO'), findsOneWidget);

    await tester.tap(find.byKey(const Key('alternar visao')));
    await tester.pump();
    expect(find.textContaining('TUDO PAUSADO'), findsNothing);
  });

  testWidgets('O botão reinicia a partida', (tester) async {
    await prepararTela(tester);
    await tester.pumpWidget(const LabirintoApp());

    await tester.tap(find.byKey(const Key('Avançar')));
    await tester.pump();

    await tester.tap(find.byKey(const Key('reiniciar')));
    await tester.pump();

    expect(find.text('0'), findsOneWidget);
    expect(find.byKey(const Key('reiniciar')), findsOneWidget);
  });
}