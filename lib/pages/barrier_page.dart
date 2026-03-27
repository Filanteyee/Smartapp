import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class BarrierPage extends StatefulWidget {
  const BarrierPage({super.key});

  @override
  State<BarrierPage> createState() => _BarrierPageState();
}

class _BarrierPageState extends State<BarrierPage> {
  final supabase.SupabaseClient _supabase = supabase.Supabase.instance.client;

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
      setState(() {
        _loadingLogs = true;
        _error = null;
      });

      final user = _supabase.auth.currentUser;
      if (user == null) {
        setState(() {
          _logs = [];
          _loadingLogs = false;
        });
        return;
      }

      final data = await _supabase
          .from('barrier_logs')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      if (!mounted) return;

      setState(() {
        _logs = List<Map<String, dynamic>>.from(data);
        _loadingLogs = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'Ошибка: $e';
        _loadingLogs = false;
      });
    }
  }

  Future<void> _openBarrier() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Сначала войдите в аккаунт')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      await _supabase.from('barrier_logs').insert({
        'user_id': user.id,
        'action': 'open_barrier',
        'result': 'success',
        'source': 'resident',
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Шлагбаум открыт 🚗')),
      );

      await _loadLogs();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  String _formatDate(String date) {
    final dt = DateTime.parse(date).toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(dt.day)}.${two(dt.month)}.${dt.year} ${two(dt.hour)}:${two(dt.minute)}';
  }

  String _actionLabel(String action) {
    switch (action) {
      case 'open_barrier':
        return 'Шлагбаум открыт';
      case 'open_gate':
        return 'Ворота открыты';
      default:
        return action;
    }
  }

  String _resultLabel(String result) {
    switch (result) {
      case 'success':
        return 'Успешно';
      case 'denied':
        return 'Отклонено';
      default:
        return result;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Шлагбаум'),
      ),
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
                label: Text(
                  _loading ? 'Открываем...' : 'Открыть шлагбаум',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'История',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _loadingLogs
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                  ),
                ),
              )
                  : _logs.isEmpty
                  ? const Center(child: Text('Пока нет действий'))
                  : RefreshIndicator(
                onRefresh: _loadLogs,
                child: ListView.builder(
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    final log = _logs[index];
                    final action =
                    (log['action'] ?? '').toString();
                    final result =
                    (log['result'] ?? '').toString();
                    final createdAt =
                    (log['created_at'] ?? '').toString();

                    return Card(
                      child: ListTile(
                        leading: Icon(
                          result == 'success'
                              ? Icons.check_circle
                              : Icons.cancel,
                        ),
                        title: Text(_actionLabel(action)),
                        subtitle: Text(
                          '${_resultLabel(result)}\n${_formatDate(createdAt)}',
                        ),
                        isThreeLine: true,
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