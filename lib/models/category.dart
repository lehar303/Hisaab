class Category {
  final int? id;
  final String name;
  final String parent;

  const Category({
    this.id,
    required this.name,
    required this.parent,
  });

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as int?,
      name: map['name'] as String,
      parent: map['parent'] as String,
    );
  }
}