import 'package:flutter/material.dart';
import 'app_state.dart';

class AppStateScope extends InheritedNotifier<AppState> {
  const AppStateScope({
    super.key,
    required AppState notifier,
    required Widget child,
  }) : super(notifier: notifier, child: child);

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppStateScope>();
    assert(scope != null, 'AppStateScope не найден. Оберни MaterialApp в AppStateScope.');
    final state = scope!.notifier;
    assert(state != null, 'AppStateScope.notifier == null');
    return state!;
  }
}