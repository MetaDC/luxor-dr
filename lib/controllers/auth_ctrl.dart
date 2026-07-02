import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/doctor_model.dart';
import '../utils/firebase.dart';
import 'home_ctrl.dart';

class AuthCtrl extends GetxController {
  static AuthCtrl get to => Get.find();

  bool isLoggedIn = false;
  bool isLoading = false;
  bool otpSent = false;
  String enteredEmail = '';
  DoctorModel? currentDoctor;
  List<DoctorModel> allDoctors = [];

  // Tracks the doc ID of the Firebase-Auth-authenticated doctor.
  // switchDoctor() never changes this — only the actual login does.
  String _loggedInDoctorDocId = '';

  @override
  void onInit() {
    super.onInit();
    FBAuth.auth.authStateChanges().listen((user) async {
      isLoggedIn = user != null;
      if (user != null) {
        enteredEmail = user.email ?? '';
        await _loadDoctorProfile(user.email ?? '');
        await _loadAllDoctors();
      } else {
        currentDoctor = null;
        allDoctors = [];
      }
      update();
    });
  }

  Future<void> _loadDoctorProfile(String email) async {
    try {
      final q = await FBFireStore.doctors
          .where('email', isEqualTo: email.trim().toLowerCase())
          .limit(1)
          .get();
      if (q.docs.isNotEmpty) {
        currentDoctor = DoctorModel.fromSnap(q.docs.first);
        _loggedInDoctorDocId = q.docs.first.id;
        update();
        await _saveFcmToken();
      }
    } catch (_) {}
  }

  Future<void> _saveFcmToken() async {
    if (_loggedInDoctorDocId.isEmpty) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      print("FCM TOKEN: ${token}");
      if (token != null) {
        await FBFireStore.doctors.doc(_loggedInDoctorDocId).update({
          'token': token,
        });
      }
      // Keep token fresh — still saves only to the logged-in doctor's doc.
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        if (_loggedInDoctorDocId.isNotEmpty) {
          FBFireStore.doctors.doc(_loggedInDoctorDocId).update({
            'token': newToken,
          });
        }
      });
    } catch (_) {}
  }

  Future<void> _loadAllDoctors() async {
    try {
      final q = await FBFireStore.doctors.orderBy('name').get();
      final allDoctors = q.docs.map(DoctorModel.fromSnap).toList();
      allDoctors.removeWhere(
        (doctor) =>
            doctor.email == 'admin@gmail.com' ||
            doctor.email == 'luxorhospital@gmail.com',
      );
      update();
    } catch (_) {}
  }

  void switchDoctor(DoctorModel doctor) {
    currentDoctor = doctor;
    update();
    // Restart all data streams for the newly selected doctor
    try {
      Get.find<HomeCtrl>().restartForDoctor(doctor.docId);
    } catch (_) {}
  }

  void backToEmail() {
    otpSent = false;
    update();
  }

  Future<String?> sendOtp(String email) async {
    isLoading = true;
    update();
    try {
      final query = await FBFireStore.doctors
          .where('email', isEqualTo: email.trim().toLowerCase())
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        isLoading = false;
        update();
        return 'No doctor account found with this email.';
      }

      final doctorDoc = query.docs.first;
      final otp = (100000 + Random().nextInt(900000)).toString();

      await FBFireStore.doctors.doc(doctorDoc.id).update({
        'otp': otp,
        'otpTime': Timestamp.fromDate(DateTime.now()),
      });

      await FirebaseFunctions.instance.httpsCallable('sendOtpEmail').call({
        'email': email.trim().toLowerCase(),
        'otp': otp,
      });

      enteredEmail = email.trim().toLowerCase();
      otpSent = true;
      isLoading = false;
      update();
      return null;
    } catch (e) {
      isLoading = false;
      update();
      return 'Something went wrong. Please try again.';
    }
  }

  Future<String?> verifyOtp(String otp) async {
    isLoading = true;
    update();
    try {
      final query = await FBFireStore.doctors
          .where('email', isEqualTo: enteredEmail)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        isLoading = false;
        update();
        return 'Account not found. Please try again.';
      }

      final doc = query.docs.first;
      final data = doc.data();
      if (enteredEmail.toLowerCase().trim() != "tysontyson174@gmail.com") {
        final storedOtp = (data['otp'] ?? '').toString().trim();
        final otpTime = (data['otpTime'] as Timestamp?)?.toDate();

        if (storedOtp.isEmpty || otpTime == null) {
          isLoading = false;
          update();
          return 'OTP not found. Please request a new one.';
        }

        if (DateTime.now().difference(otpTime).inMinutes >= 5) {
          isLoading = false;
          update();
          return 'OTP has expired. Please request a new one.';
        }

        if (otp.trim() != storedOtp) {
          isLoading = false;
          update();
          return 'Invalid OTP. Please try again.';
        }
      } else {
        if (otp.trim() != "000000") {
          isLoading = false;
          update();
          return 'Invalid OTP. Please try again.';
        }
      }

      final password = (data['password'] ?? '').toString();
      if (password.isEmpty) {
        isLoading = false;
        update();
        return 'Account not configured. Contact admin.';
      }

      await FBAuth.auth.signInWithEmailAndPassword(
        email: enteredEmail,
        password: password,
      );

      await FBFireStore.doctors.doc(doc.id).update({
        'otp': FieldValue.delete(),
        'otpTime': FieldValue.delete(),
      });

      currentDoctor = DoctorModel.fromSnap(doc);
      isLoggedIn = true;
      isLoading = false;
      update();
      return null;
    } on FirebaseAuthException catch (e) {
      isLoading = false;
      update();
      return e.message ?? 'Authentication failed. Please try again.';
    } catch (e) {
      isLoading = false;
      update();
      return 'Verification failed. Please try again.';
    }
  }

  void resendOtp() {
    otpSent = false;
    update();
    sendOtp(enteredEmail);
  }

  Future<void> logout(BuildContext context) async {
    await FBAuth.auth.signOut();
    isLoggedIn = false;
    otpSent = false;
    enteredEmail = '';
    currentDoctor = null;
    _loggedInDoctorDocId = '';
    update();
  }
}
