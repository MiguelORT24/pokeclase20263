import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; 

class PokeApiProvider extends ChangeNotifier{
  final String _baseUrl = 'pokeApi.co';
  final String _apiPatch = '/api/v2';

  Future<http.Response> getGenerations() async {
    final url = Uri.https(_baseUrl, "$_apiPatch/generation");
    final response = await http.get(url);
    return response;
  }
}