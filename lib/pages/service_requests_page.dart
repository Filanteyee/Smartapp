import 'dart:io';

import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/app_state_scope.dart';
import '../widgets/create_request_sheet.dart';

class ServiceRequestsPage extends StatefulWidget {
  const ServiceRequestsPage({super.key});

  @override
  State<ServiceRequestsPage> createState() => _ServiceRequestsPageState();
}

class _ServiceRequestsPageState extends State<ServiceRequestsPage> {
  String _query = '';
  RequestStatus? _filter; // null = все

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);

    final filtered = state.requests.where((r) {
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
                onChanged: (v) => setState(() => _query = v),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Поиск по заявкам…',
                ),
              ),
            ),

            const SizedBox(height: 10),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SegmentedButton<RequestStatus?>(
                segments: const [
                  ButtonSegment(value: null, label: Text('Все')),
                  ButtonSegment(value: RequestStatus.newRequest, label: Text('Новые')),
                  ButtonSegment(value: RequestStatus.inProgress, label: Text('В работе')),
                  ButtonSegment(value: RequestStatus.done, label: Text('Выполнено')),
                ],
                selected: {_filter},
                onSelectionChanged: (set) => setState(() => _filter = set.first),
              ),
            ),

            const SizedBox(height: 12),

            Expanded(
              child: filtered.isEmpty
                  ? const _EmptyRequests()
                  : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) => _RequestCard(request: filtered[i]),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          builder: (_) => const CreateRequestSheet(),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Создать'),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final ServiceRequest request;
  const _RequestCard({required this.request});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок + статус
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
                PopupMenuButton<RequestStatus>(
                  tooltip: 'Изменить статус (демо)',
                  onSelected: (s) => state.setRequestStatus(request.id, s),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: RequestStatus.newRequest, child: Text('Новая')),
                    PopupMenuItem(value: RequestStatus.inProgress, child: Text('В работе')),
                    PopupMenuItem(value: RequestStatus.done, child: Text('Выполнено')),
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
                    final path = request.photoPaths[i];
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.file(
                        File(path),
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
  final RequestStatus status;
  const _StatusChip({required this.status});

  String _text(RequestStatus s) {
    switch (s) {
      case RequestStatus.newRequest:
        return 'Новая';
      case RequestStatus.inProgress:
        return 'В работе';
      case RequestStatus.done:
        return 'Выполнено';
    }
  }

  IconData _icon(RequestStatus s) {
    switch (s) {
      case RequestStatus.newRequest:
        return Icons.fiber_new;
      case RequestStatus.inProgress:
        return Icons.timelapse;
      case RequestStatus.done:
        return Icons.check_circle;
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
  final RequestStatus status;
  const _StatusTimeline({required this.status});

  bool get _step1 => true;
  bool get _step2 => status == RequestStatus.inProgress || status == RequestStatus.done;
  bool get _step3 => status == RequestStatus.done;

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
            Expanded(child: Center(child: Text('В работе', style: labelStyle(_step2)))),
            Expanded(child: Align(alignment: Alignment.centerRight, child: Text('Готово', style: labelStyle(_step3)))),
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