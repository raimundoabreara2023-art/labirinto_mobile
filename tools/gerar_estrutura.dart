import 'dart:io';

final pastasIgnoradas = {
  '.git',
  '.dart_tool',
  '.idea',
  '.gradle',
  'build',

  // Plataformas geradas pelo Flutter
  'android',
  'ios',
  'linux',
  'macos',
  'windows',
};

final arquivosIgnorados = {
  'estrutura_projeto.txt',

  // Arquivos gerados automaticamente
  'GeneratedPluginRegistrant.java',
  'GeneratedPluginRegistrant.m',
  'GeneratedPluginRegistrant.h',
  'GeneratedPluginRegistrant.swift',

  'generated_plugin_registrant.cc',
  'generated_plugin_registrant.h',
  'generated_plugins.cmake',
};

final extensoesDetalhadas = {
  '.dart',
  '.yaml',
  '.yml',
  '.md',
  '.json',
  '.xml',
  '.gradle',
  '.kts',
};

void main() {
  final rootDir = Directory.current;
  final saida = File('estrutura_projeto.txt');

  final sink = saida.openWrite();

  sink.writeln('=== VERSÃO ENXUTA ===');
  sink.writeln();

  imprimirEstruturaEnxuta(
    rootDir,
    '',
    sink,
  );

  sink.writeln();
  sink.writeln();
  sink.writeln('=== VERSÃO DETALHADA ===');
  sink.writeln();

  imprimirEstruturaDetalhada(
    rootDir,
    '',
    sink,
  );

  sink.close();

  print('Arquivo gerado com sucesso!');
}

void imprimirEstruturaEnxuta(
  FileSystemEntity entidade,
  String indentacao,
  IOSink sink,
) {
  final nome = entidade.path
      .split(Platform.pathSeparator)
      .last;

  if (arquivosIgnorados.contains(nome)) {
    return;
  }

  if (entidade is Directory) {
    if (pastasIgnoradas.contains(nome)) {
      return;
    }

    sink.writeln('$indentacao[DIR] $nome');

    final filhos = entidade.listSync();
    filhos.sort((a, b) => a.path.compareTo(b.path));

    for (final filho in filhos) {
      imprimirEstruturaEnxuta(
        filho,
        '$indentacao   ',
        sink,
      );
    }
  } else {
    sink.writeln('$indentacao$nome');
  }
}

void imprimirEstruturaDetalhada(
  FileSystemEntity entidade,
  String indentacao,
  IOSink sink,
) {
  final nome = entidade.path
      .split(Platform.pathSeparator)
      .last;

  if (arquivosIgnorados.contains(nome)) {
    return;
  }

  if (entidade is Directory) {
    if (pastasIgnoradas.contains(nome)) {
      return;
    }

    sink.writeln('$indentacao[DIR] $nome');

    final filhos = entidade.listSync();
    filhos.sort((a, b) => a.path.compareTo(b.path));

    for (final filho in filhos) {
      imprimirEstruturaDetalhada(
        filho,
        '$indentacao   ',
        sink,
      );
    }
  } else {
    sink.writeln('$indentacao$nome');

    final extensao = nome.contains('.')
        ? nome.substring(nome.lastIndexOf('.'))
        : '';

    if (extensoesDetalhadas.contains(extensao)) {
      sink.writeln(
          '${indentacao}--------------------------------------------------');
      sink.writeln('${indentacao}ARQUIVO: ${entidade.path}');
      sink.writeln(
          '${indentacao}--------------------------------------------------');

      try {
        final linhas = File(entidade.path).readAsLinesSync();

        for (final linha in linhas) {
          sink.writeln('$indentacao   $linha');
        }
      } catch (_) {
        sink.writeln('$indentacao   [ERRO AO LER ARQUIVO]');
      }

      sink.writeln();
    }
  }
}