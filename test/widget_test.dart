import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logifaena_master/src/app.dart';

void main() {
  test('LogiFaenaApp expone el widget raíz vigente', () {
    const app = LogiFaenaApp();
    expect(app, isA<Widget>());
  });
}
