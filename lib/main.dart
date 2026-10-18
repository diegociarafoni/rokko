import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:path_provider/path_provider.dart';

import 'backup/backup.dart';
import 'backup/backup_page.dart';
import 'guide/guide_controller.dart';
import 'guide/guide_host.dart';
import 'home/home_shell.dart';
import 'l10n/app_localizations.dart';
import 'l10n/content.dart';
import 'reminders/reminder_controller.dart';
import 'settings/app_language.dart';
import 'settings/settings.dart';
import 'share/share_temp.dart';
import 'theme/no_transitions.dart';
import 'theme/rokko_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Backup.applyPending(
      await getApplicationSupportDirectory(),
      applyPreferencesToSystem,
    );
  } on Object catch (e) {
    debugPrint('Backup restore failed: $e');
  }
  unawaited(clearShareTemp());
  runApp(const RokkoApp());
}

class RokkoApp extends StatefulWidget {
  const RokkoApp({super.key, @visibleForTesting this.contentLoader});

  /// Carica i contenuti nella lingua data; di norma [Content.ensureLoaded].
  final Future<void> Function(String languageCode)? contentLoader;

  @override
  State<RokkoApp> createState() => _RokkoAppState();
}

class _RokkoAppState extends State<RokkoApp> with WidgetsBindingObserver {
  SettingsController? _settings;
  GuideController? _guides;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_start());
  }

  @override
  void didChangeAccessibilityFeatures() => _syncReduceMotion();

  void _syncReduceMotion() => _settings?.setReduceMotion(
    WidgetsBinding
        .instance
        .platformDispatcher
        .accessibilityFeatures
        .disableAnimations,
  );

  Future<void> _start() async {
    final settings = await SettingsController.load().catchError(
      (Object _) => SettingsController.defaults(),
    );
    final guides = await GuideController.load().catchError(
      (Object _) => GuideController.memory(enabled: false),
    );
    // I contenuti (lezioni, grandi maestri…) servono prima delle schermate.
    await _loadContent(settings.value.language);
    settings.addListener(_onSettings);
    if (!mounted) return;
    // Prima del primo disegno, così nemmeno il primo fotogramma si anima.
    settings.setReduceMotion(
      WidgetsBinding
          .instance
          .platformDispatcher
          .accessibilityFeatures
          .disableAnimations,
    );
    setState(() {
      _settings = settings;
      _guides = guides;
    });
  }

  /// Lingua dei contenuti richiesta per ultima.
  String? _contentCode;

  /// Cresce a ogni richiesta: un caricamento superato non deve scrivere.
  int _generation = 0;

  /// Caricamenti in fila: uno lento non può finire dopo uno più recente e
  /// rimettere la lingua vecchia.
  Future<void> _queue = Future.value();

  void _onSettings() {
    final language = _settings?.value.language;
    if (language != null) _refreshContent(language);
  }

  /// Con lingua Automatica il telefono può cambiarla a app aperta.
  @override
  void didChangeLocales(List<Locale>? locales) {
    final language = _settings?.value.language;
    if (language != null) _refreshContent(language);
  }

  void _refreshContent(AppLanguage language) {
    if (_codeFor(language) == _contentCode) return;
    unawaited(
      _loadContent(language).then((latest) {
        if (!mounted || !latest) return;
        setState(() {});
        // Il promemoria programmato ha ancora il testo della lingua vecchia.
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => unawaited(ReminderController.languageChanged()),
        );
      }),
    );
  }

  String _codeFor(AppLanguage language) =>
      (language.locale ??
              resolveAppLocale(
                WidgetsBinding.instance.platformDispatcher.locales,
                AppLocalizations.supportedLocales,
              ))
          .languageCode;

  /// `false` se nel frattempo è arrivata una richiesta più recente.
  Future<bool> _loadContent(AppLanguage language) {
    final code = _codeFor(language);
    _contentCode = code;
    final generation = ++_generation;
    final run = _queue.then<bool>((_) async {
      if (generation != _generation) return false;
      final load =
          widget.contentLoader ??
          (String c) => Content.ensureLoaded(language: c);
      try {
        await load(code);
      } on Object catch (e) {
        if (kDebugMode) debugPrint('Content not loaded: $e');
        // Una richiesta uguale successiva deve poter riprovare.
        if (generation == _generation) _contentCode = null;
        // Senza contenuti le schermate lanciano un errore: si ripiega sulla
        // lingua di base.
        try {
          await load('it');
        } on Object catch (e) {
          if (kDebugMode) debugPrint('Base content not loaded: $e');
        }
      }
      return generation == _generation;
    });
    _queue = run;
    return run;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _settings?.removeListener(_onSettings);
    _settings?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = _settings;
    if (settings == null) return _app(null, ThemeMode.system, null, false);
    return ValueListenableBuilder(
      valueListenable: settings,
      builder: (context, s, _) =>
          _app(settings, s.themeMode, s.language.locale, s.reduceMotion),
    );
  }

  Widget _app(
    SettingsController? settings,
    ThemeMode themeMode,
    Locale? locale,
    bool still,
  ) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      // Senza scelta si segue il telefono; una lingua non supportata ripiega
      // sull'italiano.
      locale: locale,
      localeListResolutionCallback: resolveAppLocale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: _still(RokkoTheme.light(), still),
      darkTheme: _still(RokkoTheme.dark(), still),
      themeMode: themeMode,
      // Sopra il Navigator, così anche le pagine aperte con push lo vedono.
      builder: (context, child) => settings == null
          ? child!
          : SettingsScope(
              controller: settings,
              child: GuideScope(
                controller: _guides ?? GuideController.memory(enabled: false),
                child: child!,
              ),
            ),
      home: settings == null ? const Scaffold() : HomeShell(settings: settings),
    );
  }
}

/// Con le animazioni ridotte le pagine si aprono senza transizione.
ThemeData _still(ThemeData theme, bool still) =>
    still ? theme.copyWith(pageTransitionsTheme: stillTransitions) : theme;
