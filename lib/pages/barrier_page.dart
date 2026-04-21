import 'package:flutter/material.dart';

import '../services/api_client.dart';

class BarrierPage extends StatefulWidget {
  const BarrierPage({super.key});

  @override
  State<BarrierPage> createState() => _BarrierPageState();
}

class _BarrierPageState extends State<BarrierPage> {
  final ApiClient _api = ApiClient.instance;

  bool _loading = false;
  bool _loadingLogs = true;
  String? _error;
  List<Map<String, dynamic>> _logs = [];

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    try {
      setState(() { _loadingLogs = true; _error = null; });
      if (!_api.isLoggedIn) {
        setState(() { _logs = []; _loadingLogs = false; });
        return;
      }
      final res = await _api.get('/barrier-logs');
      if (!mounted) return;
      setState(() {
        _logs = (res.data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _loadingLogs = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = 'Ошибка: $e'; _loadingLogs = false; });
    }
  }

  Future<void> _openBarrier() async {
    setState(() => _loading = true);
    try {
      await _api.post('/barrier-logs/open');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Шлагбаум открыт')));
      await _loadLogs();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatDate(String date) {
    final dt = DateTime.parse(date).toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(dt.day)}.${two(dt.month)}.${dt.year} ${two(dt.hour)}:${two(dt.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Шлагбаум')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 80,
              child: FilledButton.icon(
                onPressed: _loading ? null : _openBarrier,
                icon: const Icon(Icons.garage),
                label: Text(_loading ? 'Открываем...' : 'Открыть шлагбаум', style: const TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(height: 20),
            const Align(alignment: Alignment.centerLeft, child: Text('История', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            const SizedBox(height: 10),
            Expanded(
              child: _loadingLogs
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(child: Padding(padding: const EdgeInsets.all(16), child: Text(_error!, textAlign: TextAlign.center)))
                  : _logs.isEmpty
                  ? const Center(child: Text('Пока нет действий'))
                  : RefreshIndicator(
                onRefresh: _loadLogs,
                child: ListView.builder(
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    final log = _logs[index];
                    final direction = (log['direction'] ?? '').toString();
                    final notes = (log['notes'] ?? '').toString();
                    final createdAt = (log['created_at'] ?? '').toString();

                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.check_circle),
                        title: Text(direction == 'in' ? 'Въезд' : direction == 'out' ? 'Выезд' : 'Открытие'),
                        subtitle: Text('${notes.isNotEmpty ? "$notes\n" : ""}${createdAt.isNotEmpty ? _formatDate(createdAt) : ""}'),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
