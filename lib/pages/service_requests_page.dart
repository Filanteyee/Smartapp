import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../widgets/create_request_sheet.dart';

class ServiceRequestsPage extends StatefulWidget {
  const ServiceRequestsPage({super.key});

  @override
  State<ServiceRequestsPage> createState() => _ServiceRequestsPageState();
}

class _ServiceRequestsPageState extends State<ServiceRequestsPage> {
  final supabase.SupabaseClient _supabase = supabase.Supabase.instance.client;

  String _query = '';
  String? _filter; // null = все
  bool _loading = true;
  String? _error;
  List<_RequestItem> _requests = [];

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      final user = _supabase.auth.currentUser;
      if (user == null) {
        setState(() {
          _requests = [];
          _loading = false;
        });
        return;
      }

      final profile = await _supabase
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .maybeSingle();

      final role = (profile?['role'] ?? 'resident').toString();

      dynamic query = _supabase.from('service_requests').select('''
            id,
            user_id,
            category,
            description,
            status,
            created_at,
            updated_at,
            request_photos (
              id,
              file_path
            )
          ''');

      if (role != 'admin') {
        query = query.eq('user_id', user.id);
      }

      final rows = await query.order('created_at', ascending: false);

      final items = (rows as List)
          .map((row) => _RequestItem.fromMap(
        Map<String, dynamic>.from(row as Map),
      ))
          .toList();

      if (!mounted) return;

      setState(() {
        _requests = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'Ошибка загрузки заявок: $e';
        _loading = false;
      });
    }
  }

  Future<void> _changeStatus(_RequestItem request, String status) async {
    try {
      await _supabase
          .from('service_requests')
          .update({'status': status}).eq('id', request.id);

      await _loadRequests();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Статус заявки обновлён')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка обновления статуса: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _requests.where((r) {
      final q = _query.trim().toLowerCase();
      final matchesQuery = q.isEmpty ||
          r.category.toLowerCase().contains(q) ||
          r.description.toLowerCase().contains(q);

      final matchesFilter = _filter == null || r.status == _filter;
      return matchesQuery && matchesFilter;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Заявки'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                onChanged: (value) => setState(() => _query = value),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Поиск по заявкам…',
                ),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SegmentedButton<String?>(
                segments: const [
                  ButtonSegment(value: null, label: Text('Все')),
                  ButtonSegment(value: 'new', label: Text('Новые')),
                  ButtonSegment(value: 'in_progress', label: Text('В работе')),
                  ButtonSegment(value: 'done', label: Text('Выполнено')),
                ],
                selected: {_filter},
                onSelectionChanged: (set) => setState(() => _filter = set.first),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? _RequestsError(
                message: _error!,
                onRetry: _loadRequests,
              )
                  : filtered.isEmpty
                  ? const _EmptyRequests()
                  : RefreshIndicator(
                onRefresh: _loadRequests,
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) =>
                  const SizedBox(height: 12),
                  itemBuilder: (context, i) => _RequestCard(
                    request: filtered[i],
                    onStatusChanged: (status) =>
                        _changeStatus(filtered[i], status),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            showDragHandle: true,
            builder: (_) => const CreateRequestSheet(),
          );

          await _loadRequests();
        },
        icon: const Icon(Icons.add),
        label: const Text('Создать'),
      ),
    );
  }
}

class _RequestItem {
  final String id;
  final String userId;
  final String category;
  final String description;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<String> photoPaths;

  const _RequestItem({
    required this.id,
    required this.userId,
    required this.category,
    required this.description,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.photoPaths,
  });

  factory _RequestItem.fromMap(Map<String, dynamic> map) {
    final photosRaw = map['request_photos'];
    final photoPaths = <String>[];

    if (photosRaw is List) {
      for (final item in photosRaw) {
        final photo = Map<String, dynamic>.from(item as Map);
        final path = (photo['file_path'] ?? '').toString();
        if (path.isNotEmpty) {
          photoPaths.add(path);
        }
      }
    }

    return _RequestItem(
      id: (map['id'] ?? '').toString(),
      userId: (map['user_id'] ?? '').toString(),
      category: (map['category'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
      status: (map['status'] ?? 'new').toString(),
      createdAt: DateTime.tryParse((map['created_at'] ?? '').toString()) ??
          DateTime.now(),
      updatedAt: DateTime.tryParse((map['updated_at'] ?? '').toString()),
      photoPaths: photoPaths,
    );
  }
}

class _RequestCard extends StatelessWidget {
  final _RequestItem request;
  final ValueChanged<String> onStatusChanged;

  const _RequestCard({
    required this.request,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    request.category,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                _StatusChip(status: request.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(request.description),
            const SizedBox(height: 12),
            _StatusTimeline(status: request.status),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  _formatDate(request.createdAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Spacer(),
                PopupMenuButton<String>(
                  tooltip: 'Изменить статус',
                  onSelected: onStatusChanged,
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'new',
                      child: Text('Новая'),
                    ),
                    PopupMenuItem(
                      value: 'in_progress',
                      child: Text('В работе'),
                    ),
                    PopupMenuItem(
                      value: 'done',
                      child: Text('Выполнено'),
                    ),
                  ],
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.more_horiz),
                      SizedBox(width: 6),
                      Text('Статус'),
                    ],
                  ),
                ),
              ],
            ),
            if (request.photoPaths.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 92,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: request.photoPaths.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, i) {
                    final publicUrl = supabase.Supabase.instance.client.storage
                        .from('request-photos')
                        .getPublicUrl(request.photoPaths[i]);

                    return ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(
                        publicUrl,
                        width: 92,
                        height: 92,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 92,
                          height: 92,
                          alignment: Alignment.center,
                          child: const Icon(Icons.broken_image),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(dt.day)}.${two(dt.month)}.${dt.year}  ${two(dt.hour)}:${two(dt.minute)}';
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  String _text(String value) {
    switch (value) {
      case 'new':
        return 'Новая';
      case 'in_progress':
        return 'В работе';
      case 'done':
        return 'Выполнено';
      default:
        return value;
    }
  }

  IconData _icon(String value) {
    switch (value) {
      case 'new':
        return Icons.fiber_new;
      case 'in_progress':
        return Icons.timelapse;
      case 'done':
        return Icons.check_circle;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(_icon(status), size: 18),
      label: Text(_text(status)),
    );
  }
}

class _StatusTimeline extends StatelessWidget {
  final String status;

  const _StatusTimeline({required this.status});

  bool get _step1 => true;
  bool get _step2 => status == 'in_progress' || status == 'done';
  bool get _step3 => status == 'done';

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final muted = Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5);

    Widget dot(bool active) => Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? primary : muted,
      ),
    );

    Widget line(bool active) => Expanded(
      child: Container(
        height: 2,
        color: active ? primary : muted,
      ),
    );

    TextStyle labelStyle(bool active) => TextStyle(
      fontSize: 12,
      color: active ? primary : muted,
      fontWeight: active ? FontWeight.w600 : FontWeight.w400,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            dot(_step1),
            line(_step2),
            dot(_step2),
            line(_step3),
            dot(_step3),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(child: Text('Создано', style: labelStyle(_step1))),
            Expanded(
              child: Center(
                child: Text('В работе', style: labelStyle(_step2)),
              ),
            ),
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: Text('Готово', style: labelStyle(_step3)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _EmptyRequests extends StatelessWidget {
  const _EmptyRequests();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Заявок нет. Нажми “Создать”.'),
    );
  }
}

class _RequestsError extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _RequestsError({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 42),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }
}