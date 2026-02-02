import 'dart:async';

import 'package:dk_util/state/dk_state_event.dart';
import 'package:dk_util/state/dk_state_event_helper.dart';
import 'package:get/get.dart';

extension DKStateEventGet<T> on Rx<DKStateEvent<T>> {
  Future<void> triggerEvent({required Future<T> Function() event}) async {
    await DKStateEventHelper.triggerEvent<T>(
      onStateChange: (state) => value = state,
      event: event,
    );
  }

  StreamSubscription<DKStateEvent<T>> listenEvent({
    void Function()? onLoading,
    void Function(T data)? onSuccess,
    void Function(String message, Object? error, StackTrace? stackTrace)?
    onError,
    void Function()? onIdle,
    void Function()? onComplete,
  }) {
    return listen((state) {
      DKStateEventHelper.handleState<T>(
        state,
        onLoading: onLoading,
        onSuccess: onSuccess,
        onError: onError,
        onIdle: onIdle,
        onComplete: onComplete,
      );
    });
  }
}
