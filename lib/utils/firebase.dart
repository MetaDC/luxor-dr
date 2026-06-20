import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FBAuth {
  static final auth = FirebaseAuth.instance;
}

class FBFireStore {
  static final _db = FirebaseFirestore.instance;

  static final apptAndMeeting = _db.collection('ApptMeeting');
  static final doctors = _db.collection('Doctors');
  static final patients = _db.collection('Patients');
  static final meetingPersons = _db.collection('MeetingPersons');
}
