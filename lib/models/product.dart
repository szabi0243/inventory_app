class Product {
  final int? id;
  final String code;
  final String name;
  final DateTime createdAt;
  final int quantity; // ÚJ MEZŐ: Mennyiség

  Product({
    this.id,
    required this.code,
    required this.name,
    required this.createdAt,
    this.quantity = 1, // Alapértelmezetten 1 darab
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'quantity': quantity, // ÚJ MEZŐ mentése
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      code: map['code'],
      name: map['name'],
      createdAt: DateTime.parse(map['createdAt']),
      quantity: map['quantity'] ?? 1, // ÚJ MEZŐ betöltése
    );
  }
}