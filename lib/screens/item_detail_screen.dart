import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pokeclase20263/providers/poke_api_provider.dart';
import 'package:pokeclase20263/screens/item_categories_screen.dart';

class ItemDetailScreen extends StatefulWidget {
  final int itemId;
  final List<Map<String, dynamic>> items;

  const ItemDetailScreen({
    super.key,
    required this.itemId,
    required this.items,
  });

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  late final List<Map<String, dynamic>> _items;
  late final PageController _controller;

  @override
  void initState() {
    super.initState();
    _items = List.of(widget.items)
      ..sort((a, b) => itemResourceId(a).compareTo(itemResourceId(b)));
    _controller = PageController(
      initialPage: _items.indexWhere(
        (item) => itemResourceId(item) == widget.itemId,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PageView.builder(
    controller: _controller,
    itemCount: _items.length,
    itemBuilder: (_, index) => _ItemDetailPage(
      key: ValueKey(itemResourceId(_items[index])),
      item: _items[index],
    ),
  );
}

class _ItemDetailPage extends StatefulWidget {
  final Map<String, dynamic> item;
  const _ItemDetailPage({super.key, required this.item});

  @override
  State<_ItemDetailPage> createState() => _ItemDetailPageState();
}

class _ItemDetailPageState extends State<_ItemDetailPage> {
  late Future<Map<String, dynamic>> _detail;
  int get _id => itemResourceId(widget.item);

  @override
  void initState() {
    super.initState();
    _detail = _load();
  }

  Future<Map<String, dynamic>> _load() =>
      context.read<PokeApiProvider>().getItemDetail(_id);

  @override
  Widget build(BuildContext context) {
    final colors = ColorScheme.fromSeed(seedColor: const Color(0xFF5345AB));
    return Theme(
      data: ThemeData(useMaterial3: true, colorScheme: colors),
      child: FutureBuilder<Map<String, dynamic>>(
        future: _detail,
        builder: (context, snapshot) {
          final data = snapshot.data;
          final name =
              _localized(data?['names'], 'name')?.$1 ??
              itemDisplayName(widget.item['name'] as String);
          final sprite = data?['sprites']?['default'] as String?;
          return Scaffold(
            backgroundColor: colors.primaryContainer,
            appBar: AppBar(
              title: Text(name),
              backgroundColor: colors.primaryContainer,
              scrolledUnderElevation: 0,
            ),
            body: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    colors.primaryContainer,
                    colors.surface,
                    colors.secondaryContainer,
                  ],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: SingleChildScrollView(
                  key: PageStorageKey('item-detail-$_id'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: 230,
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: sprite == null
                              ? Icon(
                                  Icons.inventory_2_outlined,
                                  size: 100,
                                  color: colors.primary,
                                )
                              : Image.network(
                                  sprite,
                                  fit: BoxFit.contain,
                                  filterQuality: FilterQuality.none,
                                  errorBuilder: (_, error, stack) => Icon(
                                    Icons.inventory_2_outlined,
                                    size: 100,
                                    color: colors.primary,
                                  ),
                                ),
                        ),
                      ),
                      Container(
                        constraints: BoxConstraints(
                          minHeight: MediaQuery.sizeOf(context).height * 0.55,
                        ),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(36),
                          ),
                        ),
                        padding: EdgeInsets.fromLTRB(
                          24,
                          24,
                          24,
                          MediaQuery.paddingOf(context).bottom + 24,
                        ),
                        child: snapshot.connectionState != ConnectionState.done
                            ? const Center(child: CircularProgressIndicator())
                            : snapshot.hasError || data == null
                            ? Column(
                                children: [
                                  const Icon(Icons.wifi_off_rounded, size: 48),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'No se pudieron cargar los detalles del ítem.',
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  FilledButton.icon(
                                    onPressed: () => setState(() {
                                      _detail = _load();
                                    }),
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('Reintentar'),
                                  ),
                                ],
                              )
                            : Center(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 650,
                                  ),
                                  child: Material(
                                    color: Colors.white,
                                    child: _content(data, name, colors),
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _content(Map<String, dynamic> data, String name, ColorScheme colors) {
    final description = _localized(data['flavor_text_entries'], 'text');
    final effect =
        _localized(data['effect_entries'], 'short_effect') ??
        _localized(data['effect_entries'], 'effect');
    final attributes = data['attributes'] as List? ?? [];
    final prices = data['prices'] as List? ?? [];
    final flingPower = data['fling_power'];
    final flingEffect = data['fling_effect']?['name'] as String?;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '#${_id.toString().padLeft(3, '0')}',
          textAlign: TextAlign.center,
          style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold),
        ),
        Text(
          name,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        _section('Acerca de${description?.$2 == 'en' ? ' (inglés)' : ''}', [
          Text(description?.$1 ?? 'No hay descripción disponible.'),
        ]),
        if (effect != null)
          _section('Efecto${effect.$2 == 'en' ? ' (inglés)' : ''}', [
            Text(effect.$1),
          ]),
        if (attributes.isNotEmpty)
          _section('Características', [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final attribute in attributes)
                  Chip(
                    label: Text(
                      _attributeNames[attribute['name']] ??
                          itemDisplayName(attribute['name'] as String),
                    ),
                  ),
              ],
            ),
          ]),
        _section('Precio', [
          if (prices.isNotEmpty)
            ExpansionTile(
              key: PageStorageKey('item-prices-$_id'),
              tilePadding: EdgeInsets.zero,
              title: const Text('Compra y venta por juego'),
              children: [
                for (final price in prices)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      itemDisplayName(
                        price['version_group']?['name'] as String? ??
                            'desconocido',
                      ),
                    ),
                    subtitle: Text(
                      'Compra: ${_price(price['purchase_price'], price['currency']?['name'], 'No se puede comprar')}\n'
                      'Venta: ${_price(price['sell_price'], price['currency']?['name'], 'No se puede vender')}',
                    ),
                  ),
              ],
            )
          else if (data['cost'] != null)
            Text('Precio base: ${data['cost']} ₽')
          else
            const Text('No hay precios disponibles.'),
        ]),
        _section('Lanzamiento', [
          if (flingPower == null)
            const Text('No hay potencia de Lanzamiento registrada.')
          else
            Text('Potencia: $flingPower'),
          if (flingEffect != null) ...[
            const SizedBox(height: 8),
            Text(_flingEffects[flingEffect] ?? itemDisplayName(flingEffect)),
          ],
        ]),
      ],
    );
  }
}

