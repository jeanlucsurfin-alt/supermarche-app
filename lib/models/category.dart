class Category {
  final int? id;
  final String name;
  final String iconKey;
  final int colorValue;

  Category({
    this.id,
    required this.name,
    required this.iconKey,
    required this.colorValue,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'iconKey': iconKey,
      'colorValue': colorValue,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      name: map['name'],
      iconKey: map['iconKey'],
      colorValue: map['colorValue'],
    );
  }
}
