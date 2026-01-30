import 'dart:async';

import 'package:dk_util/state/dk_state_query.dart';
import 'package:dk_util/state/dk_state_query_helper.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

extension DkStateQueryGetExtension<T> on Rx<DKStateQuery<T>> {
  Future<void> query({
    required Future<T> Function() query,
    bool Function(T)? isEmpty,
  }) async {
    await DKStateQueryHelper.query<T>(
      onStateChange: (state) => value = state,
      query: query,
      isEmpty: isEmpty,
    );
  }

  Widget display({
    Widget Function()? initialBuilder,
    Widget Function()? loadingBuilder,
    Widget Function(String message)? errorBuilder,
    Widget Function()? emptyBuilder,
    required Widget Function(T data) successBuilder,
    Widget Function()? retryBuilder,
    VoidCallback? onRetry,
    required Duration transitionDuration,
    Color? backgroundColor,
  }) {
    return Obx(
      () => DKStateQueryDisplay(
        state: value,
        initialBuilder: initialBuilder,
        loadingBuilder: loadingBuilder,
        errorBuilder: errorBuilder,
        emptyBuilder: emptyBuilder,
        successBuilder: successBuilder,
        retryBuilder: retryBuilder,
        onRetry: onRetry,
        transitionDuration: transitionDuration,
        backgroundColor: backgroundColor,
      ),
    );
  }
}
