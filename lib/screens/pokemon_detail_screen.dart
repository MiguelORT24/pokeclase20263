import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:pokeclase20263/providers/poke_api_provider.dart';
import 'package:pokeclase20263/screens/pokemon_type_theme.dart';

class PokemonDetailScreen extends StatefulWidget {
  final int pokemonId;
  final String pokemonName;
  const PokemonDetailScreen({
    super.key,
    required this.pokemonId,
    required this.pokemonName,
  });

  @override
  State<PokemonDetailScreen> createState() => _PokemonDetailScreenState();
}

class _PokemonDetailScreenState extends State<PokemonDetailScreen> {
  late Future<(Map<String, dynamic>, Map<String, dynamic>)> _details;

  @override
  void initState() {
    super.initState();
    _details = _load();
  }

  @override
  void didUpdateWidget(covariant PokemonDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pokemonId != widget.pokemonId) _details = _load();
  }

  Future<Map<String, dynamic>> _decode(Future<http.Response> request) async {
    final response = await request.timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw Exception('Error ${response.statusCode}');
    }
    return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  }

  Future<(Map<String, dynamic>, Map<String, dynamic>)> _load() async {
    final api = context.read<PokeApiProvider>();
    final species = await _decode(api.getPokemonSpecies(widget.pokemonId));
    var id = widget.pokemonId;
    // A species and its default variety may have different IDs.
    for (final variety in species['varieties'] as List? ?? []) {
      if (variety['is_default'] == true) {
        id = int.parse(
          Uri.parse(variety['pokemon']['url'] as String).pathSegments
              .where((part) => part.isNotEmpty)
              .last,
        );
        break;
      }
    }
    return (await _decode(api.getPokemonDetail(id)), species);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: _details,
    builder: (context, snapshot) {
      final pokemon = snapshot.data?.$1;
      final types = (pokemon?['types'] as List? ?? [])
          .map((item) => item['type']['name'] as String)
          .toList();
      final colors = colorSchemeForType(types.firstOrNull ?? 'normal');
      return Theme(
        data: Theme.of(context).copyWith(colorScheme: colors),
        child: Scaffold(
          backgroundColor: colors.surface,
          appBar: AppBar(
            title: Text(_name(widget.pokemonName)),
            backgroundColor: colors.primary,
            foregroundColor: colors.onPrimary,
          ),
          body: snapshot.connectionState != ConnectionState.done
              ? const Center(child: CircularProgressIndicator())
              : snapshot.hasError || pokemon == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.wifi_off_rounded, size: 48),
                        const SizedBox(height: 16),
                        const Text(
                          'No se pudieron cargar los detalles. Inténtalo de nuevo.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: () {
                            setState(() {
                              _details = _load();
                            });
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                )
              : _content(pokemon, snapshot.data!.$2, types, colors),
        ),
      );
    },
  );

  Widget _content(
    Map<String, dynamic> pokemon,
    Map<String, dynamic> species,
    List<String> types,
    ColorScheme colors,
  ) {
    final sprites = pokemon['sprites'];
    final image =
        sprites?['other']?['official-artwork']?['front_default'] ??
        sprites?['front_default'];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 650),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _section(colors, [
                Text(
                  '#${widget.pokemonId.toString().padLeft(3, '0')}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(
                  height: 220,
                  child: image == null
                      ? Icon(
                          Icons.catching_pokemon,
                          size: 100,
                          color: colors.primary,
                        )
                      : Image.network(
                          image as String,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, progress) =>
                              progress == null
                              ? child
                              : const Center(
                                  child: CircularProgressIndicator(),
                                ),
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.catching_pokemon,
                            size: 100,
                            color: colors.primary,
                          ),
                        ),
                ),
                Text(
                  _name(widget.pokemonName),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  children: [
                    for (final type in types)
                      Chip(
                        label: Text(_typeNames[type] ?? _name(type)),
                        backgroundColor: colorSchemeForType(type)
                            .primaryContainer,
                        labelStyle: TextStyle(
                          color: colorSchemeForType(type).onPrimaryContainer,
                        ),
                        side: BorderSide.none,
                      ),
                  ],
                ),
              ]),
              _section(colors, [
                _heading('Acerca de'),
                Text(_description(species)),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 32,
                  runSpacing: 12,
                  children: [
                    Text(
                      'Altura: ${((pokemon['height'] as num) / 10).toStringAsFixed(1)} m',
                    ),
                    Text(
                      'Peso: ${((pokemon['weight'] as num) / 10).toStringAsFixed(1)} kg',
                    ),
                  ],
                ),
              ]),
              _section(colors, [
                _heading('Habilidades'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final ability in pokemon['abilities'] as List)
                      Chip(
                        label: Text(
                          '${_name(ability['ability']['name'] as String)}'
                          '${ability['is_hidden'] == true ? ' (oculta)' : ''}',
                        ),
                      ),
                  ],
                ),
              ]),
              _section(colors, [
                _heading('Estadísticas base'),
                for (final stat in pokemon['stats'] as List)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _statNames[stat['stat']['name']] ??
                                    _name(stat['stat']['name'] as String),
                              ),
                            ),
                            Text(
                              '${stat['base_stat']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        LinearProgressIndicator(
                          value: ((stat['base_stat'] as num) / 255).clamp(
                            0.0,
                            1.0,
                          ),
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(8),
                          color: colors.primary,
                          backgroundColor: colors.primaryContainer,
                        ),
                      ],
                    ),
                  ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _heading(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    ),
  );

  Widget _section(ColorScheme colors, List<Widget> children) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    elevation: 2,
    color: colors.surfaceContainerLowest,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    ),
  );

  String _description(Map<String, dynamic> species) {
    final entries = species['flavor_text_entries'] as List? ?? [];
    for (final language in ['es', 'en']) {
      for (final entry in entries) {
        if (entry['language']['name'] == language) {
          return (entry['flavor_text'] as String)
              .replaceAll(RegExp(r'\s+'), ' ')
              .trim();
        }
      }
    }
    return 'No hay descripción disponible.';
  }
}

String _name(String name) => name
    .split('-')
    .map(
      (word) => word.isEmpty ? word : word[0].toUpperCase() + word.substring(1),
    )
    .join(' ');

const _statNames = {
  'hp': 'PS',
  'attack': 'Ataque',
  'defense': 'Defensa',
  'special-attack': 'Ataque especial',
  'special-defense': 'Defensa especial',
  'speed': 'Velocidad',
};

const _typeNames = {
  'fire': 'Fuego',
  'water': 'Agua',
  'grass': 'Planta',
  'electric': 'Eléctrico',
  'psychic': 'Psíquico',
  'ice': 'Hielo',
  'dragon': 'Dragón',
  'dark': 'Siniestro',
  'fairy': 'Hada',
  'normal': 'Normal',
  'fighting': 'Lucha',
  'flying': 'Volador',
  'poison': 'Veneno',
  'ground': 'Tierra',
  'rock': 'Roca',
  'bug': 'Bicho',
  'ghost': 'Fantasma',
  'steel': 'Acero',
};
