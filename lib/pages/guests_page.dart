import 'package:flutter/material.dart';

import '../services/api_client.dart';

class GuestsPage extends StatefulWidget {
  const GuestsPage({super.key});

  @override
  State<GuestsPage> createState() => _GuestsPageState();
}

class _GuestsPageState extends State<GuestsPage> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _car = TextEditingController();
  final ApiClient _api = ApiClient.instance;

  DateTime? _from;
  DateTime? _to;
  bool _byCar = true;
  bool _loading = false;
  bool _loadingPasses = true;
  String? _error;
  List<_GuestPass> _passes = [];

  @override
  void initState() {
    super.initState();
    _loadPasses();
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _car.dispose();
    super.dispose();
  }

  Future<void> _loadPasses() async {
    try {
      setState(() { _loadingPasses = true; _error = null; });
      if (!_api.isLoggedIn) {
        setState(() { _passes = []; _loadingPasses = false; });
        return;
      }
      final res = await _api.get('/guest-access');
      final items = (res.data as List)
          .map((row) => _GuestPass.fromMap(Map<String, dynamic>.from(row as Map)))
          .toList();
      if (!mounted) return;
      setState(() { _passes = items; _loadingPasses = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = 'Ошибка загрузки пропусков: $e'; _loadingPasses = false; });
    }
  }

  Future<void> _pickDateTime({required bool isFrom}) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
      initialDate: isFrom ? (_from ?? now) : (_to ?? _from ?? now),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(isFrom ? (_from ?? now) : (_to ?? _from ?? now)),
    );
    if (time == null) return;

    final dt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      if (isFrom) {
        _from = dt;
        if (_to != null && !_to!.isAfter(_from!)) _to = null;
      } else {
        _to = dt;
      }
    });
  }

  String _fmt(DateTime dt) {
    String p(int n) => n.toString().padLeft(2, '0');
    return '${p(dt.day)}.${p(dt.month)}.${dt.year} ${p(dt.hour)}:${p(dt.minute)}';
  }

  String _statusLabel(String status) => switch (status) {
    'active' => 'Активен',
    'used' => 'Использован',
    'expired' => 'Истёк',
    'cancelled' => 'Отменён',
    _ => status,
  };

  Future<void> _createPass() async {
    final name = _name.text.trim();
    if (name.isEmpty) { _snack('Введите имя гостя'); return; }
    if (_from == null || _to == null) { _snack('Выберите время "с" и "по"'); return; }
    if (!_to!.isAfter(_from!)) { _snack('Время "по" должно быть позже времени "с"'); return; }
    if (_byCar && _car.text.trim().isEmpty) { _snack('Введите номер авто или выключите режим "Гость на авто"'); return; }

    setState(() => _loading = true);

    try {
      final res = await _api.post('/guest-access', data: {
        'guest_name': name,
        'guest_phone': _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        'car_number': _byCar ? _car.text.trim() : null,
        'access_type': _byCar ? 'car' : 'walk',
        'valid_from': _from!.toUtc().toIso8601String(),
        'valid_until': _to!.toUtc().toIso8601String(),
      });

      final code = res.data['access_code'] as String;
      _name.clear(); _phone.clear(); _car.clear();
      setState(() { _from = null; _to = null; _byCar = true; });
      await _loadPasses();

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Пропуск создан'),
          content: Text('Код: $code\n\nГость: $name'),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Ок'))],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _snack('Ошибка создания пропуска: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _cancelPass(_GuestPass pass) async {
    try {
      await _api.put('/guest-access/${pass.id}/cancel');
      await _loadPasses();
      if (!mounted) return;
      _snack('Пропуск отменён');
    } catch (e) {
      if (!mounted) return;
      _snack('Ошибка отмены пропуска: $e');
    }
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Гости в ЖК')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadPasses,
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
                      TextField(controller: _name, enabled: !_loading, decoration: const InputDecoration(labelText: 'Имя гостя', border: OutlineInputBorder())),
                      const SizedBox(height: 12),
                      TextField(controller: _phone, enabled: !_loading, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Телефон (опционально)', border: OutlineInputBorder())),
                      const SizedBox(height: 12),
                      SwitchListTile(value: _byCar, onChanged: _loading ? null : (v) => setState(() => _byCar = v), title: const Text('Гость на авто')),
                      if (_byCar) ...[
                        const SizedBox(height: 8),
                        TextField(controller: _car, enabled: !_loading, decoration: const InputDecoration(labelText: 'Номер авто', border: OutlineInputBorder())),
                      ],
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _loading ? null : () => _pickDateTime(isFrom: true),
                          icon: const Icon(Icons.schedule),
                          label: Text(_from == null ? 'С: выбрать' : 'С: ${_fmt(_from!)}'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _loading || _from == null ? null : () => _pickDateTime(isFrom: false),
                          icon: const Icon(Icons.schedule_outlined),
                          label: Text(_to == null ? 'По: выбрать' : 'По: ${_fmt(_to!)}'),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _loading ? null : _createPass,
                          child: _loading
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Создать пропуск'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text('Активные и прошлые пропуска', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              if (_loadingPasses)
                const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))
              else if (_error != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(children: [
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      FilledButton(onPressed: _loadPasses, child: const Text('Повторить')),
                    ]),
                  ),
                )
              else if (_passes.isEmpty)
                const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('Пропусков пока нет')))
              else
                ..._passes.map((pass) => Card(
                  child: ListTile(
                    leading: Icon(pass.accessType == 'car' ? Icons.directions_car : Icons.directions_walk),
                    title: Text(pass.guestName),
                    subtitle: Text(
                      'Код: ${pass.accessCode}\nС: ${_fmt(pass.validFrom)}\nПо: ${_fmt(pass.validUntil)}\nСтатус: ${_statusLabel(pass.status)}'
                      '${pass.carNumber != null && pass.carNumber!.isNotEmpty ? "\nАвто: ${pass.carNumber}" : ""}',
                    ),
                    isThreeLine: true,
                    trailing: pass.status == 'active'
                        ? PopupMenuButton<String>(
                      onSelected: (v) { if (v == 'cancel') _cancelPass(pass); },
                      itemBuilder: (_) => const [PopupMenuItem(value: 'cancel', child: Text('Отменить'))],
                    )
                        : null,
                  ),
                )),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuestPass {
  final String id;
  final String guestName;
  final String? guestPhone;
  final String? carNumber;
  final String accessType;
  final String accessCode;
  final DateTime validFrom;
  final DateTime validUntil;
  final String status;

  const _GuestPass({
    required this.id,
    required this.guestName,
    required this.guestPhone,
    required this.carNumber,
    required this.accessType,
    required this.accessCode,
    required this.validFrom,
    required this.validUntil,
    required this.status,
  });

  factory _GuestPass.fromMap(Map<String, dynamic> map) => _GuestPass(
    id: (map['id'] ?? '').toString(),
    guestName: (map['guest_name'] ?? '').toString(),
    guestPhone: map['guest_phone']?.toString(),
    carNumber: map['car_number']?.toString(),
    accessType: (map['access_type'] ?? 'walk').toString(),
    accessCode: (map['access_code'] ?? '').toString(),
    validFrom: DateTime.tryParse((map['valid_from'] ?? '').toString()) ?? DateTime.now(),
    validUntil: DateTime.tryParse((map['valid_until'] ?? '').toString()) ?? DateTime.now(),
    status: (map['status'] ?? 'active').toString(),
  );
}
