import 'package:flutter/material.dart';

import 'announcements_page.dart';
import 'guests_page.dart';
import 'payments_page.dart';
import 'service_requests_page.dart';
import 'services_page.dart';
import 'profile_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _index = 0;

  final _pages = [
    const _HomeOverviewTab(),
    ServiceRequestsPage(),
    ServicesPage(),
    PaymentsPage(),
    ProfilePage(),
  ];

  final _items = const [
    BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Главная'),
    BottomNavigationBarItem(icon: Icon(Icons.build_outlined), label: 'Заявки'),
    BottomNavigationBarItem(icon: Icon(Icons.grid_view_outlined), label: 'Сервисы'),
    BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), label: 'Платежи'),
    BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Профиль'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titleFor(_index)),
      ),
      body: _pages[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        items: _items,
        type: BottomNavigationBarType.fixed,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }

  String _titleFor(int index) {
    switch (index) {
      case 0:
        return 'Главная';
      case 1:
        return 'Заявки';
      case 2:
        return 'Сервисы';
      case 3:
        return 'Платежи';
      case 4:
        return 'Профиль';
      default:
        return 'Smart ЖК';
    }
  }
}

class _HomeOverviewTab extends StatelessWidget {
  const _HomeOverviewTab();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Smart ЖК',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 6),
          Text(
            'Сервис и удобство жилого комплекса',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ServiceRequestsPage()),
                    );
                  },
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Создать заявку'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ServicesPage()),
                    );
                  },
                  icon: const Icon(Icons.grid_view_outlined),
                  label: const Text('Сервисы'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _ActionCard(
                  title: 'Объявления',
                  subtitle: 'Новости от УК',
                  icon: Icons.campaign_outlined,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => AnnouncementsPage()),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionCard(
                  title: 'Гости в ЖК',
                  subtitle: 'Пропуск/код',
                  icon: Icons.badge_outlined,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => GuestsPage()),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
          child: Row(
            children: [
              Icon(icon, size: 26),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 4),
                    Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}