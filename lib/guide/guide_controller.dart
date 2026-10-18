import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Quali guide alla prima apertura sono già state viste e se vanno mostrate.
class GuideController extends ChangeNotifier {
  GuideController._(this._prefs, this._enabled, Set<String> seen)
    : _seen = {...seen};

  /// Senza salvataggio: per i test e se le preferenze non si leggono.
  GuideController.memory({bool enabled = true, Set<String> seen = const {}})
    : this._(null, enabled, seen);

  /// Valore iniziale di «Guide attive»: i test dell'app intera lo spengono per
  /// non avere la guida sopra le schermate che provano.
  static bool defaultEnabled = true;

  static const _enabledKey = 'guideEnabled';
  static const _seenKey = 'guideSeen';

  static Future<GuideController> load() async {
    final prefs = await SharedPreferences.getInstance();
    return GuideController._(
      prefs,
      prefs.getBool(_enabledKey) ?? defaultEnabled,
      {...?prefs.getStringList(_seenKey)},
    );
  }

  final SharedPreferences? _prefs;
  bool _enabled;
  final Set<String> _seen;

  bool get enabled => _enabled;

  bool isSeen(String screen) => _seen.contains(screen);

  /// La guida di [screen] compare solo se attiva e non ancora vista.
  bool shouldShow(String screen) => _enabled && !_seen.contains(screen);

  Future<void> markSeen(String screen) async {
    if (!_seen.add(screen)) return;
    notifyListeners();
    await _prefs?.setStringList(_seenKey, _seen.toList());
  }

  Future<void> setEnabled(bool value) async {
    if (_enabled == value) return;
    _enabled = value;
    notifyListeners();
    await _prefs?.setBool(_enabledKey, value);
  }

  /// «Rivedi le guide»: dimentica le viste e le riattiva.
  Future<void> reset() async {
    _seen.clear();
    _enabled = true;
    notifyListeners();
    await _prefs?.remove(_seenKey);
    await _prefs?.setBool(_enabledKey, true);
  }
}
