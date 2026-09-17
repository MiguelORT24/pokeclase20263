import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:pokeclase20263/models/generation_detail_response.dart';
import 'package:pokeclase20263/providers/poke_api_provider.dart';
import 'package:pokeclase20263/screens/pokemon_detail_screen.dart';

class GenerationDetailScreen extends StatefulWidget {
  final int generationId;

  const GenerationDetailScreen({super.key, required this.generationId});

  @override
  State<GenerationDetailScreen> createState() => _GenerationDetailScreenState();
}

class _GenerationDetailScreenState extends State<GenerationDetailScreen> {
  late Future<http.Response> _generation;

  @override
  void initState() {
    super.initState();
    _generation = context.read<PokeApiProvider>().getGenerationDetail(
      widget.generationId,
    );
  }

  @override
  void didUpdateWidget(covariant GenerationDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.generationId != widget.generationId) {
      _generation = context.read<PokeApiProvider>().getGenerationDetail(
        widget.generationId,
      );
    }
  }

  String _spriteUrl(int id) =>
      'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$id.png';

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(title: Text('Generación ${widget.generationId}')),
      body: FutureBuilder(
        future: _generation,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('No data available'));
          } else {
            final generationDetailResponse =
                GenerationDetailResponse.fromRawJson(snapshot.data!.body);
            final speciesList = generationDetailResponse.pokemonSpecies
              ..sort((a, b) => a.id.compareTo(b.id));
            return GridView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: speciesList.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.8,
              ),
              itemBuilder: (context, index) {
                final species = speciesList[index];

                return _PokemonCard(
                  id: species.id,
                  name: species.name,
                  imageUrl: _spriteUrl(species.id),
                  colorScheme: colorScheme,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PokemonDetailScreen(
                          pokemonId: species.id,
                          pokemonName: species.name,
                          pokemonList: speciesList,
                        ),
                      ),
                    );
                  },
                );
              },
            );
          }
        },
      ),
    );
  }
}

class _PokemonCard extends StatelessWidget {
  final int id;
  final String name;
  final String imageUrl;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  const _PokemonCard({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.colorScheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colorScheme.onPrimary,
      borderRadius: BorderRadius.circular(16),
      elevation: 4,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '#${id.toString().padLeft(3, '0')}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                name[0].toUpperCase() + name.substring(1),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Hero(
                  tag: 'pokemon-$id',
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.catching_pokemon,
                      color: colorScheme.secondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
