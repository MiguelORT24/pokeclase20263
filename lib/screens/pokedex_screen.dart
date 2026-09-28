import 'package:flutter/material.dart';
import 'package:pokeclase20263/screens/generation_list_screen.dart';
import 'package:pokeclase20263/screens/item_categories_screen.dart';

class PokedexScreen extends StatelessWidget {
  const PokedexScreen({super.key});

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 2,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Pokédex'),
        bottom: const TabBar(
          labelColor: Colors.white,
          unselectedLabelColor: Color(0xFFCEC9E8),
          indicatorColor: Color(0xFFE5D36D),
          indicatorWeight: 4,
          labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          tabs: [
            Tab(text: 'Generaciones'),
            Tab(text: 'Ítems'),
          ],
        ),
      ),
      body: const TabBarView(
        children: [
          GenerationListScreen(embedded: true),
          ItemCategoriesScreen(),
        ],
      ),
    ),
  );
}
