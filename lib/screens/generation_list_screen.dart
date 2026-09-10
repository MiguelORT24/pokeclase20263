import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pokeclase20263/models/generation_list_response.dart';
import 'package:pokeclase20263/providers/poke_api_provider.dart';
import 'package:pokeclase20263/screens/generation_detail_screen.dart';
import 'package:provider/provider.dart';

// class GenerationListScreen extends StatelessWidget {
//   const GenerationListScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Center(child: const Text('Generaciones')
//         ) ,
//       ),
//       body: FutureBuilder<http.Response>(
//         future: Provider.of<PokeApiProvider>(context, listen: false),getGenerations(),
//         builder: (context, snapshot){
//           if(snapshot.connectionState = ConnectionState.waiting){
//             return const Center(child: CircularProgressIndicator());

//           }else if (snapshot.hasError){
//             return Center(child: Text('Error: &{snashot.error}'));

//           }else if (!snapshot.hasData || snapshot.data!.statusCode != 200){
//             return const Center(child: Text('Failed to load generations'),);
//           }else{
//             final generationListResponse = Generation_list_response.fromJson(json.decode(snapshot.data!));
//             return ListView.separated(
//               padding: const EdgeInserts.all(12),
//               itemCount: generationListResponse.results.lenght,
//               separatorBuilder: (context, index){
//                 final generation = generationListResponse.
//               },
//             );
//           }
//         }
//       )

//     );
//   }
// }

class GenerationListScreen extends StatelessWidget {
  const GenerationListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Center(child: const Text('Generaciones'))),
      body: FutureBuilder<http.Response>(
        future: Provider.of<PokeApiProvider>(
          context,
          listen: false,
        ).getGenerations(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData && snapshot.data!.statusCode != 200) {
            return const Center(child: Text('Failed to load generations}'));
          } else {
            final generationListResponse = GenerationListResponse.fromJson(
              json.decode(snapshot.data!.body),
            );
            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: generationListResponse.results.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final generation = generationListResponse.results[index];
                // return Card(
                //   margin: EdgeInsets.zero,
                //   child: ListTile(
                //     title: Text(generation.name),
                //     onTap: () {
                //       Navigator.push(
                //         context,
                //         MaterialPageRoute(
                //           builder: (context) => GenerationDetailScreen(generationId: index+1)
                //         ));
                //     }
                //     ),
                // );
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  elevation: 2,
                  color: Color(0xFFF5F4FA),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              GenerationDetailScreen(generationId: index + 1),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.catching_pokemon, // ícono de la tarjetona -----
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              generation.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 16,
                            color: Colors.grey.shade400,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
                //-------------------------------------------------------------------------------------------------------
              },
            );
          }
        },
      ),
    );
  }
}
