import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../services/auth_service.dart';
import 'login_page.dart';
import 'ownership_verification_page.dart';
import 'register_flow_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  String _roleLabel(String role) {
    switch (role) {
      case 'admin':
        return 'Администратор';
      case 'resident':
        return 'Житель';
      default:
        return 'Не указано';
    }
  }

  String _verificationLabel(String status) {
    switch (status) {
      case 'pending':
        return 'На проверке';
      case 'approved':
        return 'Подтверждено';
      case 'rejected':
        return 'Отклонено';
      case 'not_submitted':
      default:
        return 'Не отправлено';
    }
  }

  String _roleDescription(String role, String verificationStatus) {
    if (role == 'admin') {
      return 'Права администратора: просмотр заявок, смена статусов и доступ к управлению системой.';
    }

    if (verificationStatus == 'approved') {
      return 'Ваш статус подтверждён. Доступен основной функционал приложения.';
    }

    if (verificationStatus == 'pending') {
      return 'Ваши документы находятся на проверке. Пока доступен базовый функционал.';
    }

    if (verificationStatus == 'rejected') {
      return 'Проверка была отклонена. Вы можете отправить документы повторно.';
    }

    return 'Вы ещё не подтверждены. Пока доступен базовый функционал.';
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();

    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<supabase.User?>(
          stream: auth.authStateChanges,
          builder: (context, snapshot) {
            final user = snapshot.data;

            if (user == null) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Профиль',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const CircleAvatar(
                            radius: 34,
                            child: Icon(Icons.person, size: 34),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Вы не вошли',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Войдите или зарегистрируйтесь, чтобы пользоваться профилем',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const LoginPage(),
                                  ),
                                );
                              },
                              child: const Text('Войти'),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const RegisterFlowPage(),
                                  ),
                                );
                              },
                              child: const Text('Регистрация'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }

            return FutureBuilder<Map<String, dynamic>?>(
              future: auth.getCurrentUserProfile(),
              builder: (context, profileSnapshot) {
                if (profileSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final data = profileSnapshot.data ?? <String, dynamic>{};

                final role = (data['role'] ?? 'resident').toString();
                final verificationStatus =
                (data['verification_status'] ?? 'not_submitted').toString();

                final fullName =
                (data['full_name'] ?? user.email ?? 'Пользователь')
                    .toString();

                final phone = (data['phone'] ?? '').toString();

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      'Профиль',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const CircleAvatar(
                              radius: 34,
                              child: Icon(Icons.person, size: 34),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              fullName,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 6),
                            Text(user.email ?? ''),
                            const SizedBox(height: 6),
                            if (phone.isNotEmpty) Text(phone),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.verified_user_outlined),
                            title: const Text('Роль'),
                            subtitle: Text(_roleLabel(role)),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.pending_actions_outlined),
                            title: const Text('Статус проверки'),
                            subtitle: Text(_verificationLabel(verificationStatus)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (role != 'admin' && verificationStatus != 'approved')
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                const OwnershipVerificationPage(),
                              ),
                            );
                          },
                          child: Text(
                            verificationStatus == 'rejected'
                                ? 'Отправить повторно'
                                : 'Подтвердить статус',
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          _roleDescription(role, verificationStatus),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.tonal(
                        onPressed: () async {
                          await auth.signOut();
                        },
                        child: const Text('Выйти'),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}