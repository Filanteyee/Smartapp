import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<String?> registerResident({
    required String fullName,
    required String email,
    required String password,
    required String phone,
    required String iin,
    required String personType,
    required String city,
    required String street,
    required String propertyType,
    required String propertyNumber,
    required String fullAddress,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final user = credential.user;
      if (user == null) {
        return 'Не удалось создать пользователя';
      }

      await user.updateDisplayName(fullName.trim());

      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'fullName': fullName.trim(),
        'email': email.trim(),
        'phone': phone.trim(),
        'iin': iin.trim(),
        'personType': personType,
        'city': city,
        'street': street,
        'propertyType': propertyType,
        'propertyNumber': propertyNumber,
        'address': fullAddress,
        'verificationStatus': 'not_submitted',
        'residentRole': 'unverified',
        'createdAt': FieldValue.serverTimestamp(),
      });

      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          return 'Этот email уже используется';
        case 'invalid-email':
          return 'Некорректный email';
        case 'weak-password':
          return 'Слишком слабый пароль';
        case 'operation-not-allowed':
          return 'В Firebase не включён Email/Password';
        default:
          return e.message ?? 'Ошибка регистрации';
      }
    } catch (e) {
      return 'Неизвестная ошибка: $e';
    }
  }

  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          return 'Пользователь не найден';
        case 'wrong-password':
        case 'invalid-credential':
          return 'Неверный email или пароль';
        case 'invalid-email':
          return 'Некорректный email';
        default:
          return e.message ?? 'Ошибка входа';
      }
    } catch (e) {
      return 'Неизвестная ошибка: $e';
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    return doc.data();
  }

  Future<String?> submitVerificationRequest({
    required String requestedRole,
    required List<PlatformFile> documents,
    String? comment,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 'Сначала войдите в аккаунт';

      if (documents.isEmpty) {
        return 'Прикрепите хотя бы один документ';
      }

      final uploadedDocs = <Map<String, dynamic>>[];

      for (final doc in documents) {
        if (doc.path == null) continue;

        final ref = _storage
            .ref()
            .child('verification_docs/${user.uid}/${DateTime.now().millisecondsSinceEpoch}_${doc.name}');

        await ref.putFile(File(doc.path!));
        final url = await ref.getDownloadURL();

        uploadedDocs.add({
          'name': doc.name,
          'url': url,
          'size': doc.size,
        });
      }

      await _firestore.collection('verification_requests').doc(user.uid).set({
        'uid': user.uid,
        'requestedRole': requestedRole,
        'comment': comment?.trim() ?? '',
        'documents': uploadedDocs,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _firestore.collection('users').doc(user.uid).update({
        'verificationStatus': 'pending',
      });

      return null;
    } catch (e) {
      return 'Ошибка отправки документов: $e';
    }
  }
}