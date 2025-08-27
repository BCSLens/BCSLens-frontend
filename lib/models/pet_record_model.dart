class PetRecord {
  // Existing pet information (for adding records to existing pets)
  String? existingPetId;
  bool isNewRecordForExistingPet = false;

  // Image paths
  String? frontViewImagePath;
  String? topViewImagePath;
  String? leftViewImagePath;
  String? rightViewImagePath;
  String? backViewImagePath;

  // Pet basic information
  String? name;
  String? breed;
  String? age;
  String? weight;
  String? gender;
  bool? isSterilized;
  String? category; // 'Dogs' or 'Cats'
  String? groupId;

  // BCS evaluation
  int? bcs;
  String? additionalNotes;

  // AI predictions
  String? predictedAnimal;
  double? predictionConfidence;

  // Constructor
  PetRecord({
    this.existingPetId,
    this.isNewRecordForExistingPet = false,
    this.frontViewImagePath,
    this.topViewImagePath,
    this.leftViewImagePath,
    this.rightViewImagePath,
    this.backViewImagePath,
    this.name,
    this.breed,
    this.age,
    this.weight,
    this.gender,
    this.isSterilized,
    this.category,
    this.groupId,
    this.bcs,
    this.additionalNotes,
    this.predictedAnimal,
    this.predictionConfidence,
  });

  // Reset method for clearing data
  void reset() {
    existingPetId = null;
    isNewRecordForExistingPet = false;
    frontViewImagePath = null;
    topViewImagePath = null;
    leftViewImagePath = null;
    rightViewImagePath = null;
    backViewImagePath = null;
    name = null;
    breed = null;
    age = null;
    weight = null;
    gender = null;
    isSterilized = null;
    category = null;
    groupId = null;
    bcs = null;
    additionalNotes = null;
    predictedAnimal = null;
    predictionConfidence = null;
  }

  // Convert to JSON for API calls
  Map<String, dynamic> toJson() {
    return {
      'existingPetId': existingPetId,
      'isNewRecordForExistingPet': isNewRecordForExistingPet,
      'frontViewImagePath': frontViewImagePath,
      'topViewImagePath': topViewImagePath,
      'leftViewImagePath': leftViewImagePath,
      'rightViewImagePath': rightViewImagePath,
      'backViewImagePath': backViewImagePath,
      'name': name,
      'breed': breed,
      'age': age,
      'weight': weight,
      'gender': gender,
      'isSterilized': isSterilized,
      'category': category,
      'groupId': groupId,
      'bcs': bcs,
      'additionalNotes': additionalNotes,
      'predictedAnimal': predictedAnimal,
      'predictionConfidence': predictionConfidence,
    };
  }

  // Create from JSON
  factory PetRecord.fromJson(Map<String, dynamic> json) {
    return PetRecord(
      existingPetId: json['existingPetId'],
      isNewRecordForExistingPet: json['isNewRecordForExistingPet'] ?? false,
      frontViewImagePath: json['frontViewImagePath'],
      topViewImagePath: json['topViewImagePath'],
      leftViewImagePath: json['leftViewImagePath'],
      rightViewImagePath: json['rightViewImagePath'],
      backViewImagePath: json['backViewImagePath'],
      name: json['name'],
      breed: json['breed'],
      age: json['age'],
      weight: json['weight'],
      gender: json['gender'],
      isSterilized: json['isSterilized'],
      category: json['category'],
      groupId: json['groupId'],
      bcs: json['bcs'],
      additionalNotes: json['additionalNotes'],
      predictedAnimal: json['predictedAnimal'],
      predictionConfidence: json['predictionConfidence']?.toDouble(),
    );
  }

  @override
  String toString() {
    return 'PetRecord{existingPetId: $existingPetId, isNewRecordForExistingPet: $isNewRecordForExistingPet, name: $name, bcs: $bcs}';
  }
}