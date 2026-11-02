import 'package:provider/provider.dart';
import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import 'flutter_flow/flutter_flow_util.dart';
import 'flutter_flow/nav/nav.dart';
import 'index.dart';
import '/auth/kinta_auth_service.dart';
import '/offline/kinta_local_repository.dart';

import '/offline/kinta_sync_service.dart';
import '/offline/connectivity_listener.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoRouter.optionURLReflectsImperativeAPIs = true;
  usePathUrlStrategy();
  await KintaAuthService.restoreSavedSession();
  // Remove a selection snapshot saved by older app versions. Process history
  // and offline work are stored separately and are not cleared here.
  await KintaLocalRepository.clearCurrentProcessDraft();

  final appState = FFAppState(); // Initialize FFAppState
  await appState.initializePersistedState();

  runApp(ChangeNotifierProvider(
    create: (context) => appState,
    child: MyApp(),
  ));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  State<MyApp> createState() => _MyAppState();

  static _MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>()!;
}

class MyAppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      };
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  ThemeMode _themeMode = ThemeMode.system;

  late AppStateNotifier _appStateNotifier;
  late GoRouter _router;
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  final KintaConnectivityListener _connectivityListener =
      KintaConnectivityListener();
  Timer? _autoSyncTimer;
  String getRoute([RouteMatch? routeMatch]) {
    final RouteMatch lastMatch =
        routeMatch ?? _router.routerDelegate.currentConfiguration.last;
    final RouteMatchList matchList = lastMatch is ImperativeRouteMatch
        ? lastMatch.matches
        : _router.routerDelegate.currentConfiguration;
    return matchList.uri.path;
  }

  List<String> getRouteStack() =>
      _router.routerDelegate.currentConfiguration.matches
          .map((e) => getRoute(e))
          .toList();
  @override
  void initState() {
    super.initState();

    _appStateNotifier = AppStateNotifier.instance;
    _router = createRouter(_appStateNotifier);
    WidgetsBinding.instance.addObserver(this);
    _connectivityListener.listenForOnline(
      () => _syncPendingWorkIfNeeded(forceRetry: true),
    );
    // Browser online events do not fire when only Apache/CI4 becomes reachable.
    // This short poll retries pending work without requiring a page refresh.
    _autoSyncTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _syncPendingWorkIfNeeded(),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoSyncTimer?.cancel();
    _connectivityListener.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncPendingWorkIfNeeded(forceRetry: true);
    }
  }

  Future<void> _syncPendingWorkIfNeeded({bool forceRetry = false}) async {
    if (!mounted ||
        !_connectivityListener.isOnline ||
        !KintaAuthService.hasPermission('process.sync')) {
      return;
    }

    try {
      final actorUserId = KintaAuthService.currentUser?['id']?.toString();
      if (actorUserId == null) return;
      final requeuedCount = await KintaSyncService
          .retryWaitingProcessesWhenMasterDataIsActive(
        actorUserId: actorUserId,
      );
      if (await KintaLocalRepository.countPendingLocalProcesses() == 0) return;
      final report = await KintaSyncService.syncPendingProcesses(
        forceRetry: forceRetry,
      );
      if (!mounted) return;

      if (requeuedCount > 0 && report.synced > 0) {
        _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text(
              '$requeuedCount process(es) synced after master data was reactivated.',
            ),
            duration: const Duration(seconds: 8),
          ),
        );
        return;
      }
      if (report.waitingForMasterData > 0) {
        _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text(
              '${report.waitingForMasterData} process(es) are waiting for '
              'master data reactivation. KINTA will retry automatically.',
            ),
            duration: const Duration(seconds: 8),
          ),
        );
        return;
      }
      if (report.needsReview == 0) return;

      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(
            '${report.needsReview} queued process(es) need review. '
            'Open Process Records for details.',
          ),
          duration: const Duration(seconds: 8),
        ),
      );
    } catch (_) {
      // Automatic retries stay quiet. The sync service preserves queued work.
    }
  }

  void setThemeMode(ThemeMode mode) => safeSetState(() {
        _themeMode = mode;
      });

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      scaffoldMessengerKey: _scaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      title: 'kinta-intern-justin',
      scrollBehavior: MyAppScrollBehavior(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', '')],
      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: false,
      ),
      themeMode: _themeMode,
      routerConfig: _router,
    );
  }
}


