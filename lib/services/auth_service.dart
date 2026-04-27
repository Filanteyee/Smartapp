import 'dart:async';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';

import 'api_client.dart';

class AppUser {
  final String id;
  final String email;

  const AppUser({required this.id, required this.email});
}

class AuthService {
  final ApiClient _api = ApiClient.instance;
  final _controller = StreamController<AppUser?>.broadcast();

  AppUser? _currentUser;
  AppUser? get currentUser => _currentUser;
  Stream<AppUser?> get authStateChanges => _controller.stream;

  AuthService() {
    _init();
  }

  /// Обновляет JWT, подтягивая актуальную роль из БД.
  /// Вызывать при возврате приложения на экран.
  Future<void> refreshToken() async {
    if (!_api.isLoggedIn) return;
    try {
      final res = await _api.post('/auth/refresh');
      final newToken = res.data['token'] as String;
      final newRole = (res.data['role'] as String?) ?? 'resident';
      await _api.saveSession(
        token: newToken,
        userId: _api.userId!,
        role: newRole,
      );
    } catch (_) {}
  }

  Future<void> _init() async {
    if (!_api.isLoggedIn) {
      _controller.add(null);
      return;
    }

    try {
      final profile = await getCurrentUserProfile();
      if (profile != null) {
        // Обновляем JWT чтобы подтянуть актуальную роль из БД
        try {
          final refreshRes = await _api.post('/auth/refresh');
          final newToken = refreshRes.data['token'] as String;
          final newRole = (refreshRes.data['role'] as String?) ?? 'resident';
          await _api.saveSession(
            token: newToken,
            userId: _api.userId!,
            role: newRole,
          );
        } catch (_) {
          // Если refresh не удался — продолжаем с текущим токеном
        }

        _currentUser = AppUser(
          id: _api.userId!,
          email: (profile['email'] ?? '').toString(),
        );
        _controller.add(_currentUser);
        return;
      }
    } catch (_) {}

    // Токен невалиден — выходим
    await _api.clearSession();
    _controller.add(null);
  }

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
      final res = await _api.post('/auth/register', data: {
        'email': email.trim(),
        'password': password.trim(),
        'full_name': fullName.trim(),
        'phone': phone.trim(),
        'iin': iin.trim(),
        'person_type': personType,
        'city': city,
        'street': street,
        'property_type': propertyType,
        'property_number': propertyNumber,
        'full_address': fullAddress.trim(),
      });

      final token = res.data['token'] as String;
      final userId = res.data['user_id'] as String;
      await _api.saveSession(token: token, userId: userId, role: 'resident');

      _currentUser = AppUser(id: userId, email: email.trim());
      _controller.add(_currentUser);
      return null;
    } on DioException catch (e) {
      final msg = e.response?.data?['error']?.toString() ?? '';
      if (msg.contains('already registered') || e.response?.statusCode == 409) {
        return 'Этот email уже используется';
      }
      return msg.isNotEmpty ? msg : 'Ошибка регистрации';
    } catch (e) {
      return 'Неизвестная ошибка: $e';
    }
  }

  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _api.post('/auth/login', data: {
        'email': email.trim(),
        'password': password.trim(),
      });

      final token = res.data['token'] as String;
      final userId = res.data['user_id'] as String;
      final role = res.data['role'] as String? ?? 'resident';
      await _api.saveSession(token: token, userId: userId, role: role);

      _currentUser = AppUser(id: userId, email: email.trim());
      _controller.add(_currentUser);
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return 'Неверный email или пароль';
      }
      return e.response?.data?['error']?.toString() ?? 'Ошибка входа';
    } catch (e) {
      return 'Неизвестная ошибка: $e';
    }
  }

  Future<void> signOut() async {
    await _api.clearSession();
    _currentUser = null;
    _controller.add(null);
  }

  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    try {
      final res = await _api.get('/auth/me');
      return Map<String, dynamic>.from(res.data as Map);
    } catch (_) {
      return null;
    }
  }

  Future<String?> submitVerificationRequest({
    required String requestedRole,
    required List<PlatformFile> documents,
    String? comment,
  }) async {
    if (documents.isEmpty) return 'Прикрепите хотя бы один документ';

    try {
      final res = await _api.post('/verification/requests', data: {
        'requested_role': requestedRole,
        'comment': comment?.trim() ?? '',
      });

      final verId = res.data['id'] as String;

      final formData = FormData();
      for (final doc in documents) {
        if (doc.path == null) continue;
        formData.files.add(MapEntry(
          'documents',
          await MultipartFile.fromFile(doc.path!, filename: doc.name),
        ));
      }

      await _api.postForm('/verification/requests/$verId/documents', formData);
      return null;
    } on DioException catch (e) {
      return e.response?.data?['error']?.toString() ?? 'Ошибка отправки документов';
    } catch (e) {
      return 'Ошибка отправки документов: $e';
    }
  }

  void dispose() {
    _controller.close();
  }
}
