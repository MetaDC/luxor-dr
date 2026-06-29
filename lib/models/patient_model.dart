import 'package:cloud_firestore/cloud_firestore.dart';

class PatientModel {
  final String docId;
  final String name;
  final String lowerName;
  final String email;
  final String phone;
  final String createdByRole;
  //final String doctorId;
  final DateTime createdAt;
  final DateTime updatedAt;

  PatientModel({
    required this.docId,
    required this.name,
    required this.lowerName,
    required this.email,
    required this.phone,
    required this.createdByRole,
    // required this.doctorId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PatientModel.fromJson(Map<String, dynamic> json) {
    return PatientModel(
      docId: json['docId'] ?? '',
      name: json['name'] ?? '',
      lowerName: json['lowerName'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      createdByRole: json['createdByRole'] ?? '',
      // doctorId: json['doctorId'] ?? '',
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory PatientModel.fromQueryDocumentSnapshot(
    QueryDocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final json = snapshot.data();
    return PatientModel(
      docId: snapshot.id,
      name: json['name'] ?? '',
      lowerName: json['lowerName'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      createdByRole: json['createdByRole'] ?? '',
      // doctorId: json['doctorId'] ?? '',
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'docId': docId,
      'name': name,
      'lowerName': lowerName,
      'email': email,
      'phone': phone,
      'createdByRole': createdByRole,
      // 'doctorId': doctorId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
