import 'package:flutter/material.dart';

/// Dismisses any visible toast when the route changes.
///
/// Floating snack bars are drawn over the bottom of the screen by
/// [Scaffold], not inside the page, so a confirmation about the screen you
/// just left can sit on top of a button on the screen you just opened — the
/// "Expense saved" toast covering Delete on the detail page, for instance.
///
/// A message about the previous screen has no business outliving it, so it
/// is cleared on every push and pop. A toast shown deliberately *after* a
/// pop — the Undo offer following a delete — is unaffected, because it is
/// raised once the navigation has already happened.
class ToastClearingObserver extends NavigatorObserver {
  ToastClearingObserver(this.messengerKey);

  final GlobalKey<ScaffoldMessengerState> messengerKey;

  void _clear() => messengerKey.currentState?.clearSnackBars();

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => _clear();

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) => _clear();

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      _clear();
}
