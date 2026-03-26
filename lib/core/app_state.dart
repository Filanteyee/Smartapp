import 'package:flutter/foundation.dart';

enum SensorStatus { ok, warning, danger }
enum EmergencyStatus { active, resolved }
enum RequestStatus { newRequest, inProgress, done }

class Sensor {
  final String id;
  final String title;
  final String value;
  final String room;
  final SensorStatus status;

  const Sensor({
    required this.id,
    required this.title,
    required this.value,
    required this.room,
    required this.status,
  });

  Sensor copyWith({String? value, SensorStatus? status}) {
    return Sensor(
      id: id,
      title: title,
      value: value ?? this.value,
      room: room,
      status: status ?? this.status,
    );
  }
}

class Emergency {
  final String id;
  final String title;
  final String details;
  final DateTime createdAt;
  final EmergencyStatus status;

  const Emergency({
    required this.id,
    required this.title,
    required this.details,
    required this.createdAt,
    required this.status,
  });

  Emergency copyWith({EmergencyStatus? status}) {
    return Emergency(
      id: id,
      title: title,
      details: details,
      createdAt: createdAt,
      status: status ?? this.status,
    );
  }
}

class ServiceRequest {
  final String id;
  final String category;
  final String description;
  final DateTime createdAt;
  final RequestStatus status;

  /// локальные пути к фото (позже заменим на ссылки Storage)
  final List<String> photoPaths;

  const ServiceRequest({
    required this.id,
    required this.category,
    required this.description,
    required this.createdAt,
    required this.status,
    this.photoPaths = const [],
  });

  ServiceRequest copyWith({RequestStatus? status, List<String>? photoPaths}) {
    return ServiceRequest(
      id: id,
      category: category,
      description: description,
      createdAt: createdAt,
      status: status ?? this.status,
      photoPaths: photoPaths ?? this.photoPaths,
    );
  }
}

class AppNotification {
  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool read;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.read,
  });

  AppNotification copyWith({bool? read}) {
    return AppNotification(
      id: id,
      title: title,
      body: body,
      createdAt: createdAt,
      read: read ?? this.read,
    );
  }
}

class AppState extends ChangeNotifier {
  String apartmentName = 'Квартира 8';

  bool frontDoorLocked = true;
  bool leakControlEnabled = true;
  bool cleaningEnabled = false;

  final List<Sensor> sensors = [
    const Sensor(id: 's1', title: 'Температура', value: '24°C', room: 'Спальня', status: SensorStatus.ok),
    const Sensor(id: 's2', title: 'Влажность', value: '42%', room: 'Спальня', status: SensorStatus.ok),
    const Sensor(id: 's3', title: 'Дым', value: 'Норма', room: 'Кухня', status: SensorStatus.ok),
    const Sensor(id: 's4', title: 'Протечка', value: 'Норма', room: 'Ванная', status: SensorStatus.ok),
  ];

  final List<Emergency> emergencies = [];

  final List<ServiceRequest> requests = [
    ServiceRequest(
      id: 'r1',
      category: 'Лифт',
      description: 'Лифт издаёт странный звук',
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      status: RequestStatus.inProgress,
      photoPaths: [],
    ),
    ServiceRequest(
      id: 'r2',
      category: 'Освещение',
      description: 'Не горит лампа на лестничной площадке',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      status: RequestStatus.newRequest,
      photoPaths: [],
    ),
  ];

  final List<AppNotification> notifications = [
    AppNotification(
      id: 'n1',
      title: 'Проверка системы',
      body: 'Все датчики работают в штатном режиме (демо).',
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      read: false,
    ),
  ];

  int get unreadNotifications => notifications.where((n) => !n.read).length;

  int get activeEmergenciesCount => emergencies.where((e) => e.status == EmergencyStatus.active).length;

  SensorStatus get homeStatus {
    if (activeEmergenciesCount > 0) return SensorStatus.danger;
    if (sensors.any((s) => s.status == SensorStatus.danger)) return SensorStatus.danger;
    if (sensors.any((s) => s.status == SensorStatus.warning)) return SensorStatus.warning;
    return SensorStatus.ok;
  }

  void toggleFrontDoor() {
    frontDoorLocked = !frontDoorLocked;
    _pushNotification(
      title: 'Входная дверь',
      body: frontDoorLocked ? 'Дверь закрыта (демо).' : 'Дверь открыта (демо).',
    );
    notifyListeners();
  }

  void toggleLeakControl() {
    leakControlEnabled = !leakControlEnabled;
    _pushNotification(
      title: 'Контроль протечек',
      body: leakControlEnabled ? 'Включено (демо).' : 'Выключено (демо).',
    );
    notifyListeners();
  }

  void toggleCleaning() {
    cleaningEnabled = !cleaningEnabled;
    _pushNotification(
      title: 'Уборка',
      body: cleaningEnabled ? 'Включено (демо).' : 'Выключено (демо).',
    );
    notifyListeners();
  }

  void scenarioImHome() {
    leakControlEnabled = true;
    cleaningEnabled = false;
    frontDoorLocked = true;
    _pushNotification(title: 'Сценарий', body: 'Режим “Я дома” применён (демо).');
    notifyListeners();
  }

  void scenarioImAway() {
    leakControlEnabled = true;
    cleaningEnabled = false;
    frontDoorLocked = true;
    _pushNotification(title: 'Сценарий', body: 'Режим “Я ушёл” применён (демо).');
    notifyListeners();
  }

  void addRequest({
    required String category,
    required String description,
    List<String> photoPaths = const [],
  }) {
    final req = ServiceRequest(
      id: 'r${requests.length + 1}',
      category: category,
      description: description,
      createdAt: DateTime.now(),
      status: RequestStatus.newRequest,
      photoPaths: photoPaths,
    );
    requests.insert(0, req);

    _pushNotification(
      title: 'Новая заявка',
      body: 'Категория: $category. Отправлено (демо).',
    );

    notifyListeners();
  }

  void setRequestStatus(String id, RequestStatus status) {
    final i = requests.indexWhere((r) => r.id == id);
    if (i == -1) return;
    requests[i] = requests[i].copyWith(status: status);
    notifyListeners();
  }

  void markNotificationRead(String id) {
    final i = notifications.indexWhere((n) => n.id == id);
    if (i == -1) return;
    notifications[i] = notifications[i].copyWith(read: true);
    notifyListeners();
  }

  void markAllNotificationsRead() {
    for (var i = 0; i < notifications.length; i++) {
      if (!notifications[i].read) {
        notifications[i] = notifications[i].copyWith(read: true);
      }
    }
    notifyListeners();
  }

  void addEmergency({required String title, required String details}) {
    final e = Emergency(
      id: 'e${emergencies.length + 1}',
      title: title,
      details: details,
      createdAt: DateTime.now(),
      status: EmergencyStatus.active,
    );
    emergencies.insert(0, e);

    _pushNotification(title: 'Авария: $title', body: details);
    notifyListeners();
  }

  void resolveEmergency(String id) {
    final i = emergencies.indexWhere((e) => e.id == id);
    if (i == -1) return;
    emergencies[i] = emergencies[i].copyWith(status: EmergencyStatus.resolved);
    notifyListeners();
  }

  void _pushNotification({required String title, required String body}) {
    final n = AppNotification(
      id: 'n${notifications.length + 1}',
      title: title,
      body: body,
      createdAt: DateTime.now(),
      read: false,
    );
    notifications.insert(0, n);
  }
}