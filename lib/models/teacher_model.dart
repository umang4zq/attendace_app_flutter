class TeacherModel {
  final String uid;
  final String email;
  final bool canAddManually;
  final bool canImportCsv;

  TeacherModel({
    required this.uid,
    required this.email,
    this.canAddManually = true,
    this.canImportCsv = false,
  });

  factory TeacherModel.fromMap(Map<String, dynamic> map, String uid) {
    return TeacherModel(
      uid: uid,
      email: (map['email'] ?? '').toString(),
      canAddManually: map['canAddManually'] is bool ? map['canAddManually'] as bool : true,
      canImportCsv: map['canImportCsv'] is bool ? map['canImportCsv'] as bool : false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'canAddManually': canAddManually,
      'canImportCsv': canImportCsv,
    };
  }

  TeacherModel copyWith({
    String? uid,
    String? email,
    bool? canAddManually,
    bool? canImportCsv,
  }) {
    return TeacherModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      canAddManually: canAddManually ?? this.canAddManually,
      canImportCsv: canImportCsv ?? this.canImportCsv,
    );
  }
}
