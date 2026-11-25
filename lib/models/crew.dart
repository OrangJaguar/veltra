class Crew {
  const Crew({
    required this.id,
    required this.name,
    this.siteLabel,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String? siteLabel;
  final DateTime createdAt;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'site_label': siteLabel,
      'created_at': createdAt.toUtc().millisecondsSinceEpoch,
    };
  }

  factory Crew.fromMap(Map<String, dynamic> map) {
    return Crew(
      id: map['id'] as String,
      name: map['name'] as String,
      siteLabel: map['site_label'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['created_at'] as int,
        isUtc: true,
      ),
    );
  }
}
