import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class AuthService {
  final supabase.SupabaseClient _supabase = supabase.Supabase.instance.client;

  Stream<supabase.User?> get authStateChanges =>
      _supabase.auth.onAuthStateChange.map((event) => event.session?.user);

  supabase.User? get currentUser => _supabase.auth.currentUser;

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
      final response = await _supabase.auth.signUp(
        email: email.trim(),
        password: password.trim(),
        data: {
          'full_name': fullName.trim(),
          'phone': phone.trim(),
          'iin': iin.trim(),
          'person_type': personType,
          'city': city,
          'street': street,
          'property_type': propertyType,
          'property_number': propertyNumber,
          'full_address': fullAddress.trim(),
          'role': 'resident',
        },
      );

      final user = response.user;
      if (user == null) {
        return 'Не удалось создать пользователя';
      }

      await _supabase.from('profiles').update({
        'full_name': fullName.trim(),
        'email': email.trim(),
        'phone': phone.trim(),
        'iin': iin.trim(),
        'person_type': personType,
        'city': city,
        'street': street,
        'property_type': propertyType,
        'property_number': propertyNumber,
        'full_address': fullAddress.trim(),
        'role': 'resident',
        'verification_status': 'not_submitted',
      }).eq('id', user.id);

      return null;
    } on supabase.AuthException catch (e) {
      final message = e.message.toLowerCase();

      if (message.contains('already registered') ||
          message.contains('user already registered')) {
        return 'Этот email уже используется';
      }

      if (message.contains('invalid email')) {
        return 'Некорректный email';
      }

      if (message.contains('password')) {
        return 'Слишком слабый пароль';
      }

      return e.message;
    } catch (e) {
      return 'Неизвестная ошибка: $e';
    }
  }

  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return null;
    } on supabase.AuthException catch (e) {
      final message = e.message.toLowerCase();

      if (message.contains('invalid login credentials')) {
        return 'Неверный email или пароль';
      }

      if (message.contains('email not confirmed')) {
        return 'Подтвердите email перед входом';
      }

      if (message.contains('invalid email')) {
        return 'Некорректный email';
      }

      return e.message;
    } catch (e) {
      return 'Неизвестная ошибка: $e';
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    final data = await _supabase
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    return data;
  }

  Future<String?> submitVerificationRequest({
    required String requestedRole,
    required List<PlatformFile> documents,
    String? comment,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return 'Сначала войдите в аккаунт';

      if (documents.isEmpty) {
        return 'Прикрепите хотя бы один документ';
      }

      final verificationRequest = await _supabase
          .from('verification_requests')
          .insert({
        'user_id': user.id,
        'requested_role': requestedRole,
        'comment': comment?.trim() ?? '',
        'status': 'pending',
      })
          .select()
          .single();

      final verificationRequestId = verificationRequest['id'] as String;

      for (final doc in documents) {
        if (doc.path == null) continue;

        final file = File(doc.path!);
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${doc.name}';
        final filePath = '${user.id}/$fileName';

        await _supabase.storage
            .from('verification-docs')
            .upload(filePath, file);

        await _supabase.from('verification_documents').insert({
          'verification_request_id': verificationRequestId,
          'file_path': filePath,
          'file_name': doc.name,
          'file_size': doc.size,
        });
      }

      await _supabase.from('profiles').update({
        'verification_status': 'pending',
      }).eq('id', user.id);

      return null;
    } catch (e) {
      return 'Ошибка отправки документов: $e';
    }
  }
}