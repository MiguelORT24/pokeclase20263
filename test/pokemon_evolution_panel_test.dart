import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:pokeclase20263/providers/poke_api_provider.dart';
import 'package:pokeclase20263/screens/pokemon_evolution_panel.dart';

class EvolutionApi extends PokeApiProvider {
  int calls = 0;
  bool fail = false;
  bool single = false;

  Map<String, dynamic> node(
    int id,
    String name, [
    List<dynamic> children = const [],
  ]) => {
    'species': {
      'name': name,
      'url': 'https://pokeapi.co/api/v2/pokemon-species/$id/',
    },
    'evolves_to': children,
  };

  @override
  Future<http.Response> getEvolutionChain(int id) async {
    calls++;
    if (fail) return http.Response('{}', 503);
    return http.Response(
      jsonEncode({
        'chain': single
            ? node(1017, 'ogerpon')
            : node(133, 'eevee', [node(134, 'vaporeon'), node(135, 'jolteon')]),
      }),
      200,
    );
  }
}

Widget app(EvolutionApi api) => ChangeNotifierProvider<PokeApiProvider>.value(
  value: api,
  child: MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: PokemonEvolutionPanel(
          chainUrl: 'https://pokeapi.co/api/v2/evolution-chain/67/',
          selectedId: api.single ? 1017 : 133,
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets(
    'Loads lazily, preserves branches, and reuses result after collapse',
    (tester) async {
      final api = EvolutionApi();
      await tester.pumpWidget(app(api));
      expect(api.calls, 0);
      await tester.tap(find.text('Ver evoluciones'));
      await tester.pumpAndSettle();
      expect(find.text('Ruta 1'), findsOneWidget);
      expect(find.text('Ruta 2'), findsOneWidget);
      expect(find.text('Vaporeon'), findsOneWidget);
      expect(find.text('Jolteon'), findsOneWidget);
      expect(find.text('Etapa 3'), findsNothing);
      await tester.tap(find.text('Ocultar evoluciones'));
      await tester.pumpAndSettle();
      expect(find.text('Vaporeon'), findsNothing);
      await tester.tap(find.text('Ver evoluciones'));
      await tester.pumpAndSettle();
      expect(api.calls, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Single species shows friendly message', (tester) async {
    await tester.pumpWidget(app(EvolutionApi()..single = true));
    await tester.tap(find.text('Ver evoluciones'));
    await tester.pumpAndSettle();
    expect(
      find.text('¡Este Pokémon es único! No tiene evoluciones.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Evolution failure can be retried', (tester) async {
    final api = EvolutionApi()..fail = true;
    await tester.pumpWidget(app(api));
    await tester.tap(find.text('Ver evoluciones'));
    await tester.pumpAndSettle();
    expect(find.text('No se pudieron cargar las evoluciones.'), findsOneWidget);
    api.fail = false;
    await tester.tap(find.text('Reintentar evoluciones'));
    await tester.pumpAndSettle();
    expect(find.text('Vaporeon'), findsOneWidget);
    expect(api.calls, 2);
    expect(tester.takeException(), isNull);
  });
}
