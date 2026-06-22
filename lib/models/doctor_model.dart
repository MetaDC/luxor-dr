import 'package:cloud_firestore/cloud_firestore.dart';

class DoctorModel {
  final String docId;
  final String name;
  final String lowerName;
  final String specialization;
  final String email;
  final String phone;
  final List<String> manageByIds;
  final String token;
  final DateTime createdAt;
  final DateTime updatedAt;

  DoctorModel({
    required this.docId,
    required this.name,
    required this.lowerName,
    required this.specialization,
    required this.email,
    required this.phone,
    required this.manageByIds,
    required this.token,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DoctorModel.fromJson(Map<String, dynamic> json) {
    return DoctorModel(
      docId: json['docId'] ?? '',
      name: json['name'] ?? '',
      lowerName: json['lowerName'] ?? '',
      specialization: json['specialization'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      manageByIds: List<String>.from(json['manageByIds'] ?? []),
      token: json['token'] ?? '',
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory DoctorModel.fromDocSnap(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final json = snapshot.data() ?? {};
    return DoctorModel(
      docId: snapshot.id,
      name: json['name'] ?? '',
      lowerName: json['lowerName'] ?? '',
      specialization: json['specialization'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      manageByIds: List<String>.from(json['manageByIds'] ?? []),
      token: json['token'] ?? '',
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory DoctorModel.fromSnap(
    QueryDocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final json = snapshot.data();
    return DoctorModel(
      docId: snapshot.id,
      name: json['name'] ?? '',
      lowerName: json['lowerName'] ?? '',
      specialization: json['specialization'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      manageByIds: List<String>.from(json['manageByIds'] ?? []),
      token: json['token'] ?? '',
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : 'DR';
  }
}
