import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';

import '/backend/schema/structs/index.dart';

import '/main.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/lat_lng.dart';
import '/flutter_flow/place.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'serialization_util.dart';

import '/index.dart';

export 'package:go_router/go_router.dart';
export 'serialization_util.dart';

const kTransitionInfoKey = '__transition_info__';

GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

class AppStateNotifier extends ChangeNotifier {
  AppStateNotifier._();

  static AppStateNotifier? _instance;
  static AppStateNotifier get instance => _instance ??= AppStateNotifier._();

  bool showSplashImage = true;

  void stopShowingSplashImage() {
    showSplashImage = false;
    notifyListeners();
  }
}

GoRouter createRouter(AppStateNotifier appStateNotifier) => GoRouter(
      initialLocation: '/',
      debugLogDiagnostics: true,
      refreshListenable: appStateNotifier,
      navigatorKey: appNavigatorKey,
      errorBuilder: (context, state) => const HomeWidget(),
      routes: [
        FFRoute(
          name: '_initialize',
          path: '/',
          builder: (context, _) => const HomeWidget(),
        ),
        FFRoute(
          name: LoginWidget.routeName,
          path: LoginWidget.routePath,
          builder: (context, params) => const LoginWidget(),
        ),
        FFRoute(
          name: SignupWidget.routeName,
          path: SignupWidget.routePath,
          builder: (context, params) => const SignupWidget(),
        ),
        FFRoute(
          name: VerifyEmailWidget.routeName,
          path: VerifyEmailWidget.routePath,
          builder: (context, params) => VerifyEmailWidget(
            email: params.getParam(
              'email',
              ParamType.String,
            ),
            timeEmailSent: params.getParam(
              'timeEmailSent',
              ParamType.String,
            ),
          ),
        ),
        FFRoute(
          name: AccountVerifiedWidget.routeName,
          path: AccountVerifiedWidget.routePath,
          builder: (context, params) => const AccountVerifiedWidget(),
        ),
        FFRoute(
          name: PasswordResetWidget.routeName,
          path: PasswordResetWidget.routePath,
          builder: (context, params) => const PasswordResetWidget(),
        ),
        FFRoute(
          name: PasswordResetCompleteWidget.routeName,
          path: PasswordResetCompleteWidget.routePath,
          builder: (context, params) => const PasswordResetCompleteWidget(),
        ),
        FFRoute(
          name: ChangePasswordWidget.routeName,
          path: ChangePasswordWidget.routePath,
          builder: (context, params) => const ChangePasswordWidget(),
        ),
        FFRoute(
          name: HomeWidget.routeName,
          path: HomeWidget.routePath,
          builder: (context, params) => const HomeWidget(),
        ),
        FFRoute(
          name: ScanSalesOrderWidget.routeName,
          path: ScanSalesOrderWidget.routePath,
          builder: (context, params) => const ScanSalesOrderWidget(),
        ),
        FFRoute(
          name: ProcesswScan0Widget.routeName,
          path: ProcesswScan0Widget.routePath,
          builder: (context, params) => const ProcesswScan0Widget(),
        ),
        FFRoute(
          name: ProcesswScan1Widget.routeName,
          path: ProcesswScan1Widget.routePath,
          builder: (context, params) => const ProcesswScan1Widget(),
        ),
        FFRoute(
          name: ProcesswScan2Widget.routeName,
          path: ProcesswScan2Widget.routePath,
          builder: (context, params) => const ProcesswScan2Widget(),
        ),
        FFRoute(
          name: ProcesswScan3Widget.routeName,
          path: ProcesswScan3Widget.routePath,
          builder: (context, params) => const ProcesswScan3Widget(),
        ),
        FFRoute(
          name: ProcesswScan4Widget.routeName,
          path: ProcesswScan4Widget.routePath,
          builder: (context, params) => const ProcesswScan4Widget(),
        ),
        FFRoute(
          name: ProcesswScan5Widget.routeName,
          path: ProcesswScan5Widget.routePath,
          builder: (context, params) => const ProcesswScan5Widget(),
        ),
        FFRoute(
          name: ProcessxScan0Widget.routeName,
          path: ProcessxScan0Widget.routePath,
          builder: (context, params) => const ProcessxScan0Widget(),
        ),
        FFRoute(
          name: ProcessxScan1Widget.routeName,
          path: ProcessxScan1Widget.routePath,
          builder: (context, params) => const ProcessxScan1Widget(),
        ),
        FFRoute(
          name: ProcessxScan2Widget.routeName,
          path: ProcessxScan2Widget.routePath,
          builder: (context, params) => const ProcessxScan2Widget(),
        ),
        FFRoute(
          name: ProcessxScan3Widget.routeName,
          path: ProcessxScan3Widget.routePath,
          builder: (context, params) => const ProcessxScan3Widget(),
        )
      ].map((r) => r.toRoute(appStateNotifier)).toList(),
    );

extension NavParamExtensions on Map<String, String?> {
  Map<String, String> get withoutNulls => Map.fromEntries(
        entries
            .where((e) => e.value != null)
            .map((e) => MapEntry(e.key, e.value!)),
      );
}

extension NavigationExtensions on BuildContext {
  void safePop() {
    // If there is only one route on the stack, navigate to the initial
    // page instead of popping.
    if (canPop()) {
      pop();
    } else {
      go('/');
    }
  }
}

