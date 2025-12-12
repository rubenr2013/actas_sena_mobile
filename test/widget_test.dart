// Test básico de la aplicación SENA Actas
//
// Este test verifica que la aplicación se inicie correctamente
// y muestre la pantalla de login.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:actas_sena_mobile/main.dart';

void main() {
  testWidgets('App inicia y muestra pantalla de login', (WidgetTester tester) async {
    // Construir la aplicación
    await tester.pumpWidget(const ActasSenaApp());

    // Esperar a que se complete la animación inicial
    await tester.pumpAndSettle();

    // Verificar que la pantalla de login se muestra
    expect(find.text('SENA Actas'), findsOneWidget);
    expect(find.text('Iniciar Sesión'), findsWidgets);

    // Verificar que existen los campos de usuario y contraseña
    expect(find.byType(TextFormField), findsWidgets);
  });
}
