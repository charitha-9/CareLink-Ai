import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/emergency_contact_model.dart';
import '../models/emergency_history_model.dart';
import '../models/emergency_model.dart';
import '../models/parent_guardian_link_model.dart';
import '../models/student_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore;

  FirestoreService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // Collection references
  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  CollectionReference<Map<String, dynamic>> get _emergencyEventsCollection =>
      _firestore.collection('emergency_events');

  CollectionReference<Map<String, dynamic>> get _emergencyContactsCollection =>
      _firestore.collection('emergency_contacts');

  CollectionReference<Map<String, dynamic>> get _parentLinksCollection =>
      _firestore.collection('parent_guardian_links');

  CollectionReference<Map<String, dynamic>> get _emergencyHistoryCollection =>
      _firestore.collection('emergency_history');

  // ============================================================
  // USER / STUDENT PROFILE
  // ============================================================

  Future<void> saveStudentProfile(StudentModel student) async {
    await _usersCollection
        .doc(student.studentId)
        .set(student.toMap(), SetOptions(merge: true));
  }

  Future<StudentModel?> getStudentProfile(String userId) async {
    final doc = await _usersCollection.doc(userId).get();
    if (doc.exists && doc.data() != null) {
      return StudentModel.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  Stream<StudentModel?> streamStudentProfile(String userId) {
    return _usersCollection.doc(userId).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return StudentModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    });
  }

  Future<void> updateFcmToken(String userId, String token) async {
    await _usersCollection.doc(userId).set(
      {'fcmToken': token},
      SetOptions(merge: true),
    );
  }

  // ============================================================
  // EMERGENCY EVENTS
  // ============================================================

  Future<void> createEmergencyEvent(EmergencyModel event) async {
    await _emergencyEventsCollection.doc(event.emergencyId).set(event.toMap());
  }

  Future<void> updateEmergencyEvent(EmergencyModel event) async {
    await _emergencyEventsCollection
        .doc(event.emergencyId)
        .set(event.toMap(), SetOptions(merge: true));
  }

  Future<EmergencyModel?> getEmergencyEvent(String eventId) async {
    final doc = await _emergencyEventsCollection.doc(eventId).get();
    if (doc.exists && doc.data() != null) {
      return EmergencyModel.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  Stream<List<EmergencyModel>> streamActiveEmergencies(String studentId) {
    return _emergencyEventsCollection
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => EmergencyModel.fromMap(doc.data(), doc.id))
          .where((event) =>
              event.status != EmergencyStatus.resolved &&
              event.status != EmergencyStatus.cancelled)
          .toList();
    });
  }

  // ============================================================
  // EMERGENCY CONTACTS
  // ============================================================

  Future<void> addEmergencyContact(EmergencyContactModel contact) async {
    final docRef = contact.contactId.isNotEmpty
        ? _emergencyContactsCollection.doc(contact.contactId)
        : _emergencyContactsCollection.doc();

    final toSave = contact.contactId.isEmpty
        ? contact.copyWith(contactId: docRef.id)
        : contact;

    await docRef.set(toSave.toMap(), SetOptions(merge: true));
  }

  Future<void> updateEmergencyContact(EmergencyContactModel contact) async {
    await _emergencyContactsCollection
        .doc(contact.contactId)
        .set(contact.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteEmergencyContact(String contactId) async {
    await _emergencyContactsCollection.doc(contactId).delete();
  }

  Future<List<EmergencyContactModel>> getEmergencyContacts(
      String studentId) async {
    final snapshot = await _emergencyContactsCollection
        .where('studentId', isEqualTo: studentId)
        .get();

    return snapshot.docs
        .map((doc) => EmergencyContactModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Stream<List<EmergencyContactModel>> streamEmergencyContacts(
      String studentId) {
    return _emergencyContactsCollection
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => EmergencyContactModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // ============================================================
  // PARENT / GUARDIAN LINKS
  // ============================================================

  Future<void> createParentGuardianLink(ParentGuardianLinkModel link) async {
    final docRef = link.linkId.isNotEmpty
        ? _parentLinksCollection.doc(link.linkId)
        : _parentLinksCollection.doc();

    final toSave =
        link.linkId.isEmpty ? link.copyWith(linkId: docRef.id) : link;

    await docRef.set(toSave.toMap(), SetOptions(merge: true));
  }

  Future<void> updateParentGuardianLink(ParentGuardianLinkModel link) async {
    await _parentLinksCollection
        .doc(link.linkId)
        .set(link.toMap(), SetOptions(merge: true));
  }

  Future<List<ParentGuardianLinkModel>> getParentGuardianLinks(
      String studentId) async {
    final snapshot = await _parentLinksCollection
        .where('studentId', isEqualTo: studentId)
        .get();

    return snapshot.docs
        .map((doc) => ParentGuardianLinkModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Stream<List<ParentGuardianLinkModel>> streamParentGuardianLinks(
      String studentId) {
    return _parentLinksCollection
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ParentGuardianLinkModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // ============================================================
  // EMERGENCY HISTORY
  // ============================================================

  Future<void> recordEmergencyHistory(EmergencyHistoryModel history) async {
    final docRef = history.historyId.isNotEmpty
        ? _emergencyHistoryCollection.doc(history.historyId)
        : _emergencyHistoryCollection.doc();

    final toSave = history.historyId.isEmpty
        ? history.copyWith(historyId: docRef.id)
        : history;

    await docRef.set(toSave.toMap(), SetOptions(merge: true));
  }

  Future<List<EmergencyHistoryModel>> getEmergencyHistory(
      String studentId) async {
    final snapshot = await _emergencyHistoryCollection
        .where('studentId', isEqualTo: studentId)
        .get();

    return snapshot.docs
        .map((doc) => EmergencyHistoryModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Stream<List<EmergencyHistoryModel>> streamEmergencyHistory(
      String studentId) {
    return _emergencyHistoryCollection
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => EmergencyHistoryModel.fromMap(doc.data(), doc.id))
            .toList());
  }
}