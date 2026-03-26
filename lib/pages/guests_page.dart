import 'package:flutter/material.dart';

class GuestsPage extends StatefulWidget {
  const GuestsPage({super.key});

  @override
  State<GuestsPage> createState() => _GuestsPageState();
}

class _GuestsPageState extends State<GuestsPage> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _car = TextEditingController();

  DateTime? _from;
  DateTime? _to;
  bool _byCar = true;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _car.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime({required bool isFrom}) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
      initialDate: now,
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now),
    );
    if (time == null) return;

    final dt = DateTime(date.year, date.month, date.day, time.hour, time.minute);

    setState(() {
      if (isFrom) {
        _from = dt;
        if (_to != null && _to!.isBefore(_from!)) _to = null;
      } else {
        _to = dt;
      }
    });
  }

  void _createPass() {
    if (_name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите имя гостя')),
      );
      return;
    }
    if (_from == null || _to == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите время “с” и “по”')),
      );
      return;
    }
    if (_byCar && _car.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите номер авто или переключите “Пешком”')),
      );
      return;
    }

    final code = _generateCode();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Пропуск создан (демо)'),
        content: Text(
          'Код: $code\n\n'
              'Гость: ${_name.text.trim()}\n'
              'С: ${_fmt(_from!)}\n'
              'По: ${_fmt(_to!)}\n'
              '${_byCar ? "Авто: ${_car.text.trim()}" : "Пешком"}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Ок'),
          ),
        ],
      ),
    );
  }

  String _generateCode() {
    final ms = DateTime.now().millisecondsSinceEpoch.toString();
    return 'G-${ms.substring(ms.length - 6)}';
  }

  String _fmt(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$d.$m $h:$min';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Гости в ЖК'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Оформить пропуск', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    TextField(
                      controller: _name,
                      decoration: const InputDecoration(
                        labelText: 'Имя гостя',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Телефон (опционально)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    SwitchListTile(
                      value: _byCar,
                      onChanged: (v) => setState(() => _byCar = v),
                      title: const Text('Гость на авто'),
                    ),
                    if (_byCar) ...[
                      const SizedBox(height: 8),
                      TextField(
                        controller: _car,
                        decoration: const InputDecoration(
                          labelText: 'Номер авто',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _pickDateTime(isFrom: true),
                            icon: const Icon(Icons.schedule),
                            label: Text(_from == null ? 'С: выбрать' : 'С: ${_fmt(_from!)}'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _from == null ? null : () => _pickDateTime(isFrom: false),
                            icon: const Icon(Icons.schedule_outlined),
                            label: Text(_to == null ? 'По: выбрать' : 'По: ${_fmt(_to!)}'),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _createPass,
                        child: const Text('Создать пропуск'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),
            const Text('Потом добавим: QR-код, список активных пропусков и проверку охраной.'),
          ],
        ),
      ),
    );
  }
}