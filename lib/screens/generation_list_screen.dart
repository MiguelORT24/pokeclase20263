import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pokeclase20263/models/generation_list_response.dart';
import 'package:pokeclase20263/providers/poke_api_provider.dart';
import 'package:pokeclase20263/screens/generation_detail_screen.dart';
import 'package:provider/provider.dart';

class GenerationListScreen extends StatelessWidget {
  const GenerationListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: const Text('Generaciones')),
      ),
      body: FutureBuilder<http.Response>(
        future : Provider.of<PokeApiProvider>(context, listen: false).getGenerations(),
        builder: (context, snapshot){
          if(snapshot.connectionState == ConnectionState.waiting){
            return const Center(child: CircularProgressIndicator(),);
          } else if(snapshot.hasError){
            return Center(child: Text('Error: ${snapshot.error}'),);
          } else if (!snapshot.hasData || snapshot.data!.statusCode != 200) {
            return const Center(child: Text('Failed to load generations'),);
          } else {
            final generationListResponse = GenerationListResponse.fromJson(json.decode(snapshot.data!.body));
            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: generationListResponse.results.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8,),
              itemBuilder: (context, index) {
                final generation = generationListResponse.results[index];
                return Card(
                  margin: EdgeInsets.zero,
                  child: ListTile(
                    title: Text(generation.name),
                    onTap: () {
                      Navigator.push(
                        context, 
                        MaterialPageRoute(
                          builder: (context) => GenerationDetailScreen(generationId: index +1)
                        )
                      );
                    },
                  ),
                );
              },
            );
          }
        },
      )
    );
  }
}