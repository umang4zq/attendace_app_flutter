class StudentModel {
  String docId;
  String name;
  String rollno;
  String stream;
  String streamId;
  bool isPresent;
  bool isAbsent;
  bool selected; // Used for holiday selection
  double attendancePercentage;

  StudentModel({
    this.docId = '',
    this.name = '',
    this.rollno = '',
    this.stream = '',
    this.streamId = '',
    this.isPresent = false,
    this.isAbsent = false,
    this.selected = false,
    this.attendancePercentage = 0.0,
  });

  factory StudentModel.fromMap(Map<String, dynamic> map, String docId, {String streamId = ''}) {
    return StudentModel(
      docId: docId,
      name: (map['name'] ?? '').toString().trim(),
      rollno: (map['rollno'] ?? '').toString().trim(),
      stream: (map['stream'] ?? streamId).toString().trim(),
      streamId: streamId.isNotEmpty ? streamId : (map['stream'] ?? '').toString().trim(),
      isPresent: map['isPresent'] is bool ? map['isPresent'] as bool : false,
      isAbsent: map['isAbsent'] is bool ? map['isAbsent'] as bool : false,
      selected: map['selected'] is bool ? map['selected'] as bool : false,
      attendancePercentage: (map['attendancePercentage'] is num)
          ? (map['attendancePercentage'] as num).toDouble()
          : 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name.trim(),
      'rollno': rollno.trim(),
      'stream': stream.trim(),
      'isPresent': isPresent,
      'isAbsent': isAbsent,
    };
  }

  StudentModel copyWith({
    String? docId,
    String? name,
    String? rollno,
    String? stream,
    String? streamId,
    bool? isPresent,
    bool? isAbsent,
    bool? selected,
    double? attendancePercentage,
  }) {
    return StudentModel(
      docId: docId ?? this.docId,
      name: name ?? this.name,
      rollno: rollno ?? this.rollno,
      stream: stream ?? this.stream,
      streamId: streamId ?? this.streamId,
      isPresent: isPresent ?? this.isPresent,
      isAbsent: isAbsent ?? this.isAbsent,
      selected: selected ?? this.selected,
      attendancePercentage: attendancePercentage ?? this.attendancePercentage,
    );
  }
}
