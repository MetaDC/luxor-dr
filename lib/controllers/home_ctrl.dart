import 'dart:async';
import 'dart:io' as io;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../models/app_meet_model.dart';
import '../models/meeting_per_model.dart';
import '../models/patient_model.dart';
import '../utils/firebase.dart';
import '../utils/methods.dart';
import 'auth_ctrl.dart';

class HomeCtrl extends GetxController {
  static HomeCtrl get to => Get.find();

  bool dataLoaded = false;

  List<PatientModel> patients = [];
  int patientsCount = 0;
  List<MeetingPersonModel> get meetingPersons => patients
      .map(
        (p) => MeetingPersonModel(
          docId: p.docId,
          name: p.name,
          lowerName: p.lowerName,
          email: p.email,
          phone: p.phone,
          createdByRole: p.createdByRole,
          createdAt: p.createdAt,
          updatedAt: p.updatedAt,
        ),
      )
      .toList();
  List<AppointmentMeetingModel> appointments = [];
  List<AppointmentMeetingModel> meetings = [];

  // Today-scoped lists — live stream from midnight to 23:59:59
  // List<AppointmentMeetingModel> todayAppointments = [];
  // List<AppointmentMeetingModel> todayMeetings = [];
  int todayAppointmentsCount = 0;
  int todayMeetingsCount = 0;
  StreamSubscription<User?>? _authSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _patientsStream;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _appointmentsStream;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _meetingsStream;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _settingsSub;
  Timer? _clockTimer;

  bool versionSupported = true;

  @override
  void onInit() {
    super.onInit();
    _startSettingsStream();
    _authSub = FBAuth.auth.authStateChanges().listen((user) {
      if (user != null) {
        _startStreams();
      } else {
        _cancelAll();
        _clearAll();
      }
    });
  }

  @override
  void onClose() {
    _authSub?.cancel();
    _settingsSub?.cancel();
    _clockTimer?.cancel();
    _cancelAll();
    super.onClose();
  }

  void _startSettingsStream() {
    _settingsSub = FBFireStore.settings.snapshots().listen((snapshot) async {
      if (!snapshot.exists) return;
      final data = snapshot.data();
      if (data == null) return;

      String? firebaseBuildStr;
      if (io.Platform.isAndroid) {
        firebaseBuildStr = data['andbuildNumber']?.toString();
      } else {
        firebaseBuildStr = data['iosbuildNumber']?.toString();
      }
      // Fallback to generic minversion field
      firebaseBuildStr ??=
          data['minversion']?.toString() ?? data['minVersion']?.toString();

      if (firebaseBuildStr == null || firebaseBuildStr.isEmpty) return;

      try {
        final packageInfo = await PackageInfo.fromPlatform();
        final currentBuild = int.tryParse(packageInfo.buildNumber) ?? 0;
        final minBuild = int.tryParse(firebaseBuildStr) ?? 0;
        final supported = currentBuild >= minBuild;
        debugPrint(
          'Version check — current: $currentBuild, required: $minBuild, supported: $supported',
        );
        if (versionSupported != supported) {
          versionSupported = supported;
          update();
        }
      } catch (e) {
        debugPrint('Version check error: $e');
      }
    }, onError: (e) => debugPrint('Settings stream error: $e'));
  }

  void _startStreams() async {
    String doctorId = AuthCtrl.to.currentDoctor?.docId ?? '';

    // AuthCtrl._loadDoctorProfile is async — poll until it resolves (max 3 s)
    if (doctorId.isEmpty) {
      for (var i = 0; i < 10; i++) {
        await Future.delayed(const Duration(milliseconds: 300));
        doctorId = AuthCtrl.to.currentDoctor?.docId ?? '';
        if (doctorId.isNotEmpty) break;
      }
    }

    if (doctorId.isEmpty) return;
    _launchStreams(doctorId);
  }

