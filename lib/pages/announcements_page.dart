import 'package:flutter/material.dart';

class AnnouncementsPage extends StatelessWidget {
  const AnnouncementsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final items = const [
      ('Важно', 'Отключение воды завтра 10:00–14:00', 'Сегодня', true),
      ('Работы', 'Проверка лифтов в доме 8', 'Вчера', false),
      ('Новости', 'Добавили сервис “Гости в ЖК” (демо)', '2 дня назад', false),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Объявления'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final title = items[i].$1;
          final text = items[i].$2;
          final time = items[i].$3;
          final important = items[i].$4;

          return Card(
            child: ListTile(
              leading: Icon(important ? Icons.priority_high : Icons.campaign_outlined),
              title: Text(title),
              subtitle: Text('$text\n$time'),
              isThreeLine: true,
              trailing: important ? const Chip(label: Text('Важно')) : null,
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  showDragHandle: true,
                  builder: (_) => Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 10),
                        Text(text),
                        const SizedBox(height: 10),
                        Text(time, style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}