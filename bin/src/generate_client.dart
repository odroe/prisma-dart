// ignore_for_file: file_names

import 'package:code_builder/code_builder.dart';
import 'package:orm/dmmf/src/mappings.dart';

import 'generate_delegate.dart';
import 'generator.dart';
import 'utils/dart_style_fixer.dart';

extension GenerateClient on Generator {
  Extension generateClient() {
    return Extension((builder) {
      builder.name = 'PrismaClient\$Extention';
      builder.on = TypeReference((type) {
        type.symbol = 'PrismaClient';
        type.url = 'package:orm/orm.dart';
        type.types.add(refer('T'));
      });
      builder.types.add(refer('T'));
      builder.fields.add(generateDatamodel());

      for (final mapping in options.dmmf.mappings.modelOperations) {
        builder.methods.add(generateModelOperation(mapping));
      }
    });
  }
}

extension on Generator {
  Field generateDatamodel() {
    return Field((builder) {
      builder.static = true;
      builder.modifier = FieldModifier.final$;
      builder.name = 'datamodel';
      builder.assignment = refer('DataModel', 'package:orm/dmmf.dart')
          .newInstanceNamed('fromJson', [
        literalMap(options.dmmf.source['datamodel']),
      ]).code;
    });
  }

  Method generateModelOperation(ModelMapping mapping) {
    final type = generateDelegate(mapping);

    return Method((method) {
      method.name = mapping.plural.propertyName;
      method.returns = type;
      method.type = MethodType.getter;
      method.lambda = true;
      method.body = type.newInstanceNamed('_', [refer('this')]).code;
    });
  }
}
