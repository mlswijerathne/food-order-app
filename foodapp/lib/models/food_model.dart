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
      id: map['id'],
      name: map['name'],
      description: map['description'],
      price: map['price'].toDouble(),
      foodPicture: map['foodPicture'],
    );
  }
}