import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class GuestsPage extends StatefulWidget {
  const GuestsPage({super.key});

  @override
  State<GuestsPage> createState() => _GuestsPageState();
}

class _GuestsPageState extends State<GuestsPage> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _car = TextEditingController();

  final supabase.SupabaseClient _supabase = supabase.Supabase.instance.client;

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
      setState(() {
        _loadingPasses = true;
        _error = null;
      });

      final user = _supabase.auth.currentUser;
      if (user == null) {
        setState(() {
          _passes = [];
          _loadingPasses = false;
        });
        return;
      }

      final rows = await _supabase
          .from('guest_access')
          .select()
          .eq('resident_id', user.id)
          .order('created_at', ascending: false);

      final items = (rows as List)
          .map((row) => _GuestPass.fromMap(
        Map<String, dynamic>.from(row as Map),
      ))
          .toList();

      if (!mounted) return;

      setState(() {
        _passes = items;
        _loadingPasses = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'Ошибка загрузки пропусков: $e';
        _loadingPasses = false;
      });
    }
  }

  Future<void> _pickDateTime({required bool isFrom}) async {
    final now = DateTime.now();
    final initialDate = isFrom
        ? (_from ?? now)
        : (_to ?? _from ?? now);

    final date = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
      initialDate: initialDate,
    );
    if (date == null || !mounted) return;

    final baseTime = isFrom ? (_from ?? now) : (_to ?? _from ?? now);

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(baseTime),
    );
    if (time == null) return;

    final dt = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    setState(() {
      if (isFrom) {
        _from = dt;
        if (_to != null && !_to!.isAfter(_from!)) {
          _to = null;
        }
      } else {
        _to = dt;
      }
    });
  }

  String _generateCode() {
    final ms = DateTime.now().millisecondsSinceEpoch.toString();
    return 'G-${ms.substring(ms.length - 6)}';
  }

  String _fmt(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year.toString();
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$d.$m.$y $h:$min';
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'active':
        return 'Активен';
      case 'used':
        return 'Использован';
      case 'expired':
        return 'Истёк';
      case 'cancelled':
        return 'Отменён';
      default:
        return status;
    }
  }

  Future<void> _createPass() async {
    final name = _name.text.trim();
    final phone = _phone.text.trim();
    final car = _car.text.trim();

    if (name.isEmpty) {
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

    if (!_to!.isAfter(_from!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Время “по” должно быть позже времени “с”')),
      );
      return;
    }

    if (_byCar && car.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Введите номер авто или выключите режим “Гость на авто”'),
        ),
      );
      return;
    }

    final user = _supabase.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Сначала войдите в аккаунт')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final code = _generateCode();

      await _supabase.from('guest_access').insert({
        'resident_id': user.id,
        'guest_name': name,
        'guest_phone': phone.isEmpty ? null : phone,
        'car_number': _byCar ? car : null,
        'access_type': _byCar ? 'car' : 'walk',
        'access_code': code,
        'valid_from': _from!.toIso8601String(),
        'valid_until': _to!.toIso8601String(),
        'status': 'active',
      });

      if (!mounted) return;

      _name.clear();
      _phone.clear();
      _car.clear();

      setState(() {
        _from = null;
        _to = null;
        _byCar = true;
      });

      await _loadPasses();

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Пропуск создан'),
          content: Text(
            'Код: $code\n\n'
                'Гость: $name\n'
                'С: ${_fmt(_from ?? DateTime.now())}\n'
                'По: ${_fmt(_to ?? DateTime.now())}\n'
                '${_byCar ? "Авто: $car" : "Пешком"}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Ок'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка создания пропуска: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _cancelPass(_GuestPass pass) async {
    try {
      await _supabase
          .from('guest_access')
          .update({'status': 'cancelled'}).eq('id', pass.id);

      await _loadPasses();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пропуск отменён')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка отмены пропуска: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Гости в ЖК'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadPasses,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Оформить пропуск',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      TextField(
                        controller: _name,
                        enabled: !_loading,
                        decoration: const InputDecoration(
                          labelText: 'Имя гостя',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _phone,
                        enabled: !_loading,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Телефон (опционально)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        value: _byCar,
                        onChanged: _loading
                            ? null
                            : (v) => setState(() => _byCar = v),
                        title: const Text('Гость на авто'),
                      ),
                      if (_byCar) ...[
                        const SizedBox(height: 8),
                        TextField(
                          controller: _car,
                          enabled: !_loading,
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
                              onPressed: _loading
                                  ? null
                                  : () => _pickDateTime(isFrom: true),
                              icon: const Icon(Icons.schedule),
                              label: Text(
                                _from == null
                                    ? 'С: выбрать'
                                    : 'С: ${_fmt(_from!)}',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _loading || _from == null
                                  ? null
                                  : () => _pickDateTime(isFrom: false),
                              icon: const Icon(Icons.schedule_outlined),
                              label: Text(
                                _to == null
                                    ? 'По: выбрать'
                                    : 'По: ${_fmt(_to!)}',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _loading ? null : _createPass,
                          child: _loading
                              ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                              : const Text('Создать пропуск'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Активные и прошлые пропуска',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              if (_loadingPasses)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _loadPasses,
                          child: const Text('Повторить'),
                        ),
                      ],
                    ),
                  ),
                )
              else if (_passes.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Пропусков пока нет'),
                    ),
                  )
                else
                  ..._passes.map(
                        (pass) => Card(
                      child: ListTile(
                        leading: Icon(
                          pass.accessType == 'car'
                              ? Icons.directions_car
                              : Icons.directions_walk,
                        ),
                        title: Text(pass.guestName),
                        subtitle: Text(
                          'Код: ${pass.accessCode}\n'
                              'С: ${_fmt(pass.validFrom)}\n'
                              'По: ${_fmt(pass.validUntil)}\n'
                              'Статус: ${_statusLabel(pass.status)}'
                              '${pass.carNumber != null && pass.carNumber!.isNotEmpty ? "\nАвто: ${pass.carNumber}" : ""}',
                        ),
                        isThreeLine: true,
                        trailing: pass.status == 'active'
                            ? PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'cancel') {
                              _cancelPass(pass);
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'cancel',
                              child: Text('Отменить'),
                            ),
                          ],
                        )
                            : null,
                      ),
                    ),
                  ),
              const SizedBox(height: 12),
              const Text(
                'Потом можно добавить QR-код, экран охраны и автоматическую проверку кода.',
              ),
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
  final DateTime createdAt;

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
    required this.createdAt,
  });

  factory _GuestPass.fromMap(Map<String, dynamic> map) {
    return _GuestPass(
      id: (map['id'] ?? '').toString(),
      guestName: (map['guest_name'] ?? '').toString(),
      guestPhone: map['guest_phone']?.toString(),
      carNumber: map['car_number']?.toString(),
      accessType: (map['access_type'] ?? 'walk').toString(),
      accessCode: (map['access_code'] ?? '').toString(),
      validFrom: DateTime.tryParse((map['valid_from'] ?? '').toString()) ??
          DateTime.now(),
      validUntil: DateTime.tryParse((map['valid_until'] ?? '').toString()) ??
          DateTime.now(),
      status: (map['status'] ?? 'active').toString(),
      createdAt: DateTime.tryParse((map['created_at'] ?? '').toString()) ??
          DateTime.now(),
    );
  }
}