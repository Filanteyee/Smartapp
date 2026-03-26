import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class OwnershipVerificationPage extends StatefulWidget {
  const OwnershipVerificationPage({super.key});

  @override
  State<OwnershipVerificationPage> createState() => _OwnershipVerificationPageState();
}

class _OwnershipVerificationPageState extends State<OwnershipVerificationPage> {
  static const Color _accent = Color(0xFFF9793D);

  final _authService = AuthService();
  final _commentController = TextEditingController();

  String _requestedRole = 'owner';
  List<PlatformFile> _files = [];
  bool _loading = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );

    if (result != null) {
      setState(() => _files = result.files);
    }
  }

  Future<void> _submit() async {
    setState(() => _loading = true);

    final error = await _authService.submitVerificationRequest(
      requestedRole: _requestedRole,
      documents: _files,
      comment: _commentController.text,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Документы отправлены на проверку')),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F7F7),
        foregroundColor: _accent,
        elevation: 0,
        title: const Text(
          'Проверка статуса',
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Подтверждение владельца или арендатора',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.black),
          ),
          const SizedBox(height: 10),
          const Text(
            'Прикрепите документ. После проверки мы вручную присвоим вам статус owner или tenant.',
            style: TextStyle(color: Colors.black54, height: 1.5),
          ),
          const SizedBox(height: 24),
          Card(
            child: Column(
              children: [
                RadioListTile<String>(
                  value: 'owner',
                  groupValue: _requestedRole,
                  onChanged: (v) => setState(() => _requestedRole = v!),
                  title: const Text('Я владелец'),
                ),
                RadioListTile<String>(
                  value: 'tenant',
                  groupValue: _requestedRole,
                  onChanged: (v) => setState(() => _requestedRole = v!),
                  title: const Text('Я арендатор'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _commentController,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'Комментарий (необязательно)',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: _pickFiles,
            icon: const Icon(Icons.attach_file),
            label: const Text('Прикрепить документ'),
          ),
          const SizedBox(height: 10),
          ..._files.map(
                (f) => Card(
              child: ListTile(
                leading: const Icon(Icons.insert_drive_file_outlined),
                title: Text(f.name),
                subtitle: Text('${(f.size / 1024).toStringAsFixed(1)} KB'),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(24),
        child: SizedBox(
          height: 56,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: _loading ? null : _submit,
            child: Text(_loading ? 'Отправка...' : 'Отправить на проверку'),
          ),
        ),
      ),
    );
  }
}