import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pokeclase20263/providers/poke_api_provider.dart';

/// Loads the chain only when expanded, independently of the main details.
class PokemonEvolutionPanel extends StatefulWidget {
  final String? chainUrl;
  final int selectedId;

  const PokemonEvolutionPanel({
    super.key,
    required this.chainUrl,
    required this.selectedId,
  });

  @override
  State<PokemonEvolutionPanel> createState() => _PokemonEvolutionPanelState();
}

class _PokemonEvolutionPanelState extends State<PokemonEvolutionPanel> {
  bool _expanded = false;
  Future<List<List<_EvolutionSpecies>>>? _chain;

  Future<List<List<_EvolutionSpecies>>> _load() async {
    final url = widget.chainUrl;
    if (url == null) return [];
    final id = int.parse(
      Uri.parse(url).pathSegments.where((s) => s.isNotEmpty).last,
    );
    final response = await context
        .read<PokeApiProvider>()
        .getEvolutionChain(id)
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw Exception('Error ${response.statusCode}');
    }
    final json =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    return _paths(json['chain'] as Map<String, dynamic>);
  }

  List<List<_EvolutionSpecies>> _paths(Map<String, dynamic> node) {
    final species = node['species'] as Map<String, dynamic>;
    final current = _EvolutionSpecies(
      int.parse(
        Uri.parse(species['url'] as String).pathSegments
            .where((s) => s.isNotEmpty)
            .last,
      ),
      species['name'] as String,
    );
    final children = node['evolves_to'] as List? ?? [];
    if (children.isEmpty) {
      return [
        [current],
      ];
    }
    return [
      for (final child in children)
        for (final path in _paths(child as Map<String, dynamic>))
          [current, ...path],
    ];
  }

  @override
  void didUpdateWidget(covariant PokemonEvolutionPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chainUrl != widget.chainUrl) {
      _chain = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            expanded: _expanded,
            child: TextButton(
              onPressed: () => setState(() {
                _expanded = !_expanded;
              }),
              child: Column(
                children: [
                  const Icon(Icons.more_horiz, size: 30),
                  Text(_expanded ? 'Ocultar evoluciones' : 'Ver evoluciones'),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: !_expanded
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    child: FutureBuilder<List<List<_EvolutionSpecies>>>(
                      future: _chain ??= _load(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState != ConnectionState.done) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        if (snapshot.hasError) {
                          return Column(
                            children: [
                              const Text(
                                'No se pudieron cargar las evoluciones.',
                                textAlign: TextAlign.center,
                              ),
                              TextButton.icon(
                                onPressed: () => setState(() => _chain = null),
                                icon: const Icon(Icons.refresh),
                                label: const Text('Reintentar evoluciones'),
                              ),
                            ],
                          );
                        }
                        final paths = snapshot.data ?? [];
                        if (paths.isEmpty) {
                          return const Text(
                            'No hay informaci?n de evoluciones disponible.',
                            textAlign: TextAlign.center,
                          );
                        }
                        if ((paths.length == 1 && paths.single.length == 1)) {
                          return const Text(
                            '¡Este Pokémon es único! No tiene evoluciones.',
                            textAlign: TextAlign.center,
                          );
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Cadena de evolución',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            for (var i = 0; i < paths.length; i++) ...[
                              if (paths.length > 1)
                                Padding(
                                  padding: const EdgeInsets.only(top: 16),
                                  child: Text(
                                    'Ruta ${i + 1}',
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              for (
                                var stage = 0;
                                stage < paths[i].length;
                                stage++
                              ) ...[
                                if (stage > 0)
                                  Icon(
                                    Icons.arrow_downward_rounded,
                                    color: colors.primary,
                                  ),
                                _speciesTile(paths[i][stage], stage, colors),
                              ],
                            ],
                          ],
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _speciesTile(
    _EvolutionSpecies species,
    int stage,
    ColorScheme colors,
  ) {
    final selected = species.id == widget.selectedId;
    final name = species.name
        .split('-')
        .map((s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1))
        .join(' ');
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: selected ? colors.primaryContainer : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: selected ? Border.all(color: colors.primary) : null,
      ),
      child: Row(
        children: [
          Image.network(
            'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/${species.id}.png',
            width: 64,
            height: 64,
            fit: BoxFit.contain,
            excludeFromSemantics: true,
            errorBuilder: (_, error, stackTrace) => const SizedBox(
              width: 64,
              height: 64,
              child: Icon(Icons.catching_pokemon),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(stage == 0 ? 'Etapa 1 · Base' : 'Etapa ${stage + 1}'),
                if (selected) const Text('Pokémon actual'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EvolutionSpecies {
  final int id;
  final String name;
  const _EvolutionSpecies(this.id, this.name);
}
