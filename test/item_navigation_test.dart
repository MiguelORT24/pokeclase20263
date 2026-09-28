import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:pokeclase20263/main.dart';
import 'package:pokeclase20263/providers/poke_api_provider.dart';
import 'package:pokeclase20263/screens/item_detail_screen.dart';

class ItemApi extends PokeApiProvider {
  bool fail = false;
  bool empty = false;
  bool failDetails = false;
  int categoryCalls = 0;
  int? selectedCategory;

  @override
  Future<http.Response> getGenerations() async => http.Response(
    '{"count":1,"next":null,"previous":null,"results":[{"name":"generation-i","url":"https://pokeapi.co/api/v2/generation/1/"}]}',
    200,
  );

  @override
  Future<List<Map<String, dynamic>>> getItemCategories() async {
    categoryCalls++;
    if (fail) throw Exception('offline');
    return [
      {
        'name': 'standard-balls',
        'url': 'https://pokeapi.co/api/v2/item-category/34/',
      },
    ];
  }

  @override
  Future<Map<String, dynamic>> getItemCategory(int id) async {
    selectedCategory = id;
    return {
      'items': empty
          ? []
          : [
              {'name': 'poke-ball', 'url': 'https://pokeapi.co/api/v2/item/4/'},
              {
                'name': 'master-ball',
                'url': 'https://pokeapi.co/api/v2/item/1/',
              },
            ],
    };
  }

  @override
  Future<Map<String, dynamic>> getItemDetail(int id) async {
    if (failDetails) throw Exception('offline');
    return {
      'sprites': {'default': null},
      'names': [
        {
          'name': id == 4 ? 'Poké Ball' : 'Master Ball',
          'language': {'name': 'es'},
        },
      ],
      'flavor_text_entries': [
        {
          'text': 'English description.',
          'language': {'name': 'en'},
        },
        {
          'text': 'Descripción\nen español.',
          'language': {'name': 'es'},
        },
      ],
      'effect_entries': [
        {
          'short_effect': 'Catches Pokémon.',
          'language': {'name': 'en'},
        },
      ],
      'attributes': [
        {'name': 'holdable'},
      ],
      'fling_power': null,
      'fling_effect': null,
      'prices': [
        {
          'version_group': {'name': 'red-blue'},
          'currency': {'name': 'poke-dollar'},
          'purchase_price': 200,
          'sell_price': null,
        },
      ],
    };
  }
}

Future<void> openItems(WidgetTester tester, ItemApi api) async {
  await tester.pumpWidget(
    ChangeNotifierProvider<PokeApiProvider>.value(
      value: api,
      child: const MyApp(),
    ),
  );
  await tester.pumpAndSettle();
  expect(find.text('generation-i'), findsOneWidget);
  await tester.tap(find.text('Ítems'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'Item card opens selected detail, swipes by ID, and returns to grid',
    (tester) async {
      final api = ItemApi();
      await openItems(tester, api);
      await tester.tap(find.text('Poké Balls estándar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Poke Ball'));
      await tester.pumpAndSettle();
      expect(find.byType(ItemDetailScreen), findsOneWidget);
      expect(find.text('Poké Ball'), findsNWidgets(2));
      expect(find.text('#004'), findsOneWidget);
      expect(find.text('Descripción en español.'), findsOneWidget);
      expect(find.text('English description.'), findsNothing);
      expect(find.text('Efecto (inglés)'), findsOneWidget);
      expect(find.text('Se puede equipar'), findsOneWidget);
      expect(find.text('Poké Balls estándar'), findsNothing);
      await tester.ensureVisible(find.text('Compra y venta por juego'));
      await tester.tap(find.text('Compra y venta por juego'));
      await tester.pumpAndSettle();
      expect(
        find.text('Compra: 200 ₽\nVenta: No se puede vender'),
        findsOneWidget,
      );
      await tester.drag(find.byType(PageView), const Offset(600, 0));
      await tester.pumpAndSettle();
      expect(find.text('#001'), findsOneWidget);
      expect(find.text('Master Ball'), findsNWidgets(2));
      expect(tester.takeException(), isNull);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(GridView), findsOneWidget);
      expect(find.text('Poké Balls estándar'), findsOneWidget);
    },
  );

  testWidgets('Failed item details can be retried', (tester) async {
    final api = ItemApi();
    await openItems(tester, api);
    await tester.tap(find.text('Poké Balls estándar'));
    await tester.pumpAndSettle();
    api.failDetails = true;
    await tester.tap(find.text('Master Ball'));
    await tester.pumpAndSettle();
    expect(
      find.text('No se pudieron cargar los detalles del ítem.'),
      findsOneWidget,
    );
    api.failDetails = false;
    await tester.ensureVisible(find.text('Reintentar'));
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.text('Descripción en español.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Tabs, category grid and back preserve the selected section', (
    tester,
  ) async {
    final api = ItemApi();
    await openItems(tester, api);
    final tabContext = tester.element(find.byType(TabBar));
    expect(DefaultTabController.of(tabContext).index, 1);
    await tester.tap(find.text('Poké Balls estándar'));
    await tester.pumpAndSettle();
    expect(api.selectedCategory, 34);
    expect(find.text('Poké Balls estándar'), findsOneWidget);
    expect(find.byType(GridView), findsOneWidget);
    expect(find.text('#001'), findsOneWidget);
    expect(find.text('Master Ball'), findsOneWidget);
    expect(find.text('Poke Ball'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Poké Balls estándar'), findsOneWidget);
    expect(
      DefaultTabController.of(tester.element(find.byType(TabBar))).index,
      1,
    );
    expect(api.categoryCalls, 1);
    await tester.tap(find.text('Generaciones'));
    await tester.pumpAndSettle();
    expect(find.text('generation-i'), findsOneWidget);
  });

  testWidgets(
    'Category failures can be retried and empty grids are explained',
    (tester) async {
      final api = ItemApi()..fail = true;
      await openItems(tester, api);
      expect(find.text('Reintentar'), findsOneWidget);
      api.fail = false;
      api.empty = true;
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Poké Balls estándar'));
      await tester.pumpAndSettle();
      expect(find.text('Esta categoría no tiene ítems.'), findsOneWidget);
      expect(api.categoryCalls, 2);
      expect(tester.takeException(), isNull);
    },
  );
}
