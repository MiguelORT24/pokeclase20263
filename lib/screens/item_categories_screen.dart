import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pokeclase20263/models/item_category_names.dart';
import 'package:pokeclase20263/providers/poke_api_provider.dart';
import 'package:pokeclase20263/screens/item_grid_screen.dart';

int itemResourceId(Map<String, dynamic> resource) => int.parse(
  Uri.parse(resource['url'] as String).pathSegments
      .where((s) => s.isNotEmpty)
      .last,
);

String itemDisplayName(String name) => name
    .split('-')
    .map(
      (word) => word.isEmpty ? word : word[0].toUpperCase() + word.substring(1),
    )
    .join(' ');

class ItemCategoriesScreen extends StatefulWidget {
  const ItemCategoriesScreen({super.key});

  @override
  State<ItemCategoriesScreen> createState() => _ItemCategoriesScreenState();
}

class _ItemCategoriesScreenState extends State<ItemCategoriesScreen>
    with AutomaticKeepAliveClientMixin {
  late Future<List<Map<String, dynamic>>> _categories;
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _categories = context.read<PokeApiProvider>().getItemCategories();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder(
      future: _categories,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return ItemLoadError(
            onRetry: () => setState(() {
              _categories = context.read<PokeApiProvider>().getItemCategories();
            }),
          );
        }
        final categories = List<Map<String, dynamic>>.of(snapshot.data!)
          ..sort((a, b) => itemResourceId(a).compareTo(itemResourceId(b)));
        if (categories.isEmpty) {
          return const Center(child: Text('No hay categorías disponibles.'));
        }
        return ListView.separated(
          key: const PageStorageKey('item-categories'),
          padding: const EdgeInsets.all(12),
          itemCount: categories.length,
          separatorBuilder: (_, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final category = categories[index];
            final name = itemCategoryNameEs(category['name'] as String);
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              elevation: 2,
              color: const Color(0xFFF5F4FA),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: const Icon(Icons.inventory_2_outlined),
                title: Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ItemGridScreen(
                      categoryId: itemResourceId(category),
                      categoryName: name,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class ItemLoadError extends StatelessWidget {
  final VoidCallback onRetry;
  const ItemLoadError({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'No se pudieron cargar los ítems. Inténtalo de nuevo.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    ),
  );
}
