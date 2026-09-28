import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pokeclase20263/models/generation_list_response.dart';
import 'package:pokeclase20263/providers/poke_api_provider.dart';
import 'package:pokeclase20263/screens/generation_detail_screen.dart';
import 'package:provider/provider.dart';

class GenerationListScreen extends StatefulWidget {
  final bool embedded;
  const GenerationListScreen({super.key, this.embedded = false});

  @override
  State<GenerationListScreen> createState() => _GenerationListScreenState();
}

class _GenerationListScreenState extends State<GenerationListScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  late final Future<http.Response> _generations;

  @override
  void initState() {
    super.initState();
    _generations = context.read<PokeApiProvider>().getGenerations();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: widget.embedded
          ? null
          : AppBar(title: const Text('Generaciones')),
      body: FutureBuilder<http.Response>(
        future: _generations,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.statusCode != 200) {
            return const Center(child: Text('Failed to load generations'));
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

                //-------------------------------------------------------------------------------------------------------------------
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

                // return
                // Card(
                //   margin: EdgeInsets.zero,
                //   child: ListTile(
                //     title: Text(generation.name),
                //     onTap: () {
                //       Navigator.push(
                //         context,
                //         MaterialPageRoute(
                //           builder: (context) => GenerationDetailScreen(generationId: index +1)
                //         )
                //       );
                //     },
                //   ),
                // );

                //-------------------------------------------------------------------------------------------------------------------
              },
            );
          }
        },
      ),
    );
  }
}
