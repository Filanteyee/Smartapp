import 'package:flutter/material.dart';

class MonitoringPage extends StatefulWidget {
  const MonitoringPage({super.key});

  @override
  State<MonitoringPage> createState() => _MonitoringPageState();
}

class _MonitoringPageState extends State<MonitoringPage> {
  int _segment = 0; // 0 = датчики, 1 = аварии

  // ✅ Явно заданные типы (иначе пустой const [] = List<Never> и будет ругаться)
  final List<Map<String, Object>> _sensors = const [
    {
      'title': 'Температура',
      'value': '22°C',
      'status': 'ok',
      'icon': Icons.thermostat,
    },
    {
      'title': 'Дым',
      'value': 'Норма',
      'status': 'ok',
      'icon': Icons.smoke_free,
    },
    {
      'title': 'Протечка',
      'value': 'Норма',
      'status': 'ok',
      'icon': Icons.water_drop,
    },
  ];

  final List<Map<String, Object>> _emergencies = const [
    // Пример:
    // {
    //   'title': 'Протечка на 3 этаже',
    //   'details': 'Подъезд 1, кв. 32',
    //   'time': '10:24',
    //   'status': 'active',
    // },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мониторинг'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SegmentedButton<int>(
                segments: const [
                  ButtonSegment(
                    value: 0,
                    label: Text('Датчики'),
                    icon: Icon(Icons.sensors),
                  ),
                  ButtonSegment(
                    value: 1,
                    label: Text('Аварии'),
                    icon: Icon(Icons.warning_amber),
                  ),
                ],
                selected: {_segment},
                onSelectionChanged: (set) =>
                    setState(() => _segment = set.first),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _segment == 0
                    ? _SensorsList(sensors: _sensors)
                    : _EmergenciesList(items: _emergencies),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SensorsList extends StatelessWidget {
  final List<Map<String, Object>> sensors;
  const _SensorsList({required this.sensors});

  IconData _statusIcon(String status) {
    switch (status) {
      case 'warning':
        return Icons.error_outline;
      case 'danger':
        return Icons.dangerous;
      default:
        return Icons.check_circle_outline;
    }
  }

  String _statusText(String status) {
    switch (status) {
      case 'warning':
        return 'Внимание';
      case 'danger':
        return 'Опасно';
      default:
        return 'Норма';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      key: const ValueKey('sensors'),
      padding: const EdgeInsets.all(16),
      itemCount: sensors.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final s = sensors[i];
        final status = (s['status'] as String?) ?? 'ok';

        return Card(
          child: ListTile(
            leading: Icon(s['icon'] as IconData),
            title: Text(s['title'] as String),
            subtitle: Text(s['value'] as String),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_statusIcon(status)),
                const SizedBox(width: 8),
                Text(_statusText(status)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EmergenciesList extends StatelessWidget {
  final List<Map<String, Object>> items;
  const _EmergenciesList({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        key: ValueKey('empty'),
        child: Text('Активных аварий нет (демо).'),
      );
    }

    return ListView.separated(
      key: const ValueKey('emergencies'),
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final e = items[i];

        return Card(
          child: ListTile(
            leading: const Icon(Icons.warning_amber),
            title: Text(e['title'] as String),
            subtitle: Text('${e['details']} • ${e['time']}'),
            trailing: const Chip(label: Text('ACTIVE')),
          ),
        );
      },
    );
  }
}