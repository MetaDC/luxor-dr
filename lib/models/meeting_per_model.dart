import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/methods.dart';

class MeetingPersonModel {
  final String docId;
  final String name;
  final String lowerName;
  final String email;
  final String phone;
  final String countryCode;
  final String phoneNumber;
  final List<String> combinationNames;
  final String createdByRole;
  // final String? doctorId;
  final DateTime createdAt;
  final DateTime updatedAt;

  MeetingPersonModel({
    required this.docId,
    required this.name,
    required this.lowerName,
    required this.email,
    required this.phone,
    required this.createdByRole,
    // this.doctorId,
    required this.createdAt,
    required this.updatedAt,
    this.countryCode = '',
    this.phoneNumber = '',
    this.combinationNames = const [],
  });

  factory MeetingPersonModel.fromJson(Map<String, dynamic> json) {
    final phone = json['phone'] ?? '';
    final (code, rest) = splitStoredPhone(phone);
    return MeetingPersonModel(
      docId: json['docId'] ?? '',
      name: json['name'] ?? '',
      lowerName: json['lowerName'] ?? '',
      email: json['email'] ?? '',
      phone: phone,
      countryCode: json['countryCode'] ?? code,
      phoneNumber: json['phoneNumber'] ?? rest,
      combinationNames: List<String>.from(json['combinationNames'] ?? []),
      createdByRole: json['createdByRole'] ?? '',
      // doctorId: json['doctorId'],
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory MeetingPersonModel.fromSnap(
    QueryDocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final json = snapshot.data();
    final phone = json['phone'] ?? '';
    final (code, rest) = splitStoredPhone(phone);
    return MeetingPersonModel(
      docId: snapshot.id,
      name: json['name'] ?? '',
      lowerName: json['lowerName'] ?? '',
      email: json['email'] ?? '',
      phone: phone,
      countryCode: json['countryCode'] ?? code,
      phoneNumber: json['phoneNumber'] ?? rest,
      combinationNames: List<String>.from(json['combinationNames'] ?? []),
      createdByRole: json['createdByRole'] ?? '',
      // doctorId: json['doctorId'],
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
      'countryCode': countryCode,
      'phoneNumber': phoneNumber,
      'combinationNames': combinationNames,
      'createdByRole': createdByRole,
      //'doctorId': doctorId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