  void _launchStreams(String doctorId) {
    _fetchPatientsCount();
    // getAppointments(doctorId);
    // getMeetings(doctorId);
    getTodayAppointments(doctorId);
    getTodayMeetings(doctorId);
    dataLoaded = true;
    update();

    // Tick every minute so upcomingNextHour re-evaluates as the clock moves
    _clockTimer?.cancel();
    _clockTimer = Timer.periodic(const Duration(minutes: 1), (_) => update());
  }

  void _cancelAll() {
    _patientsStream?.cancel();
    _appointmentsStream?.cancel();
    _meetingsStream?.cancel();
    _clockTimer?.cancel();
    _clockTimer = null;
    patientsCount = 0;
    dataLoaded = false;
  }

  void _clearAll() {
    patients.clear();
    appointments.clear();
    meetings.clear();
    // todayAppointments.clear();
    // todayMeetings.clear();
    patientsCount = 0;
    update();
  }

  void _fetchPatientsCount() async {
    try {
      final aggregateQuery = await FBFireStore.patients.count().get();
      patientsCount = aggregateQuery.count ?? 0;
      update();
    } catch (e) {
      debugPrint('Failed to get patients count: $e');
    }
  }

  // ─── Patients ──────────────────────────────────────────────────────────────

  Future<PatientModel?> createPatient({
    required String name,
    required String email,
    required String phone,
  }) async {
    try {
      // final doctorId = AuthCtrl.to.currentDoctor?.docId ?? '';
      final ref = FBFireStore.patients.doc();
      final now = Timestamp.fromDate(DateTime.now());
      final (code, rest) = splitStoredPhone(phone);
      final data = {
        'docId': ref.id,
        'name': name.trim(),
        'lowerName': name.trim().toLowerCase(),
        'email': email.trim(),
        'phone': phone.trim(),
        'countryCode': code,
        'phoneNumber': rest,
        'combinationNames': generateSearchCombinations(name),
        // 'doctorId': doctorId,
        'createdByRole': 'doctor',
        'createdAt': now,
        'updatedAt': now,
      };
      await ref.set(data);
      patientsCount++;
      update();
      return PatientModel.fromJson(data);
    } catch (e) {
      debugPrint(e.toString());
      return null;
    }
  }

  // ─── Meeting Persons ───────────────────────────────────────────────────────

  Future<MeetingPersonModel?> createMeetingPerson({
    required String name,
    required String email,
    required String phone,
  }) async {
    try {
      // final doctorId = AuthCtrl.to.currentDoctor?.docId;
      final ref = FBFireStore.meetingPersons.doc();
      final now = Timestamp.fromDate(DateTime.now());
      final (code, rest) = splitStoredPhone(phone);
      final data = {
        'docId': ref.id,
        'name': name.trim(),
        'lowerName': name.trim().toLowerCase(),
        'email': email.trim(),
        'phone': phone.trim(),
        'countryCode': code,
        'phoneNumber': rest,
        'combinationNames': generateSearchCombinations(name),
        // 'doctorId': doctorId,
        'createdByRole': 'doctor',
        'createdAt': now,
        'updatedAt': now,
      };
      await ref.set(data);
      return MeetingPersonModel.fromJson(data);
    } catch (e) {
      debugPrint(e.toString());
      return null;
    }
  }

  // ─── Appointments ──────────────────────────────────────────────────────────
  /* 
  void getAppointments(String doctorId) {
    _appointmentsStream?.cancel();
    _appointmentsStream = FBFireStore.apptAndMeeting
        .where('doctorId', isEqualTo: doctorId)
        .where('docType', isEqualTo: 'appointment')
        .orderBy('startTime', descending: false)
        .snapshots()
        .listen((event) {
          appointments = event.docs
              .map(AppointmentMeetingModel.fromQueryDocumentSnapshot)
              .toList();
          print("Ain Ctrl Apointments= ${appointments.length}");
          update();
        }, onError: (e) => debugPrint(e.toString()));
  } */

  Future<bool> createAppointment(AppointmentMeetingModel appt) async {
    try {
      final ref = FBFireStore.apptAndMeeting.doc();
      await ref.set({...appt.toJson(), 'docId': ref.id});
      return true;
    } catch (e) {
      debugPrint(e.toString());
      return false;
    }
  }

