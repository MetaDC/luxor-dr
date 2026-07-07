import 'package:cloud_firestore/cloud_firestore.dart';

class AppointmentMeetingModel {
  final String docId;

  final String doctorId;
  final String doctorName;
  final String specialization;

  /// "appointment" or "meeting"
  final String docType;

  /// consultation, follow_up, checkup, procedure, emergency, other / business, review, etc.
  final String type;

  final String personId;
  final String personName;
  final String personPhone;
  final String personEmail;

  final DateTime startTime;
  final DateTime endTime;

  /// Scheduled / Completed / Cancelled
  final String status;

  final DateTime createdAt;
  final String createdById;
  final String createdByName;

  final String? cancelledBy;
  final String? cancellationReason;
  final DateTime? cancelledAt;

  final String? shortDescription;
  final String? description;

  final String? completedBy;
  final String? summary;
  final DateTime? completedAt;

  final bool showOnReception;

  AppointmentMeetingModel({
    required this.docId,
    required this.doctorId,
    required this.doctorName,
    required this.specialization,
    required this.docType,
    required this.type,
    required this.personId,
    required this.personName,
    required this.personPhone,
    required this.personEmail,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.createdAt,
    required this.createdById,
    required this.createdByName,
    this.cancelledBy,
    this.cancellationReason,
    this.cancelledAt,
    this.shortDescription,
    this.description,
    this.completedBy,
    this.summary,
    this.completedAt,
    required this.showOnReception,
  });

  factory AppointmentMeetingModel.fromJson(Map<String, dynamic> json) {
    return AppointmentMeetingModel(
      docId: json['docId'] ?? '',
      doctorId: json['doctorId'] ?? '',
      doctorName: json['doctorName'] ?? '',
      specialization: json['specialization'] ?? '',
      docType: json['docType'] ?? '',
      type: json['type'] ?? '',
      personId: json['personId'] ?? '',
      personName: json['personName'] ?? '',
      personPhone: json['personPhone'] ?? '',
      personEmail: json['personEmail'] ?? '',
      startTime: (json['startTime'] as Timestamp).toDate(),
      endTime: (json['endTime'] as Timestamp).toDate(),
      status: json['status'] ?? '',
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      createdById: json['createdById'] ?? '',
      createdByName: json['createdByName'] ?? '',
      cancelledBy: json['cancelledBy'],
      cancellationReason: json['cancellationReason'],
      cancelledAt: (json['cancelledAt'] as Timestamp?)?.toDate(),
      shortDescription: json['shortDescription'],
      description: json['description'],
      completedBy: json['completedBy'],
      summary: json['summary'],
      completedAt: (json['completedAt'] as Timestamp?)?.toDate(),
      showOnReception: json['showOnReception'] ?? true,
    );
  }

  factory AppointmentMeetingModel.fromQueryDocumentSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final json = snapshot.data() ?? {};
    return AppointmentMeetingModel(
      docId: snapshot.id,
      doctorId: json['doctorId'] ?? '',
      doctorName: json['doctorName'] ?? '',
      specialization: json['specialization'] ?? '',
      docType: json['docType'] ?? '',
      type: json['type'] ?? '',
      personId: json['personId'] ?? '',
      personName: json['personName'] ?? '',
      personPhone: json['personPhone'] ?? '',
      personEmail: json['personEmail'] ?? '',
      startTime: (json['startTime'] as Timestamp).toDate(),
      endTime: (json['endTime'] as Timestamp).toDate(),
      status: json['status'] ?? '',
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      createdById: json['createdById'] ?? '',
      createdByName: json['createdByName'] ?? '',
      cancelledBy: json['cancelledBy'],
      cancellationReason: json['cancellationReason'],
      cancelledAt: (json['cancelledAt'] as Timestamp?)?.toDate(),
      shortDescription: json['shortDescription'],
      description: json['description'],
      completedBy: json['completedBy'],
      summary: json['summary'],
      completedAt: (json['completedAt'] as Timestamp?)?.toDate(),
      showOnReception: json['showOnReception'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'doctorId': doctorId,
      'doctorName': doctorName,
      'specialization': specialization,
      'docType': docType,
      'type': type,
      'personId': personId,
      'personName': personName,
      'personPhone': personPhone,
      'personEmail': personEmail,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdById': createdById,
      'createdByName': createdByName,
      'cancelledBy': cancelledBy,
      'cancellationReason': cancellationReason,
      'cancelledAt':
          cancelledAt != null ? Timestamp.fromDate(cancelledAt!) : null,
      'shortDescription': shortDescription,
      'description': description,
      'completedBy': completedBy,
      'summary': summary,
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'showOnReception': showOnReception,
    };
  }
}