extension _GoRouterStateExtensions on GoRouterState {
  Map<String, dynamic> get extraMap =>
      extra != null ? extra as Map<String, dynamic> : {};
  Map<String, dynamic> get allParams => <String, dynamic>{}
    ..addAll(pathParameters)
    ..addAll(uri.queryParameters)
    ..addAll(extraMap);
  TransitionInfo get transitionInfo => extraMap.containsKey(kTransitionInfoKey)
      ? extraMap[kTransitionInfoKey] as TransitionInfo
      : TransitionInfo.appDefault();
}

class FFParameters {
  FFParameters(this.state, [this.asyncParams = const {}]);

  final GoRouterState state;
  final Map<String, Future<dynamic> Function(String)> asyncParams;

  Map<String, dynamic> futureParamValues = {};

  // Parameters are empty if the params map is empty or if the only parameter
  // present is the special extra parameter reserved for the transition info.
  bool get isEmpty =>
      state.allParams.isEmpty ||
      (state.allParams.length == 1 &&
          state.extraMap.containsKey(kTransitionInfoKey));
  bool isAsyncParam(MapEntry<String, dynamic> param) =>
      asyncParams.containsKey(param.key) && param.value is String;
  bool get hasFutures => state.allParams.entries.any(isAsyncParam);
  Future<bool> completeFutures() => Future.wait(
        state.allParams.entries.where(isAsyncParam).map(
          (param) async {
            final doc = await asyncParams[param.key]!(param.value)
                .onError((_, __) => null);
            if (doc != null) {
              futureParamValues[param.key] = doc;
              return true;
            }
            return false;
          },
        ),
      ).onError((_, __) => [false]).then((v) => v.every((e) => e));

  dynamic getParam<T>(
    String paramName,
    ParamType type, {
    bool isList = false,
    StructBuilder<T>? structBuilder,
  }) {
    if (futureParamValues.containsKey(paramName)) {
      return futureParamValues[paramName];
    }
    if (!state.allParams.containsKey(paramName)) {
      return null;
    }
    final param = state.allParams[paramName];
    // Got parameter from `extras`, so just directly return it.
    if (param is! String) {
      return param;
    }
    // Return serialized value.
    return deserializeParam<T>(
      param,
      type,
      isList,
      structBuilder: structBuilder,
    );
  }
}

class FFRoute {
  const FFRoute({
    required this.name,
    required this.path,
    required this.builder,
    this.requireAuth = false,
    this.asyncParams = const {},
    this.routes = const [],
  });

  final String name;
  final String path;
  final bool requireAuth;
  final Map<String, Future<dynamic> Function(String)> asyncParams;
  final Widget Function(BuildContext, FFParameters) builder;
  final List<GoRoute> routes;

  GoRoute toRoute(AppStateNotifier appStateNotifier) => GoRoute(
        name: name,
        path: path,
        pageBuilder: (context, state) {
          fixStatusBarOniOS16AndBelow(context);
          final ffParams = FFParameters(state, asyncParams);
          final page = ffParams.hasFutures
              ? FutureBuilder(
                  future: ffParams.completeFutures(),
                  builder: (context, _) => builder(context, ffParams),
                )
              : builder(context, ffParams);
          final child = page;

          final transitionInfo = state.transitionInfo;
          return transitionInfo.hasTransition
              ? CustomTransitionPage(
                  key: state.pageKey,
                  name: state.name,
                  child: child,
                  transitionDuration: transitionInfo.duration,
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) =>
                          PageTransition(
                    type: transitionInfo.transitionType,
                    duration: transitionInfo.duration,
                    reverseDuration: transitionInfo.duration,
                    alignment: transitionInfo.alignment,
                    curve: transitionInfo.transitionType ==
                            PageTransitionType.scale
                        ? const Interval(0.0, 0.5)
                        : Curves.linear,
                    child: child,
                  ).buildTransitions(
                    context,
                    animation,
                    secondaryAnimation,
                    child,
                  ),
                )
              : MaterialPage(
                  key: state.pageKey, name: state.name, child: child);
        },
        routes: routes,
      );
}

class TransitionInfo {
  const TransitionInfo({
    required this.hasTransition,
    this.transitionType = PageTransitionType.fade,
    this.duration = const Duration(milliseconds: 300),
    this.alignment,
  });

  final bool hasTransition;
  final PageTransitionType transitionType;
  final Duration duration;
  final Alignment? alignment;

  static TransitionInfo appDefault() =>
      const TransitionInfo(hasTransition: false);
}

class RootPageContext {
  const RootPageContext(this.isRootPage, [this.errorRoute]);
  final bool isRootPage;
  final String? errorRoute;

  static bool isInactiveRootPage(BuildContext context) {
    final rootPageContext = context.read<RootPageContext?>();
    final isRootPage = rootPageContext?.isRootPage ?? false;
    final location = GoRouterState.of(context).uri.toString();
    return isRootPage &&
        location != '/' &&
        location != rootPageContext?.errorRoute;
  }

  static Widget wrap(Widget child, {String? errorRoute}) => Provider.value(
        value: RootPageContext(true, errorRoute),
        child: child,
      );
}

extension GoRouterLocationExtension on GoRouter {
  String getCurrentLocation() {
    final RouteMatch lastMatch = routerDelegate.currentConfiguration.last;
    final RouteMatchList matchList = lastMatch is ImperativeRouteMatch
        ? lastMatch.matches
        : routerDelegate.currentConfiguration;
    return matchList.uri.toString();
  }
}
