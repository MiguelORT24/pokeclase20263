import 'dart:convert';

class GenerationListResponse{
  final int count; 
  final String? next;
  final String? previous;
  final List<GenerationItem> results; 

  GenerationListResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results
  });

  //Metodo para recibir directamente el response.body (String)
  factory GenerationListResponse.fromRawJson(String str) =>
  GenerationListResponse.fromJson(json.decode(str));

  //metodo para recibir el Map ya decodificado
  factory GenerationListResponse.fromJson(Map<String, dynamic>json){
    var list = json['results'] as List? ?? []; 
    List<GenerationItem> resultList = list
    .map((i) => GenerationItem.fromJson(i))
    .toList();

    return GenerationListResponse(
      count: json['count'] ?? 0,
      next: json['next'], 
      previous: json['previous'], 
      results: resultList
      );
  }
}

class GenerationItem {
  final String name;
  final String url;

  GenerationItem({
    required this.name,
    required this.url,
  });

  factory GenerationItem.fromRawJson(String str) => GenerationItem.fromJson(json.decode(str));
  
  factory GenerationItem.fromJson(Map<String, dynamic>json){
    return GenerationItem(
      name: json['name'] ?? '',
      url: json['url'] ?? '',
    );

  }
  Map<String, dynamic> toJson() => {
    "name": name,
    "url": url,
  };

  //Extraer el ID de la generación directamente desde la URL
  int get id {
    final uri = Uri.parse(url);
    final segments =  uri.pathSegments.where((s) => s
      .isNotEmpty).toList(); 
    return int.parse(segments.last);
  }

}