import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../services/api_client.dart';

class AdminVerificationPage extends StatefulWidget {
  const AdminVerificationPage({super.key});

  @override
  State<AdminVerificationPage> createState() => _AdminVerificationPageState();
}

class _AdminVerificationPageState extends State<AdminVerificationPage> {
  final ApiClient _api = ApiClient.instance;

  bool _loading = true;
  String? _error;
  List<_VerificationRequestItem> _requests = [];

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    try {
      setState(() { _loading = true; _error = null; });
      final res = await _api.get('/verification/requests');
      final items = (res.data as List)
          .map((row) => _VerificationRequestItem.fromMap(Map<String, dynamic>.from(row as Map)))
          .toList();
      if (!mounted) return;
      setState(() { _requests = items; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = 'Ошибка загрузки запросов: $e'; _loading = false; });
    }
  }

  Future<void> _updateStatus(_VerificationRequestItem request, String newStatus) async {
    try {
      await _api.put('/verification/requests/${request.id}/status', data: {'status': newStatus});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(newStatus == 'approved' ? 'Статус пользователя подтверждён' : 'Запрос отклонён'),
      ));
      await _loadRequests();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка обновления статуса: $e')));
    }
  }

  Future<void> _openDocumentsDialog(_VerificationRequestItem request) async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Прикреплённые документы'),
        content: SizedBox(
          width: double.maxFinite,
          child: request.documents.isEmpty
              ? const Text('Документы не найдены')
              : ListView.separated(
            shrinkWrap: true,
            itemCount: request.documents.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final doc = request.documents[index];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.insert_drive_file_outlined),
                title: Text(doc.fileName.isEmpty ? 'Без имени' : doc.fileName, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(_formatFileSize(doc.fileSize)),
                trailing: OutlinedButton(onPressed: () => _openFile(doc), child: const Text('Открыть')),
              );
            },
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Закрыть'))],
      ),
    );
  }

  Future<void> _openFile(_VerificationDocumentItem doc) async {
    try {
      final url = doc.url.isNotEmpty ? doc.url : '${ApiClient.baseUrl}/uploads/${doc.filePath}';
      final response = await http.get(Uri.parse(url));
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${doc.fileName.isEmpty ? 'file' : doc.fileName}');
      await file.writeAsBytes(response.bodyBytes);

      if (!mounted) return;

      final lowerName = doc.fileName.toLowerCase();
      final isImage = lowerName.endsWith('.jpg') || lowerName.endsWith('.jpeg') || lowerName.endsWith('.png');
      final isPdf = lowerName.endsWith('.pdf');

      if (isImage) {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Просмотр изображения')),
            body: Center(child: InteractiveViewer(minScale: 0.5, maxScale: 4, child: Image.file(file))),
          ),
        ));
      } else if (isPdf) {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('PDF документ')),
            body: PDFView(filePath: file.path),
          ),
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Формат не поддерживается')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка открытия файла: $e')));
    }
  }

  String _statusLabel(String status) => switch (status) { 'pending' => 'На проверке', 'approved' => 'Подтверждено', 'rejected' => 'Отклонено', _ => status };
  Color _statusColor(String status) => switch (status) { 'approved' => Colors.green, 'rejected' => Colors.red, _ => Colors.orange };
  String _roleLabel(String role) => switch (role) { 'owner' => 'Владелец', 'tenant' => 'Арендатор', _ => role };

  String _formatDate(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(dt.day)}.${two(dt.month)}.${dt.year}  ${two(dt.hour)}:${two(dt.minute)}';
  }

  String _formatFileSize(int size) {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Проверка документов')),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? _ErrorBlock(message: _error!, onRetry: _loadRequests)
            : _requests.isEmpty
            ? const _EmptyBlock(text: 'Запросов на подтверждение пока нет')
            : RefreshIndicator(
          onRefresh: _loadRequests,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: _requests.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final request = _requests[index];
              final profile = request.profile;

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(profile.fullName.isEmpty ? 'Без имени' : profile.fullName, style: Theme.of(context).textTheme.titleMedium)),
                          Chip(label: Text(_statusLabel(request.status)), avatar: Icon(Icons.circle, size: 10, color: _statusColor(request.status))),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (profile.email.isNotEmpty) Text(profile.email),
                      if (profile.phone.isNotEmpty) ...[const SizedBox(height: 4), Text(profile.phone)],
                      if (profile.iin.isNotEmpty) ...[const SizedBox(height: 4), Text('ИИН: ${profile.iin}')],
                      if (profile.fullAddress.isNotEmpty) ...[const SizedBox(height: 4), Text(profile.fullAddress, style: Theme.of(context).textTheme.bodySmall)],
                      const SizedBox(height: 12),
                      Row(children: [const Icon(Icons.badge_outlined, size: 18), const SizedBox(width: 8), Text('Запрошенный статус: ${_roleLabel(request.requestedRole)}')]),
                      const SizedBox(height: 8),
                      Row(children: [const Icon(Icons.schedule_outlined, size: 18), const SizedBox(width: 8), Text(_formatDate(request.createdAt))]),
                      if (request.comment.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(request.comment),
                        ),
                      ],
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _openDocumentsDialog(request),
                          icon: const Icon(Icons.folder_open_outlined),
                          label: Text('Документы (${request.documents.length})'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (request.status == 'pending')
                        Row(
                          children: [
                            Expanded(child: OutlinedButton(onPressed: () => _updateStatus(request, 'rejected'), child: const Text('Отклонить'))),
                            const SizedBox(width: 12),
                            Expanded(child: FilledButton(onPressed: () => _updateStatus(request, 'approved'), child: const Text('Подтвердить'))),
                          ],
                        )
                      else
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.tonal(
                            onPressed: null,
                            child: Text(request.status == 'approved' ? 'Уже подтверждено' : 'Уже отклонено'),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _VerificationRequestItem {
  final String id;
  final String userId;
  final String requestedRole;
  final String comment;
  final String status;
  final DateTime createdAt;
  final _ProfileInfo profile;
  final List<_VerificationDocumentItem> documents;

  const _VerificationRequestItem({
    required this.id,
    required this.userId,
    required this.requestedRole,
    required this.comment,
    required this.status,
    required this.createdAt,
    required this.profile,
    required this.documents,
  });

  factory _VerificationRequestItem.fromMap(Map<String, dynamic> map) {
    final profileMap = Map<String, dynamic>.from((map['profile'] as Map?) ?? {});
    final docsRaw = map['documents'];
    final docs = <_VerificationDocumentItem>[];
    if (docsRaw is List) {
      for (final item in docsRaw) {
        docs.add(_VerificationDocumentItem.fromMap(Map<String, dynamic>.from(item as Map)));
      }
    }
    return _VerificationRequestItem(
      id: (map['id'] ?? '').toString(),
      userId: (map['user_id'] ?? '').toString(),
      requestedRole: (map['requested_role'] ?? '').toString(),
      comment: (map['comment'] ?? '').toString(),
      status: (map['status'] ?? 'pending').toString(),
      createdAt: DateTime.tryParse((map['created_at'] ?? '').toString()) ?? DateTime.now(),
      profile: _ProfileInfo.fromMap(profileMap),
      documents: docs,
    );
  }
}

class _ProfileInfo {
  final String fullName;
  final String email;
  final String phone;
  final String iin;
  final String fullAddress;

  const _ProfileInfo({required this.fullName, required this.email, required this.phone, required this.iin, required this.fullAddress});

  factory _ProfileInfo.fromMap(Map<String, dynamic> map) => _ProfileInfo(
    fullName: (map['full_name'] ?? '').toString(),
    email: (map['email'] ?? '').toString(),
    phone: (map['phone'] ?? '').toString(),
    iin: (map['iin'] ?? '').toString(),
    fullAddress: (map['full_address'] ?? '').toString(),
  );
}

class _VerificationDocumentItem {
  final String id;
  final String filePath;
  final String fileName;
  final int fileSize;
  final String url;

  const _VerificationDocumentItem({required this.id, required this.filePath, required this.fileName, required this.fileSize, required this.url});

  factory _VerificationDocumentItem.fromMap(Map<String, dynamic> map) => _VerificationDocumentItem(
    id: (map['id'] ?? '').toString(),
    filePath: (map['file_path'] ?? '').toString(),
    fileName: (map['file_name'] ?? '').toString(),
    fileSize: map['file_size'] is int ? map['file_size'] as int : int.tryParse((map['file_size'] ?? '0').toString()) ?? 0,
    url: (map['url'] ?? '').toString(),
  );
}

class _EmptyBlock extends StatelessWidget {
  final String text;
  const _EmptyBlock({required this.text});
  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(text, textAlign: TextAlign.center)));
}

class _ErrorBlock extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;
  const _ErrorBlock({required this.message, required this.onRetry});

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
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Повторить')),
          ],
        ),
      ),
    );
  }
}
