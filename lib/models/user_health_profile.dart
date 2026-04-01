class UserHealthProfile {
  final String gender;
  final double? heightCm;
  final double? weightKg;
  final List<String> healthConditions;

  const UserHealthProfile({
    this.gender = '',
    this.heightCm,
    this.weightKg,
    this.healthConditions = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'gender': gender,
      'heightCm': heightCm,
      'weightKg': weightKg,
      'healthConditions': healthConditions,
    };
  }

  bool get isEmpty {
    return gender.trim().isEmpty &&
        heightCm == null &&
        weightKg == null &&
        healthConditions.isEmpty;
  }
}