  Future<bool> updateAppointment(AppointmentMeetingModel appt) async {
    try {
      await FBFireStore.apptAndMeeting.doc(appt.docId).update(appt.toJson());
      return true;
    } catch (e) {
      debugPrint(e.toString());
      return false;
    }
  }

  Future<bool> cancelAppointment({
    required String docId,
    required String reason,
  }) async {
    try {
      final doctorName =
          AuthCtrl.to.currentDoctor?.name ?? AuthCtrl.to.enteredEmail;
      await FBFireStore.apptAndMeeting.doc(docId).update({
        'status': 'Cancelled',
        'cancelledBy': doctorName,
        'cancellationReason': reason,
        'cancelledAt': Timestamp.fromDate(DateTime.now()),
      });
      return true;
    } catch (e) {
      debugPrint(e.toString());
      return false;
    }
  }

  Future<bool> completeAppointment({
    required String docId,
    String summary = '',
  }) async {
    try {
      final doctorName =
          AuthCtrl.to.currentDoctor?.name ?? AuthCtrl.to.enteredEmail;
      await FBFireStore.apptAndMeeting.doc(docId).update({
        'status': 'Completed',
        'completedBy': doctorName,
        'summary': summary,
        'completedAt': Timestamp.fromDate(DateTime.now()),
      });
      return true;
    } catch (e) {
      debugPrint(e.toString());
      return false;
    }
  }

  // ─── Meetings ──────────────────────────────────────────────────────────────
  /* 
  void getMeetings(String doctorId) {
    _meetingsStream?.cancel();
    _meetingsStream = FBFireStore.apptAndMeeting
        .where('doctorId', isEqualTo: doctorId)
        .where('docType', isEqualTo: 'meeting')
        .orderBy('startTime', descending: false)
        .snapshots()
        .listen((event) {
          meetings = event.docs
              .map(AppointmentMeetingModel.fromQueryDocumentSnapshot)
              .toList();
          update();
        }, onError: (e) => debugPrint(e.toString()));
  } */

  Future<bool> createMeeting(AppointmentMeetingModel meeting) async {
    try {
      final ref = FBFireStore.apptAndMeeting.doc();
      await ref.set({...meeting.toJson(), 'docId': ref.id});
      return true;
    } catch (e) {
      debugPrint(e.toString());
      return false;
    }
  }

  Future<bool> updateMeeting(AppointmentMeetingModel meeting) async {
    try {
      await FBFireStore.apptAndMeeting
          .doc(meeting.docId)
          .update(meeting.toJson());
      return true;
    } catch (e) {
      debugPrint(e.toString());
      return false;
    }
  }

  Future<bool> cancelMeeting({
    required String docId,
    required String reason,
  }) async {
    try {
      final doctorName =
          AuthCtrl.to.currentDoctor?.name ?? AuthCtrl.to.enteredEmail;
      await FBFireStore.apptAndMeeting.doc(docId).update({
        'status': 'Cancelled',
        'cancelledBy': doctorName,
        'cancellationReason': reason,
        'cancelledAt': Timestamp.fromDate(DateTime.now()),
      });
      return true;
    } catch (e) {
      debugPrint(e.toString());
      return false;
    }
  }

  // ─── Switch active doctor ──────────────────────────────────────────────────

  void restartForDoctor(String doctorId) {
    _patientsStream?.cancel();
    _appointmentsStream?.cancel();
    _meetingsStream?.cancel();
    _clockTimer?.cancel();
    _clockTimer = null;
    patients.clear();
    appointments.clear();
    meetings.clear();
    // todayAppointments.clear();
    // todayMeetings.clear();
    dataLoaded = false;
    update();
    _launchStreams(doctorId);
  }

  // ─── Today-scoped count queries (midnight → 23:59:59) ──────────────────────

