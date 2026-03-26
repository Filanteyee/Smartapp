import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class RegisterFlowPage extends StatefulWidget {
  const RegisterFlowPage({super.key});

  @override
  State<RegisterFlowPage> createState() => _RegisterFlowPageState();
}

class _RegisterFlowPageState extends State<RegisterFlowPage> {
  static const Color _accent = Color(0xFFF9793D);
  static const Color _green = Color(0xFF35C84A);

  final _authService = AuthService();

  int _step = 0;
  bool _loading = false;

  final _phoneController = TextEditingController();
  final _iinController = TextEditingController();
  final _streetController = TextEditingController();
  final _propertyNumberController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _agreeData = true;
  bool _agreeTerms = true;
  bool _isIndividual = true;

  String? _selectedCity;
  String? _selectedPropertyType;

  bool _obscure1 = true;
  bool _obscure2 = true;

  final List<String> _cities = const [
    'Астана',
    'Алматы',
    'Шымкент',
    'Караганда',
  ];

  final List<String> _propertyTypes = const [
    'Квартира',
    'Дом',
    'Коммерческое помещение',
  ];

  @override
  void dispose() {
    _phoneController.dispose();
    _iinController.dispose();
    _streetController.dispose();
    _propertyNumberController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _validateStep0() {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      _show('Введите номер');
      return false;
    }
    if (!_agreeData || !_agreeTerms) {
      _show('Нужно принять условия');
      return false;
    }
    return true;
  }

  bool _validateStep1() {
    if (_iinController.text.trim().length < 12) {
      _show('Введите корректный ИИН/БИН');
      return false;
    }
    return true;
  }

  bool _validateStep2() {
    if (_selectedCity == null) {
      _show('Выберите город');
      return false;
    }
    if (_streetController.text.trim().isEmpty) {
      _show('Введите улицу и дом');
      return false;
    }
    if (_selectedPropertyType == null) {
      _show('Выберите тип недвижимости');
      return false;
    }
    if (_propertyNumberController.text.trim().isEmpty) {
      _show('Введите номер объекта');
      return false;
    }
    return true;
  }

  bool _validateStep3() {
    if (_fullNameController.text.trim().isEmpty) {
      _show('Введите ФИО');
      return false;
    }
    if (!_emailController.text.contains('@')) {
      _show('Введите корректный email');
      return false;
    }
    if (_passwordController.text.length < 6) {
      _show('Пароль должен быть не меньше 6 символов');
      return false;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      _show('Пароли не совпадают');
      return false;
    }
    return true;
  }

  void _next() {
    final ok = switch (_step) {
      0 => _validateStep0(),
      1 => _validateStep1(),
      2 => _validateStep2(),
      _ => true,
    };

    if (!ok) return;

    setState(() => _step++);
  }

  Future<void> _submit() async {
    if (!_validateStep3()) return;

    setState(() => _loading = true);

    final error = await _authService.registerResident(
      fullName: _fullNameController.text,
      email: _emailController.text,
      password: _passwordController.text,
      phone: _phoneController.text,
      iin: _iinController.text,
      personType: _isIndividual ? 'individual' : 'legal',
      city: _selectedCity ?? '',
      street: _streetController.text,
      propertyType: _selectedPropertyType ?? '',
      propertyNumber: _propertyNumberController.text,
      fullAddress: '${_streetController.text}, ${_selectedCity ?? ''}',
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (error != null) {
      _show(error);
      return;
    }

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Регистрация успешна')),
    );
  }

