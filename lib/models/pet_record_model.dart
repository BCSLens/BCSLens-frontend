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
    String? backViewImagePath,
    String? predictedAnimal,
    double? predictionConfidence,
    String? id,
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
    if (backViewImagePath != null) {
      _instance.backViewImagePath = backViewImagePath;
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
  String? backViewImagePath;

  // View classifications
  Map<String, String> viewClassifications = {};

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
  String? groupId;  // Add groupId for API integration
  
  // Prediction details
  String? predictedAnimal; 
  double? predictionConfidence; 
  int? predictedClassId;

  // Method to reset record (useful when starting a new record)
  void reset() {
    frontViewImagePath = null;
    topViewImagePath = null;
    leftViewImagePath = null;
    rightViewImagePath = null;
    backViewImagePath = null;
    viewClassifications = {};
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
    groupId = null;
  }
}