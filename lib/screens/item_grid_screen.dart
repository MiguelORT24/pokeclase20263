import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pokeclase20263/providers/poke_api_provider.dart';
import 'package:pokeclase20263/screens/item_categories_screen.dart';
import 'package:pokeclase20263/screens/item_detail_screen.dart';

class ItemGridScreen extends StatefulWidget {
  final int categoryId;
  final String categoryName;
  const ItemGridScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<ItemGridScreen> createState() => _ItemGridScreenState();
}

class _ItemGridScreenState extends State<ItemGridScreen> {
  late Future<Map<String, dynamic>> _category;

  @override
  void initState() {
    super.initState();
    _category = context.read<PokeApiProvider>().getItemCategory(
      widget.categoryId,
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.categoryName)),
    body: FutureBuilder(
      future: _category,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return ItemLoadError(
            onRetry: () => setState(() {
              _category = context.read<PokeApiProvider>().getItemCategory(
                widget.categoryId,
              );
            }),
          );
        }
        final items =
            (snapshot.data!['items'] as List)
                .cast<Map<String, dynamic>>()
                .toList()
              ..sort((a, b) => itemResourceId(a).compareTo(itemResourceId(b)));
        if (items.isEmpty) {
          return const Center(child: Text('Esta categoría no tiene ítems.'));
        }
        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 180,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) => _ItemCard(
            key: ValueKey(itemResourceId(items[index])),
            item: items[index],
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ItemDetailScreen(
                  itemId: itemResourceId(items[index]),
                  items: items,
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}

class _ItemCard extends StatefulWidget {
  final Map<String, dynamic> item;
  final VoidCallback onTap;
  const _ItemCard({super.key, required this.item, required this.onTap});

  @override
  State<_ItemCard> createState() => _ItemCardState();
}

class _ItemCardState extends State<_ItemCard> {
  late Future<Map<String, dynamic>> _detail;
  @override
  void initState() {
    super.initState();
    _detail = context.read<PokeApiProvider>().getItemDetail(
      itemResourceId(widget.item),
    );
  }

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    elevation: 4,
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Text(
              '#${itemResourceId(widget.item).toString().padLeft(3, '0')}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            Expanded(
              child: FutureBuilder(
                future: _detail,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return IconButton(
                      tooltip: 'Reintentar imagen',
                      icon: const Icon(Icons.refresh),
                      onPressed: () => setState(() {
                        _detail = context.read<PokeApiProvider>().getItemDetail(
                          itemResourceId(widget.item),
                        );
                      }),
                    );
                  }
                  final sprite =
                      snapshot.data?['sprites']?['default'] as String?;
                  if (sprite == null) {
                    return const Icon(Icons.inventory_2_outlined, size: 36);
                  }
                  return Image.network(
                    sprite,
                    width: 80,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.none,
                    errorBuilder: (_, error, stack) =>
                        const Icon(Icons.inventory_2_outlined, size: 36),
                  );
                },
              ),
            ),
            Text(
              itemDisplayName(widget.item['name'] as String),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
