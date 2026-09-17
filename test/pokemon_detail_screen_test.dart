import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:pokeclase20263/providers/poke_api_provider.dart';
import 'package:pokeclase20263/screens/pokemon_detail_screen.dart';
import 'package:pokeclase20263/screens/generation_detail_screen.dart';
import 'package:provider/provider.dart';

class FakePokeApi extends PokeApiProvider {
  bool fail = false;
  int speciesCalls = 0;
  int? requestedPokemon;

  @override
  Future<http.Response> getGenerationDetail(int id) async => http.Response(
    jsonEncode({
      'id': id,
      'name': 'generation-i',
      'pokemon_species': [
        for (final entry in {
          3: 'venusaur',
          1: 'bulbasaur',
          2: 'ivysaur',
        }.entries)
          {
            'name': entry.value,
            'url': 'https://pokeapi.co/api/v2/pokemon-species/${entry.key}/',
          },
      ],
    }),
    200,
  );

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
  testWidgets('Small screen scrolls to all details without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(app(FakePokeApi()));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Ver evoluciones'));
    await tester.tap(find.text('Ver evoluciones'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(LinearProgressIndicator));
    await tester.pumpAndSettle();
    expect(find.byType(LinearProgressIndicator).hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Grid opens selected ID and swipes in Pokedex order', (
    tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<PokeApiProvider>.value(
        value: FakePokeApi(),
        child: const MaterialApp(home: GenerationDetailScreen(generationId: 1)),
      ),
    );
    await tester.pumpAndSettle();
    final gridHero = tester.widget<Hero>(
      find.ancestor(of: find.byType(Image).at(1), matching: find.byType(Hero)),
    );
    expect(gridHero.tag, 'pokemon-2');
    await tester.tap(find.text('Ivysaur'));
    await tester.pump();
    // The destination Hero must exist before the detail request completes.
    expect(
      find.byWidgetPredicate((w) => w is Hero && w.tag == 'pokemon-2'),
      findsWidgets,
    );
    await tester.pumpAndSettle();
    final pager = tester.widget<PageView>(find.byType(PageView));
    expect(pager.controller!.initialPage, 1);
    expect(find.text('#002'), findsOneWidget);

    Future<void> swipe(double dx, String number) async {
      await tester.drag(find.byType(PageView), Offset(dx, 0));
      await tester.pumpAndSettle();
      expect(find.text(number), findsOneWidget);
      expect(tester.takeException(), isNull);
    }

    await swipe(-600, '#003');
    await swipe(-600, '#003');
    await swipe(600, '#002');
    await swipe(600, '#001');
    await swipe(600, '#001');
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(GridView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

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
