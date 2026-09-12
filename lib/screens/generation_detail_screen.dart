import 'package:flutter/material.dart';
import 'package:pokeclase20263/models/generation_detail_response.dart';
import 'package:pokeclase20263/providers/poke_api_provider.dart';
import 'package:pokeclase20263/screens/pokemon_detail_screen.dart';

class GenerationDetailScreen extends StatelessWidget {
  final int generationId;

  const GenerationDetailScreen({Key? key, required this.generationId})
    : super(key: key);

  String _spriteUrl(int id) =>
      'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$id.png';

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(title: Text('Generación $generationId')),
      body: FutureBuilder(
        future: PokeApiProvider().getGenerationDetail(generationId),
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
            final speciesList = generationDetailResponse.pokemonSpecies;
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

                //-------------------------------------------------------------------------------------------

                // return _PokemonCard(
                //   id: species.id,
                //   name: species.name,
                //   imageUrl: _spriteUrl(species.id),
                //   colorScheme: (species.types?.isNotEmpty ?? false)
                //       ? colorSchemeForType(species.types!.first)
                //       : colorSchemeForType('normal'),
                //   onTap: () {
                //     Navigator.push(
                //       context,
                //       MaterialPageRoute(
                //         builder: (context) => PokemonDetailScreen(
                //           pokemonId: species.id,
                //           pokemonName: species.name,
                //         ),
                //       ),
                //     );
                //   },
                // );

                return _PokemonCard(
                  id: species.id,
                  name: species.name,
                  imageUrl: _spriteUrl(species.id),
                  colorScheme: colorScheme,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PokemonDetailScreen(pokemonId: species.id, pokemonName: species.name),
                      ),
                    );
                  },
                );

                //-------------------------------------------------------------------------------------------
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
            ],
          ),
        ),
      ),
    );
  }
}













































// ColorScheme colorSchemeForType(String type) {
//   final baseColor = switch (type) {
//     'fire' => const Color(0xFFEE8130),
//     'water' => const Color(0xFF6390F0),
//     'grass' => const Color(0xFF7AC74C),
//     'electric' => const Color(0xFFF7D02C),
//     'psychic' => const Color(0xFFF95587),
//     'ice' => const Color(0xFF96D9D6),
//     'dragon' => const Color(0xFF6F35FC),
//     'dark' => const Color(0xFF705746),
//     'fairy' => const Color(0xFFD685AD),
//     'normal' => const Color(0xFFA8A77A),
//     'fighting' => const Color(0xFFC22E28),
//     'flying' => const Color(0xFFA98FF3),
//     'poison' => const Color(0xFFA33EA1),
//     'ground' => const Color(0xFFE2BF65),
//     'rock' => const Color(0xFFB6A136),
//     'bug' => const Color(0xFFA6B91A),
//     'ghost' => const Color(0xFF735797),
//     'steel' => const Color(0xFFB7B7CE),
//     _ => const Color(0xFF5345AB),
//   };

//   return ColorScheme.fromSeed(
//     seedColor: baseColor,
//     brightness: Brightness.light,
//   );
// }