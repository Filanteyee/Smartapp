import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/app_state_scope.dart';

class CreateRequestSheet extends StatefulWidget {
  const CreateRequestSheet({super.key});

  @override
  State<CreateRequestSheet> createState() => _CreateRequestSheetState();
}

class _CreateRequestSheetState extends State<CreateRequestSheet> {
  final _formKey = GlobalKey<FormState>();
  final _desc = TextEditingController();
  final _picker = ImagePicker();

  final _categories = const [
    'Лифт',
    'Домофон',
    'Дверь/вход',
    'Протечка',
    'Освещение',
    'Электричество',
    'Уборка',
    'Другое',
  ];

  String _selected = 'Лифт';
  final List<XFile> _photos = [];

  @override
  void dispose() {
    _desc.dispose();
    super.dispose();
  }

  Future<void> _pickFromGallery() async {
    final images = await _picker.pickMultiImage(imageQuality: 85);
    if (images.isEmpty) return;

    setState(() {
      _photos.addAll(images);
    });
  }

  Future<void> _takePhoto() async {
    final img = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (img == null) return;

    setState(() {
      _photos.add(img);
    });
  }

  void _removePhoto(int index) {
    setState(() {
      _photos.removeAt(index);
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final state = AppStateScope.of(context);

    state.addRequest(
      category: _selected,
      description: _desc.text.trim(),
      photoPaths: _photos.map((e) => e.path).toList(),
    );

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Заявка создана (демо).')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Создать заявку', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),

            Align(
              alignment: Alignment.centerLeft,
              child: Text('Категория', style: Theme.of(context).textTheme.labelLarge),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((c) {
                final selected = c == _selected;
                return ChoiceChip(
                  label: Text(c),
                  selected: selected,
                  onSelected: (_) => setState(() => _selected = c),
                );
              }).toList(),
            ),

            const SizedBox(height: 14),

            Form(
              key: _formKey,
              child: TextFormField(
                controller: _desc,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Описание проблемы',
                  hintText: 'Например: не работает домофон, лифт шумит…',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  final text = (v ?? '').trim();
                  if (text.isEmpty) return 'Напиши описание';
                  if (text.length < 8) return 'Слишком коротко';
                  return null;
                },
              ),
            ),

            const SizedBox(height: 14),

            Align(
              alignment: Alignment.centerLeft,
              child: Text('Фото (необязательно)', style: Theme.of(context).textTheme.labelLarge),
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _takePhoto,
                    icon: const Icon(Icons.photo_camera),
                    label: const Text('Камера'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickFromGallery,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Галерея'),
                  ),
                ),
              ],
            ),

            if (_photos.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 92,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _photos.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, i) {
                    final p = _photos[i];
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.file(
                            File(p.path),
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
                        ),
                        Positioned(
                          right: 6,
                          top: 6,
                          child: InkWell(
                            onTap: () => _removePhoto(i),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Icon(Icons.close, size: 16),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],

            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Отмена'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _submit,
                    child: const Text('Создать'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}