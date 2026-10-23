
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

    expect(find.text('O LABIRINTO VIVO'), findsOneWidget);
    expect(find.text('ENCONTRE A SAÍDA'), findsOneWidget);
    expect(find.byKey(const Key('MOVIMENTOS')), findsOneWidget);
    expect(
      find.byKey(const Key('Mover para direita')),
      findsOneWidget,
    );
  });

  testWidgets('O jogador consegue se movimentar', (tester) async {
    await prepararTela(tester);
    await tester.pumpWidget(const LabirintoApp());

    await tester.tap(find.byKey(const Key('Mover para direita')));
    await tester.pump();

    expect(find.byKey(const Key('MOVIMENTOS')), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('O botão reinicia a partida', (tester) async {
    await prepararTela(tester);
    await tester.pumpWidget(const LabirintoApp());

    await tester.tap(find.byKey(const Key('Mover para direita')));
    await tester.pump();

    await tester.tap(find.byKey(const Key('reiniciar')));
    await tester.pump();

    expect(find.text('0'), findsOneWidget);
    expect(find.byKey(const Key('reiniciar')), findsOneWidget);
  });
}
