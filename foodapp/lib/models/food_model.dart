class FoodModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final String foodPicture;

  FoodModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.foodPicture,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'foodPicture': foodPicture,
    };
  }

  factory FoodModel.fromMap(Map<String, dynamic> map) {
    return FoodModel(
      id: map['id'] ?? '', // Provide default value if null
      name: map['name'] ?? 'Unknown',
      description: map['description'] ?? 'No description available',
      price: (map['price'] ?? 0).toDouble(), // Convert to double safely
      foodPicture: map['foodPicture'] ?? '', // Prevent null images
    );
  }
}
