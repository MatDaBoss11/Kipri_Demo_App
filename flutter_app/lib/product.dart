class Product {
  final int id;
  final String name;
  final double price;
  final String storeName;
  final String? category;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.storeName,
    this.category,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      storeName: json['store_name'] as String,
      category: json['category'] as String?,
    );
  }
}