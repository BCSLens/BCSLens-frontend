class PetRecord {
  // Image paths for different views
  String? frontViewImagePath;
  String? topViewImagePath;
  String? leftViewImagePath;
  String? rightViewImagePath;

  // Pet details
  String? name;
  String? age;
  String? breed; // พันธ์
  String? weight;
  int? bcs; // Body Condition Score

  // Additional optional fields
  String? species;
  String? category;

  PetRecord({
    this.frontViewImagePath,
    this.topViewImagePath,
    this.leftViewImagePath,
    this.rightViewImagePath,
    this.name,
    this.age,
    this.breed,
    this.weight,
    this.bcs,
    this.species,
    this.category,
  });
}