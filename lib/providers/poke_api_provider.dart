import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PokeApiProvider extends ChangeNotifier {
  final Map<int, http.Response> _evolutionChains = {};
  final Map<Uri, Map<String, dynamic>> _itemsCache = {};

  Future<Map<String, dynamic>> _getItemResource(Uri url) async {
    final cached = _itemsCache[url];
    if (cached != null) return cached;
    final response = await http.get(url).timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw Exception(
        'No se pudieron cargar los ítems (${response.statusCode}).',
      );
    }
    final data =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    _itemsCache[url] = data;
    return data;
  }

  Future<List<Map<String, dynamic>>> getItemCategories() async {
    Uri? url = Uri.https(_baseUrl, '$_apiPatch/item-category', {
      'limit': '100',
    });
    final categories = <Map<String, dynamic>>[];
    while (url != null) {
      final data = await _getItemResource(url);
      categories.addAll((data['results'] as List).cast<Map<String, dynamic>>());
      url = data['next'] == null ? null : Uri.parse(data['next'] as String);
    }
    return categories;
  }

  Future<Map<String, dynamic>> getItemCategory(int id) =>
      _getItemResource(Uri.https(_baseUrl, '$_apiPatch/item-category/$id'));

  Future<Map<String, dynamic>> getItemDetail(int id) =>
      _getItemResource(Uri.https(_baseUrl, '$_apiPatch/item/$id'));

  final String _baseUrl = 'pokeapi.co';
  final String _apiPatch = '/api/v2';

  Future<http.Response> getGenerations() async {
    final url = Uri.https(_baseUrl, "$_apiPatch/generation");
    final response = await http.get(url);
    return response;
  }

  Future<http.Response> getGenerationDetail(int id) async {
    final url = Uri.https(_baseUrl, '$_apiPatch/generation/$id');
    final response = await http.get(url);
    return response;
  }

  // Nuevo: trae detalle del Pokémon, incluyendo 'types'
  Future<http.Response> getPokemonDetail(int id) async {
    final url = Uri.https(_baseUrl, '$_apiPatch/pokemon/$id');
    final response = await http.get(url);
    return response;
  }

  //
  Future<http.Response> getPokemonSpecies(int id) async {
    final url = Uri.https(_baseUrl, '$_apiPatch/pokemon-species/$id');
    final response = await http.get(url);
    return response;
  }

  Future<http.Response> getEvolutionChain(int id) async {
    final cached = _evolutionChains[id];
    if (cached != null) return cached;
    final response = await http
        .get(Uri.https(_baseUrl, '$_apiPatch/evolution-chain/$id'))
        .timeout(const Duration(seconds: 20));
    if (response.statusCode == 200) _evolutionChains[id] = response;
    return response;
  }
}
