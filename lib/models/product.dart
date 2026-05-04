class Product {
  final int? id;
  final String code;
  final String name;
  final DateTime createdAt;

  Product({
    this.id,
    required this.code,
    required this.name,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      code: map['code'],
      name: map['name'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}