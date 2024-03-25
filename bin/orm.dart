import 'dart:io';

import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:orm/generator_helper.dart';
import 'package:orm/version.dart';
import 'package:path/path.dart';

import 'src/generator.dart';

void main() async {
  final app = GeneratorApp.stdio(stdin: stdin, stdout: stderr);
  app.onManifest(manifest);
  app.onGenerate(generate);

  await app.listen();
}

Future<GeneratorManifest> manifest(GeneratorConfig config) async {
  return GeneratorManifest(
    prettyName: 'Prisma Dart Client',
    defaultOutput: 'generated_dart_client',
    version: 'v$version',
    requiresEngines: [EngineType.queryEngine],
  );
}

Future<void> generate(GeneratorOptions options) async {
  if (options.generator.output == null) {
    throw StateError('No output directory specified');
  }

  final generator = Generator(options);
  final libraries = generator.generate();
  final formatter = DartFormatter();

  for (final (filename, library) in libraries) {
    final emitter = DartEmitter.scoped(
      useNullSafetySyntax: true,
      orderDirectives: true,
    );
    final source = library.accept(emitter);
    // final formated = formatter.format(source.toString());
    final output = await File(join(options.generator.output!.value, filename))
        .autoCreate();

    // TODO: Bug in dart formatter, https://github.com/medz/prisma-dart/issues/344#issuecomment-2018074768
    await output.writeAsString(source.toString());

    // await output.writeAsString(formated);
  }

  // Copy prisma query engine.
  final engineDownloadPath =
      options.binaryPaths.queryEngine?.values.firstOrNull;
  if (engineDownloadPath != null) {
    await File(engineDownloadPath).copy('prisma-query-engine');
  }
}

extension on File {
  Future<File> autoCreate() async {
    if (await exists()) {
      return this;
    }

    await parent.create(recursive: true);
    return create();
  }
}