Widget _section(String title, List<Widget> children) => Padding(
  padding: const EdgeInsets.only(bottom: 24),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 12),
      ...children,
    ],
  ),
);

(String, String)? _localized(dynamic entries, String field) {
  for (final language in ['es', 'en']) {
    for (final entry in (entries as List? ?? [])) {
      final text = entry[field] as String?;
      if (entry['language']?['name'] == language &&
          text != null &&
          text.trim().isNotEmpty) {
        return (
          text
              .replaceAllMapped(
                RegExp(r'\[([^\]]+)\]\{[^}]+\}'),
                (match) => match[1]!,
              )
              .replaceAll(RegExp(r'\s+'), ' ')
              .trim(),
          language,
        );
      }
    }
  }
  return null;
}

String _price(dynamic value, dynamic currency, String unavailable) {
  if (value == null) return unavailable;
  final unit = currency == 'poke-dollar'
      ? '₽'
      : itemDisplayName(currency as String? ?? 'moneda');
  return '$value $unit';
}

const _attributeNames = {
  'countable': 'Acumulable',
  'consumable': 'Consumible',
  'usable-overworld': 'Uso fuera del combate',
  'usable-in-battle': 'Uso en combate',
  'holdable': 'Se puede equipar',
  'holdable-passive': 'Efecto pasivo al equipar',
  'holdable-active': 'Se activa al equipar',
  'underground': 'Disponible en el subsuelo',
  'underground-usable': 'Uso en el subsuelo',
};

const _flingEffects = {
  'badly-poison': 'Envenena gravemente al objetivo.',
  'burn': 'Quema al objetivo.',
  'berry-effect': 'Aplica al objetivo el efecto de la baya.',
  'herb-effect': 'Aplica al objetivo el efecto de la hierba.',
  'paralyze': 'Paraliza al objetivo.',
  'poison': 'Envenena al objetivo.',
  'flinch': 'Hace retroceder al objetivo.',
};
