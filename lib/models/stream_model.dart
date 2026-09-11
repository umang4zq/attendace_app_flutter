class StreamModel {
  final String id;
  final String name;
  final String? year;

  StreamModel({
    required this.id,
    required this.name,
    this.year,
  });

  factory StreamModel.fromDoc(String id, Map<String, dynamic>? data) {
    return StreamModel(
      id: id,
      name: data?['name']?.toString() ?? id,
      year: data?['year']?.toString(),
    );
  }
}