  Future<void> getTodayAppointments(String doctorId) async {
    try {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day);
      final end = DateTime(now.year, now.month, now.day, 23, 59, 59);

      final aggregateQuery = await FBFireStore.apptAndMeeting
          .where('doctorId', isEqualTo: doctorId)
          .where('docType', isEqualTo: 'appointment')
          .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('startTime', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .count()
          .get();

      todayAppointmentsCount = aggregateQuery.count ?? 0;
      update();
    } catch (e) {
      debugPrint('Failed to get today appointments count: $e');
    }
  }

  Future<void> getTodayMeetings(String doctorId) async {
    try {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day);
      final end = DateTime(now.year, now.month, now.day, 23, 59, 59);

      final aggregateQuery = await FBFireStore.apptAndMeeting
          .where('doctorId', isEqualTo: doctorId)
          .where('docType', isEqualTo: 'meeting')
          .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('startTime', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .count()
          .get();

      todayMeetingsCount = aggregateQuery.count ?? 0;
      update();
    } catch (e) {
      debugPrint('Failed to get today meetings count: $e');
    }
  }

  Future<bool> completeMeeting({
    required String docId,
    String summary = '',
  }) async {
    try {
      final doctorName =
          AuthCtrl.to.currentDoctor?.name ?? AuthCtrl.to.enteredEmail;
      await FBFireStore.apptAndMeeting.doc(docId).update({
        'status': 'Completed',
        'completedBy': doctorName,
        'summary': summary,
        'completedAt': Timestamp.fromDate(DateTime.now()),
      });
      return true;
    } catch (e) {
      debugPrint(e.toString());
      return false;
    }
  }

  // ─── Real-time listen by date/range ──────────────────────────────────────

  /*   Stream<List<AppointmentMeetingModel>> listenAppointmentsForDate(
    DateTime date,
  ) {
    final doctorId = AuthCtrl.to.currentDoctor?.docId ?? '';
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return FBFireStore.apptAndMeeting
        .where('doctorId', isEqualTo: doctorId)
        .where('docType', isEqualTo: 'appointment')
        .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('startTime', isLessThan: Timestamp.fromDate(end))
        .orderBy('startTime')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(AppointmentMeetingModel.fromQueryDocumentSnapshot)
              .toList(),
        );
  } */

  /*   Stream<List<AppointmentMeetingModel>> listenMeetingsForDate(DateTime date) {
    final doctorId = AuthCtrl.to.currentDoctor?.docId ?? '';
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return FBFireStore.apptAndMeeting
        .where('doctorId', isEqualTo: doctorId)
        .where('docType', isEqualTo: 'meeting')
        .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('startTime', isLessThan: Timestamp.fromDate(end))
        .orderBy('startTime')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(AppointmentMeetingModel.fromQueryDocumentSnapshot)
              .toList(),
        );
  } */

  /*  Stream<List<AppointmentMeetingModel>> listenAppointmentsForRange(
    DateTime from,
    DateTime to,
  ) {
    final doctorId = AuthCtrl.to.currentDoctor?.docId ?? '';
    final start = DateTime(from.year, from.month, from.day);
    final end = DateTime(
      to.year,
      to.month,
      to.day,
    ).add(const Duration(days: 1));
    return FBFireStore.apptAndMeeting
        .where('doctorId', isEqualTo: doctorId)
        .where('docType', isEqualTo: 'appointment')
        .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('startTime', isLessThan: Timestamp.fromDate(end))
        .orderBy('startTime')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(AppointmentMeetingModel.fromQueryDocumentSnapshot)
              .toList(),
        );
  } */

  /*  Stream<List<AppointmentMeetingModel>> listenMeetingsForRange(
    DateTime from,
    DateTime to,
  ) {
    final doctorId = AuthCtrl.to.currentDoctor?.docId ?? '';
    final start = DateTime(from.year, from.month, from.day);
    final end = DateTime(
      to.year,
      to.month,
      to.day,
    ).add(const Duration(days: 1));
    return FBFireStore.apptAndMeeting
        .where('doctorId', isEqualTo: doctorId)
        .where('docType', isEqualTo: 'meeting')
        .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('startTime', isLessThan: Timestamp.fromDate(end))
        .orderBy('startTime')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(AppointmentMeetingModel.fromQueryDocumentSnapshot)
              .toList(),
        );
  } */

