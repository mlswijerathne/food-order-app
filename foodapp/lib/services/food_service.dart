import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/food_model.dart';

class FoodService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add a new food item
  Future<String?> addFood(Map<String, dynamic> foodMap) async {
  try {
    // Check for required fields
    debugPrint("Food map before adding: $foodMap");
    
    // Make sure all required fields are present
    if (!foodMap.containsKey('name') || !foodMap.containsKey('description')) {
      debugPrint("Missing required fields in food map");
      return null;
    }
    
    DocumentReference docRef = await _firestore.collection('foods').add(foodMap);
    await docRef.update({'id': docRef.id});
    
    // Verify the document was added correctly
    DocumentSnapshot addedDoc = await docRef.get();
    debugPrint("Added document data: ${addedDoc.data()}");
    
    return docRef.id;
  } catch (e) {
    debugPrint("Error adding food: ${e.toString()}");
    return null;
  }
}

  // Get all food items
  Future<List<FoodModel>> getAllFoods() async {
  try {
    QuerySnapshot snapshot = await _firestore.collection('foods').get();
    
    debugPrint("Fetched ${snapshot.docs.length} food items"); // Debugging
    
    return snapshot.docs.map((doc) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      debugPrint("Food Item: $data"); // Check if data exists
      return FoodModel.fromMap(data);
    }).toList();
  } catch (e) {
    debugPrint("Error getting foods: ${e.toString()}");
    return [];
  }
}


  // Get a specific food item
  Future<FoodModel?> getFoodById(String foodId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('foods').doc(foodId).get();
      if (doc.exists) {
        return FoodModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint("Error getting food: ${e.toString()}");
      return null;
    }
  }

  // Update a food item
  Future<bool> updateFood(FoodModel food) async {
    try {
      await _firestore.collection('foods').doc(food.id).update(food.toMap());
      debugPrint("Food updated successfully: ${food.id}");
      return true;
    } catch (e) {
      debugPrint("Error updating food: ${e.toString()}");
      return false;
    }
  }

  // Delete a food item
  Future<bool> deleteFood(String foodId) async {
    try {
      await _firestore.collection('foods').doc(foodId).delete();
      debugPrint("Food deleted successfully: $foodId");
      return true;
    } catch (e) {
      debugPrint("Error deleting food: ${e.toString()}");
      return false;
    }
  }
}