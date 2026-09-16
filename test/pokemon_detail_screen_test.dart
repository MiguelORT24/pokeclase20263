import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:pokeclase20263/providers/poke_api_provider.dart';
import 'package:pokeclase20263/screens/pokemon_detail_screen.dart';
import 'package:provider/provider.dart';

class FakePokeApi extends PokeApiProvider {
  bool fail = false;
  int speciesCalls = 0;
  int? requestedPokemon;

  @override
  Future<http.Response> getPokemonSpecies(int id) async {
    speciesCalls++;
    if (fail) return http.Response('{}', 503);
    return http.Response(
      jsonEncode({
        'varieties': [
          {
            'is_default': true,
            'pokemon': {'url': 'https://pokeapi.co/api/v2/pokemon/10001/'},
          },
        ],
        'flavor_text_entries': [
          {
            'language': {'name': 'en'},
            'flavor_text': 'English description',
          },
          {
            'language': {'name': 'es'},
            'flavor_text': 'Descripción\nde prueba.',
          },
        ],
      }),
      200,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  }

  @override
  Future<http.Response> getPokemonDetail(int id) async {
    requestedPokemon = id;
    return http.Response(
      jsonEncode({
        'height': 7,
        'weight': 69,
        'sprites': {},
        'types': [
          {
            'type': {'name': 'grass'},
          },
        ],
        'abilities': [
          {
            'ability': {'name': 'overgrow'},
            'is_hidden': false,
          },
        ],
        'stats': [
          {
            'stat': {'name': 'hp'},
            'base_stat': 45,
          },
        ],
      }),
      200,
    );
  }
}

Widget app(FakePokeApi api) => ChangeNotifierProvider<PokeApiProvider>.value(
  value: api,
  child: const MaterialApp(
    home: PokemonDetailScreen(pokemonId: 1, pokemonName: 'bulbasaur'),
  ),
);

void main() {
  testWidgets('Loads default variety, Spanish description and measurements', (
    tester,
  ) async {
    final api = FakePokeApi();
    await tester.pumpWidget(app(api));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();
    expect(api.requestedPokemon, 10001);
    expect(find.text('Planta'), findsOneWidget);
    expect(find.text('Descripción de prueba.'), findsOneWidget);
    expect(find.text('Altura: 0.7 m'), findsOneWidget);
    expect(find.text('Peso: 6.9 kg'), findsOneWidget);
    await tester.pumpWidget(app(api));
    await tester.pumpAndSettle();
    expect(api.speciesCalls, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Retries a failed request', (tester) async {
    final api = FakePokeApi()..fail = true;
    await tester.pumpWidget(app(api));
    await tester.pumpAndSettle();
    expect(find.text('Reintentar'), findsOneWidget);
    api.fail = false;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.text('Planta'), findsOneWidget);
    expect(api.speciesCalls, 2);
    expect(tester.takeException(), isNull);
  });
}
