// lib/models/pet_record_model.dart
class PetRecord {
  // Create a singleton instance
  static final PetRecord _instance = PetRecord._internal();

  // Factory constructor returns the singleton instance
  factory PetRecord({
    String? frontViewImagePath,
    String? topViewImagePath,
    String? leftViewImagePath,
    String? rightViewImagePath,
    String? predictedAnimal,
    double? predictionConfidence,
  }) {
    // Update paths if provided
    if (frontViewImagePath != null) {
      _instance.frontViewImagePath = frontViewImagePath;
    }
    if (topViewImagePath != null) {
      _instance.topViewImagePath = topViewImagePath;
    }
    if (leftViewImagePath != null) {
      _instance.leftViewImagePath = leftViewImagePath;
    }
    if (rightViewImagePath != null) {
      _instance.rightViewImagePath = rightViewImagePath;
    }
    if (predictedAnimal != null) {
      _instance.predictedAnimal = predictedAnimal;
    }
    if (predictionConfidence != null) {
      _instance.predictionConfidence = predictionConfidence;
    }
    return _instance;
  }

  // Private constructor
  PetRecord._internal();

  // Image paths for different views
  String? frontViewImagePath;
  String? topViewImagePath;
  String? leftViewImagePath;
  String? rightViewImagePath;

  // Pet details
  String? name;
  String? age;
  String? breed;
  String? weight;
  int? bcs;
  String? species;
  String? category;
  String? gender;
  bool? isSterilized;
  String? additionalNotes;
  
  // Prediction details
  String? predictedAnimal; // The predicted animal type (dog, cat, etc.)
  double? predictionConfidence; // Confidence score from the API (e.g., 0.813)
  int? predictedClassId; // Optional: store the class_id if needed

  // Method to reset record (useful when starting a new record)
  void reset() {
    frontViewImagePath = null;
    topViewImagePath = null;
    leftViewImagePath = null;
    rightViewImagePath = null;
    name = null;
    age = null;
    breed = null;
    weight = null;
    bcs = null;
    species = null;
    category = null;
    gender = null;
    isSterilized = null;
    additionalNotes = null;
    predictedAnimal = null;
    predictionConfidence = null;
    predictedClassId = null;
  }
}