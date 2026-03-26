import 'package:flutter/material.dart';

import 'announcements_page.dart';
import 'guests_page.dart';
import 'service_requests_page.dart';

class ServicesPage extends StatelessWidget {
  const ServicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final services = const [
      ('Сантехник', 'Протечки, краны, трубы', Icons.plumbing_outlined),
      ('Электрик', 'Розетки, освещение, автоматы', Icons.electrical_services_outlined),
      ('Уборка', 'Подъезд/двор/после ремонта', Icons.cleaning_services_outlined),
      ('Вывоз', 'Мусор, мебель, стройматериалы', Icons.local_shipping_outlined),
      ('Охрана', 'Вопросы безопасности', Icons.security_outlined),
      ('Домофон', 'Ключи, доступ, трубка', Icons.door_front_door_outlined),
    ];

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Сервисы', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: _TopServiceCard(
                    title: 'Объявления',
                    subtitle: 'Новости от УК',
                    icon: Icons.campaign_outlined,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AnnouncementsPage()),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TopServiceCard(
                    title: 'Гости в ЖК',
                    subtitle: 'Оформить пропуск',
                    icon: Icons.badge_outlined,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const GuestsPage()),
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),
            Text('Услуги', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),

            ...services.map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                child: ListTile(
                  leading: Icon(s.$3),
                  title: Text(s.$1),
                  subtitle: Text(s.$2),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // Пока просто переводим на заявки (позже — предзаполним форму категорией)
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ServiceRequestsPage()),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Демо: выбрана услуга “${s.$1}”')),
                    );
                  },
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }
}

class _TopServiceCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _TopServiceCard({
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
              Icon(icon),
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
            ],
          ),
        ),
      ),
    );
  }
}