import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'login_page.dart';
import 'ownership_verification_page.dart';
import 'register_flow_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  String _roleLabel(String role) {
    switch (role) {
      case 'owner':
        return 'Владелец';
      case 'tenant':
        return 'Арендатор';
      default:
        return 'Не подтверждён';
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
      default:
        return 'Не отправлено';
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();

    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<User?>(
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
                final data = profileSnapshot.data ?? {};
                final role = (data['residentRole'] ?? 'unverified').toString();
                final verificationStatus =
                (data['verificationStatus'] ?? 'not_submitted').toString();

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
                              data['fullName'] ?? user.displayName ?? 'Пользователь',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 6),
                            Text(user.email ?? ''),
                            const SizedBox(height: 6),
                            if ((data['phone'] ?? '').toString().isNotEmpty)
                              Text(data['phone']),
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
                    if (role == 'unverified' || verificationStatus != 'approved')
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const OwnershipVerificationPage(),
                              ),
                            );
                          },
                          child: const Text('Подтвердить статус'),
                        ),
                      ),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: role == 'owner'
                            ? const Text(
                          'Права владельца: полный доступ к платежам, гостям, документам и управлению квартирой.',
                        )
                            : role == 'tenant'
                            ? const Text(
                          'Права арендатора: доступ к заявкам, объявлениям, сервисам. Ограниченный доступ к разделам собственника.',
                        )
                            : const Text(
                          'Вы ещё не подтверждены. Пока доступен базовый функционал.',
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