  Future<Map<String, dynamic>> fetchSchedulePage({
    required String docTypeFilter,
    required String statusFilter,
    required DateTime startDateTime,
    DateTime? endDateTime,
    required int limit,
    DocumentSnapshot? startAfterDoc,
  }) async {
    final doctorId = AuthCtrl.to.currentDoctor?.docId ?? '';
    try {
      Query<Map<String, dynamic>> query = FBFireStore.apptAndMeeting
          .where('doctorId', isEqualTo: doctorId)
          .where(
            'startTime',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDateTime),
          );

      if (endDateTime != null) {
        query = query.where(
          'startTime',
          isLessThan: Timestamp.fromDate(endDateTime),
        );
      }

      if (docTypeFilter != 'all') {
        query = query.where('docType', isEqualTo: docTypeFilter);
      }
      if (statusFilter != 'All') {
        query = query.where('status', isEqualTo: statusFilter);
      }

      query = query.orderBy('startTime');

      if (startAfterDoc != null) {
        query = query.startAfterDocument(startAfterDoc);
      }

      final snap = await query.limit(limit).get();
      final items = snap.docs
          .map(AppointmentMeetingModel.fromQueryDocumentSnapshot)
          .toList();

      return {
        'items': items,
        'lastDoc': snap.docs.isNotEmpty ? snap.docs.last : null,
      };
    } catch (e) {
      debugPrint(e.toString());
      return {'items': <AppointmentMeetingModel>[], 'lastDoc': null};
    }
  }

  // ─── On-demand fetch by date (using .get()) ──────────────────────────────

  Future<List<AppointmentMeetingModel>> fetchAppointmentsForDate(
    DateTime date,
  ) async {
    final doctorId = AuthCtrl.to.currentDoctor?.docId ?? '';
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    try {
      final snap = await FBFireStore.apptAndMeeting
          .where('doctorId', isEqualTo: doctorId)
          .where('docType', isEqualTo: 'appointment')
          .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('startTime', isLessThan: Timestamp.fromDate(end))
          .orderBy('startTime')
          .get();
      return snap.docs
          .map(AppointmentMeetingModel.fromQueryDocumentSnapshot)
          .toList();
    } catch (e) {
      debugPrint(e.toString());
      return [];
    }
  }

  Future<List<AppointmentMeetingModel>> fetchAppointmentsForRange(
    DateTime from,
    DateTime to,
  ) async {
    final doctorId = AuthCtrl.to.currentDoctor?.docId ?? '';
    final start = DateTime(from.year, from.month, from.day);
    final end = DateTime(
      to.year,
      to.month,
      to.day,
    ).add(const Duration(days: 1));
    try {
      final snap = await FBFireStore.apptAndMeeting
          .where('doctorId', isEqualTo: doctorId)
          .where('docType', isEqualTo: 'appointment')
          .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('startTime', isLessThan: Timestamp.fromDate(end))
          .orderBy('startTime')
          .get();
      return snap.docs
          .map(AppointmentMeetingModel.fromQueryDocumentSnapshot)
          .toList();
    } catch (e) {
      debugPrint(e.toString());
      return [];
    }
  }

  Future<List<AppointmentMeetingModel>> fetchMeetingsForDate(
    DateTime date,
  ) async {
    final doctorId = AuthCtrl.to.currentDoctor?.docId ?? '';
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    try {
      final snap = await FBFireStore.apptAndMeeting
          .where('doctorId', isEqualTo: doctorId)
          .where('docType', isEqualTo: 'meeting')
          .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('startTime', isLessThan: Timestamp.fromDate(end))
          .orderBy('startTime')
          .get();
      return snap.docs
          .map(AppointmentMeetingModel.fromQueryDocumentSnapshot)
          .toList();
    } catch (e) {
      debugPrint(e.toString());
      return [];
    }
  }

  Future<List<AppointmentMeetingModel>> fetchMeetingsForRange(
    DateTime from,
    DateTime to,
  ) async {
    final doctorId = AuthCtrl.to.currentDoctor?.docId ?? '';
    final start = DateTime(from.year, from.month, from.day);
    final end = DateTime(
      to.year,
      to.month,
      to.day,
    ).add(const Duration(days: 1));
    try {
      final snap = await FBFireStore.apptAndMeeting
          .where('doctorId', isEqualTo: doctorId)
          .where('docType', isEqualTo: 'meeting')
          .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('startTime', isLessThan: Timestamp.fromDate(end))
          .orderBy('startTime')
          .get();
      return snap.docs
          .map(AppointmentMeetingModel.fromQueryDocumentSnapshot)
          .toList();
    } catch (e) {
      debugPrint(e.toString());
      return [];
    }
  }

  // ─── Records for a specific person on a specific date ─────────────────────

  Future<List<AppointmentMeetingModel>> fetchRecordsForPersonOnDate({
    required String personId,
    required String doctorId,
    required DateTime date,
  }) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    try {
      final snap = await FBFireStore.apptAndMeeting
          // .where('doctorId', isEqualTo: doctorId)
          .where('personId', isEqualTo: personId)
          .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('startTime', isLessThan: Timestamp.fromDate(end))
          .orderBy('startTime')
          .get();
      return snap.docs
          .map(AppointmentMeetingModel.fromQueryDocumentSnapshot)
          .toList();
    } catch (e) {
      debugPrint(e.toString());
      return [];
    }
  }

  // ─── Conflict check ────────────────────────────────────────────────────────

  Future<List<AppointmentMeetingModel>> fetchConflicts({
    required DateTime newStart,
    required DateTime newEnd,
    String excludeDocId = '',
  }) async {
    final doctorId = AuthCtrl.to.currentDoctor?.docId ?? '';
    final snap = await FBFireStore.apptAndMeeting
        .where('doctorId', isEqualTo: doctorId)
        .where('status', isEqualTo: 'Scheduled')
        .where('startTime', isLessThan: Timestamp.fromDate(newEnd))
        .get();
    return snap.docs
        .map(AppointmentMeetingModel.fromQueryDocumentSnapshot)
        .where((e) => e.docId != excludeDocId && e.endTime.isAfter(newStart))
        .toList();
  }

  // ─── Dashboard stats ───────────────────────────────────────────────────────

  int get totalAppointments => appointments.length;
  int get totalMeetings => meetings.length;

  List<AppointmentMeetingModel> appointmentsForDate(DateTime date) {
    return appointments.where((a) {
      final d = a.startTime;
      return d.year == date.year && d.month == date.month && d.day == date.day;
    }).toList()..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  List<AppointmentMeetingModel> meetingsForDate(DateTime date) {
    return meetings.where((m) {
      final d = m.startTime;
      return d.year == date.year && d.month == date.month && d.day == date.day;
    }).toList()..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  // ─── Today's live counts — driven by the today-scoped streams ───────────────

  // int get todayAppointmentsCount => todayAppointments.length;

  // int get todayMeetingsCount => todayMeetings.length;

  // ─── Up-next: scheduled items starting within the next 60 minutes ──────────
  // Reads from the today stream (midnight–23:59:59), no extra query needed.

  // List<AppointmentMeetingModel> get upcomingNextHour {
  //   final now = DateTime.now();
  //   final cutoff = now.add(const Duration(hours: 1));
  //   return [...todayAppointments, ...todayMeetings]
  //       .where(
  //         (e) =>
  //             e.status == 'Scheduled' &&
  //             e.endTime.isAfter(now) && // not yet finished
  //             e.startTime.isBefore(
  //               cutoff,
  //             ), // starts within next hour (or already started)
  //       )
  //       .toList()
  //     ..sort((a, b) => a.startTime.compareTo(b.startTime));
  // }
}
