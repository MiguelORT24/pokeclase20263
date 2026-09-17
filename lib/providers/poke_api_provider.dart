import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PokeApiProvider extends ChangeNotifier {
  final Map<int, http.Response> _evolutionChains = {};

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