  void _show(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
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
          'Регистрация',
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          children: [
            if (_step >= 2)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: const Text(
                    'Адрес не найден?',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ),
            if (_step >= 2) _StepDots(step: _step),
            const SizedBox(height: 10),
            if (_step == 0) _buildPhoneStep(),
            if (_step == 1) _buildIinStep(),
            if (_step == 2) _buildAddressStep(),
            if (_step == 3) _buildAccountStep(),
          ],
        ),
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
            onPressed: _loading ? null : (_step == 3 ? _submit : _next),
            child: Text(
              _loading
                  ? 'Сохранение...'
                  : (_step == 3 ? 'Зарегистрироваться' : 'Продолжить'),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneStep() {
    return Column(
      children: [
        const SizedBox(height: 30),
        const Text(
          'Добро пожаловать',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Чтобы продолжить, заполните поле ниже',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 30),
        _LightField(
          controller: _phoneController,
          label: 'Номер телефона',
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: _agreeData,
              activeColor: _accent,
              onChanged: (v) => setState(() => _agreeData = v ?? false),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: RichText(
                  text: const TextSpan(
                    style: TextStyle(color: Colors.black87, fontSize: 15),
                    children: [
                      TextSpan(text: 'Я даю согласие на '),
                      TextSpan(
                        text: 'сбор и обработку персональных данных',
                        style: TextStyle(color: _accent),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: _agreeTerms,
              activeColor: _accent,
              onChanged: (v) => setState(() => _agreeTerms = v ?? false),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: RichText(
                  text: const TextSpan(
                    style: TextStyle(color: Colors.black87, fontSize: 15),
                    children: [
                      TextSpan(text: 'Я принимаю '),
                      TextSpan(
                        text: 'условия пользовательского соглашения',
                        style: TextStyle(color: _accent),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildIinStep() {
    return Column(
      children: [
        const SizedBox(height: 24),
        const Text(
          'Введите ИИН',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Необходимо ввести только свой ИИН.\nИспользование чужого ИИН запрещено.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Colors.black87,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 28),
        RadioListTile<bool>(
          value: true,
          groupValue: _isIndividual,
          activeColor: _accent,
          onChanged: (v) => setState(() => _isIndividual = v ?? true),
          title: const Text('Физическое лицо'),
        ),
        RadioListTile<bool>(
          value: false,
          groupValue: _isIndividual,
          activeColor: _accent,
          onChanged: (v) => setState(() => _isIndividual = v ?? false),
          title: const Text('Юридическое лицо'),
        ),
        const SizedBox(height: 20),
        _LightField(
          controller: _iinController,
          label: 'ИИН/БИН',
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 18),
        TextButton(
          onPressed: () {},
          child: const Text(
            'Проблемы с авторизацией?',
            style: TextStyle(color: _accent),
          ),
        ),
      ],
    );
  }

  Widget _buildAddressStep() {
    return Column(
      children: [
        const SizedBox(height: 18),
        const Text(
          'Адрес собственности',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Введите адрес согласно документам',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 28),
        DropdownButtonFormField<String>(
          value: _selectedCity,
          items: _cities
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          decoration: _dropdownDecoration('Город'),
          onChanged: (value) => setState(() => _selectedCity = value),
        ),
        const SizedBox(height: 14),
        _LightField(
          controller: _streetController,
          label: 'Улица, дом',
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          value: _selectedPropertyType,
          items: _propertyTypes
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          decoration: _dropdownDecoration('Тип объекта недвижимости'),
          onChanged: (value) => setState(() => _selectedPropertyType = value),
        ),
        const SizedBox(height: 14),
        _LightField(
          controller: _propertyNumberController,
          label: 'Номер объекта недвижимости',
        ),
      ],
    );
  }

  Widget _buildAccountStep() {
    return Column(
      children: [
        const SizedBox(height: 18),
        const Text(
          'Создать аккаунт',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'ФИО, email и пароль',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 28),
        _LightField(
          controller: _fullNameController,
          label: 'ФИО',
        ),
        const SizedBox(height: 14),
        _LightField(
          controller: _emailController,
          label: 'Email',
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 14),
        _LightField(
          controller: _passwordController,
          label: 'Пароль',
          obscureText: _obscure1,
          suffix: IconButton(
            onPressed: () => setState(() => _obscure1 = !_obscure1),
            icon: Icon(
              _obscure1 ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey,
            ),
          ),
        ),
        const SizedBox(height: 14),
        _LightField(
          controller: _confirmPasswordController,
          label: 'Подтвердите пароль',
          obscureText: _obscure2,
          suffix: IconButton(
            onPressed: () => setState(() => _obscure2 = !_obscure2),
            icon: Icon(
              _obscure2 ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey,
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _dropdownDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFFD9D9D9)),
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }
}

class _StepDots extends StatelessWidget {
  final int step;

  const _StepDots({required this.step});

  @override
  Widget build(BuildContext context) {
    Widget dot(int index, Color color) {
      return Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (index != 2)
            Container(
              width: 28,
              height: 3,
              color: Colors.grey.shade300,
            ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        dot(0, step > 0 ? _RegisterFlowPageState._green : _RegisterFlowPageState._accent),
        dot(1, step > 1 ? _RegisterFlowPageState._green : _RegisterFlowPageState._accent),
        dot(2, step > 2 ? _RegisterFlowPageState._green : Colors.grey.shade300),
      ],
    );
  }
}

class _LightField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffix;

  const _LightField({
    required this.controller,
    required this.label,
    this.keyboardType,
    this.obscureText = false,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        suffixIcon: suffix,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFFD9D9D9)),
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}