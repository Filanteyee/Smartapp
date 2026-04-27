import 'package:flutter/material.dart';

import '../services/api_client.dart';
import 'admin_verification_page.dart';
import 'announcements_page.dart';
import 'barrier_page.dart';
import 'guests_page.dart';
import 'payments_page.dart';
import 'profile_page.dart';
import 'service_requests_page.dart';
import 'services_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final ApiClient _api = ApiClient.instance;

  int _index = 0;
  bool _loadingRole = true;
  String _role = 'resident';

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    try {
      if (!_api.isLoggedIn) {
        setState(() { _role = 'resident'; _loadingRole = false; });
        return;
      }
      final res = await _api.get('/auth/me');
      final role = (res.data['role'] ?? 'resident').toString();
      await _api.updateRole(role);
      if (!mounted) return;
      setState(() {
        _role = role;
        _loadingRole = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() { _role = 'resident'; _loadingRole = false; });
    }
  }

  List<Widget> get _pages => [
    _HomeOverviewTab(role: _role),
    const ServiceRequestsPage(),
    const ServicesPage(),
    const PaymentsPage(),
    const ProfilePage(),
  ];

  List<BottomNavigationBarItem> get _items => const [
    BottomNavigationBarItem(
      icon: Icon(Icons.home_outlined),
      label: 'Главная',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.build_outlined),
      label: 'Заявки',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.grid_view_outlined),
      label: 'Сервисы',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.receipt_long_outlined),
      label: 'Платежи',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.person_outline),
      label: 'Профиль',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    if (_loadingRole) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        items: _items,
        type: BottomNavigationBarType.fixed,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }

}

class _HomeOverviewTab extends StatelessWidget {
  final String role;

  const _HomeOverviewTab({required this.role});

  bool get _isAdmin => role == 'admin';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isAdmin ? 'Панель администратора' : 'Главная'),
      ),
      body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 6),
          Text(
            _isAdmin
                ? 'Управление заявками, проверкой документов и основными функциями жилого комплекса'
                : 'Сервис и удобство жилого комплекса',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 18),
          if (_isAdmin) ...[
            Row(
              children: [
                Expanded(
                  child: _TopActionButton(
                    label: 'Все заявки',
                    icon: Icons.assignment_outlined,
                    tonal: false,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ServiceRequestsPage(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TopActionButton(
                    label: 'Проверка',
                    icon: Icons.fact_check_outlined,
                    tonal: true,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminVerificationPage(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _ActionGrid(
              children: [
                _ActionCard(
                  title: 'Управление заявками',
                  subtitle: '',
                  icon: Icons.build_circle_outlined,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ServiceRequestsPage(),
                      ),
                    );
                  },
                ),
                _ActionCard(
                  title: 'Проверка документов',
                  subtitle: '',
                  icon: Icons.verified_user_outlined,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminVerificationPage(),
                      ),
                    );
                  },
                ),
                _ActionCard(
                  title: 'Шлагбаум',
                  subtitle: 'История открытий и имитация IoT',
                  icon: Icons.garage_outlined,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const BarrierPage(),
                      ),
                    );
                  },
                ),
                _ActionCard(
                  title: 'Объявления',
                  subtitle: 'Новости для жителей',
                  icon: Icons.campaign_outlined,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AnnouncementsPage(),
                      ),
                    );
                  },
                ),
                _ActionCard(
                  title: 'Профиль',
                  subtitle: 'Данные текущего администратора',
                  icon: Icons.person_outline,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ProfilePage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: _TopActionButton(
                    label: 'Создать заявку',
                    icon: Icons.add_circle_outline,
                    tonal: true,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ServiceRequestsPage(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TopActionButton(
                    label: 'Сервисы',
                    icon: Icons.grid_view_outlined,
                    tonal: false,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ServicesPage(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _ActionGrid(
              children: [
                _ActionCard(
                  title: 'Объявления',
                  subtitle: 'Новости от УК',
                  icon: Icons.campaign_outlined,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AnnouncementsPage(),
                      ),
                    );
                  },
                ),
                _ActionCard(
                  title: 'Гости в ЖК',
                  subtitle: 'Пропуск и код для доступа',
                  icon: Icons.badge_outlined,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const GuestsPage(),
                      ),
                    );
                  },
                ),
                _ActionCard(
                  title: 'Шлагбаум',
                  subtitle: 'Открыть въезд и посмотреть историю',
                  icon: Icons.garage_outlined,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const BarrierPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    ),
    );
  }
}

class _TopActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool tonal;
  final VoidCallback onTap;

  const _TopActionButton({
    required this.label,
    required this.icon,
    required this.tonal,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final button = tonal
        ? FilledButton.tonalIcon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(
        label,
        maxLines: 2,
        textAlign: TextAlign.center,
      ),
    )
        : FilledButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(
        label,
        maxLines: 2,
        textAlign: TextAlign.center,
      ),
    );

    return SizedBox(
      height: 64,
      child: button,
    );
  }
}

class _ActionGrid extends StatelessWidget {
  final List<Widget> children;

  const _ActionGrid({required this.children});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];

    for (int i = 0; i < children.length; i += 2) {
      final left = children[i];
      final right = i + 1 < children.length ? children[i + 1] : null;

      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: left),
              const SizedBox(width: 12),
              Expanded(child: right ?? const SizedBox()),
            ],
          ),
        ),
      );

      if (i + 2 < children.length) {
        rows.add(const SizedBox(height: 12));
      }
    }

    return Column(children: rows);
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 24),
              const SizedBox(height: 10),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 8),
              const Align(
                alignment: Alignment.bottomRight,
                child: Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),
      ),
    );
  }
}