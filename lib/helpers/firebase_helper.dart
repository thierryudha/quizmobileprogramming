import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/contact.dart';

class FirebaseHelper {
  final CollectionReference collection =
      FirebaseFirestore.instance.collection('contacts');

  Future<void> insert(Contact contact) async {
    await collection.add(contact.toMap());
  }

  Stream<List<Contact>> getContacts() {
    return collection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Contact.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    });
  }

  Future<void> update(String id, Contact contact) async {
    await collection.doc(id).update(contact.toMap());
  }

  Future<void> delete(String id) async {
    await collection.doc(id).delete();
  }
}