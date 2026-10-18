import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderOffstage;

import '../l10n/app_localizations.dart';
import '../settings/settings.dart';
import 'guide_controller.dart';
import 'guide_overlay.dart';

/// Un passo della guida: l'elemento da evidenziare e la sua spiegazione.
class GuideStep {
  const GuideStep(this.anchor, this.text);

  /// Identificativo dell'elemento, lo stesso del [GuideAnchor].
  final String anchor;

  /// Testo del passo; `kid` è vero nel profilo bambino, che ha frasi più semplici.
  final String Function(AppLocalizations l10n, bool kid) text;
}

/// Rende la guida disponibile alle schermate sotto di sé.
class GuideScope extends InheritedNotifier<GuideController> {
  const GuideScope({
    super.key,
    required GuideController controller,
    required super.child,
  }) : super(notifier: controller);

  /// Il controller, o null fuori dall'app (per esempio nei test): senza, nessuna
  /// guida compare.
  static GuideController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<GuideScope>()?.notifier;
}

class _HostScope extends InheritedWidget {
  const _HostScope(this.state, {required super.child});

  final GuideHostState state;

  @override
  bool updateShouldNotify(_HostScope old) => old.state != state;
}

/// Segna un elemento della schermata che un passo della guida può evidenziare.
/// Fuori da un [GuideHost] non fa nulla.
class GuideAnchor extends StatefulWidget {
  const GuideAnchor({super.key, required this.id, required this.child});

  final String id;
  final Widget child;

  @override
  State<GuideAnchor> createState() => _GuideAnchorState();
}

class _GuideAnchorState extends State<GuideAnchor> {
  @override
  void initState() {
    super.initState();
    // Gli elementi che arrivano dopo i dati rimandano la partenza della guida.
    context.getInheritedWidgetOfExactType<_HostScope>()?.state._consider();
  }

  @override
  Widget build(BuildContext context) {
    final host = context.getInheritedWidgetOfExactType<_HostScope>()?.state;
    if (host == null) return widget.child;
    host._layoutChanged();
    return KeyedSubtree(key: host.keyFor(widget.id), child: widget.child);
  }
}

/// Mostra la guida di una schermata la prima volta che compare, con un passo per
/// funzione evidenziata. Salta i passi il cui elemento non c'è (per esempio la
/// ricerca nel profilo bambino).
class GuideHost extends StatefulWidget {
  const GuideHost({
    super.key,
    required this.screen,
    required this.steps,
    required this.child,
    this.enabled = true,
    this.onStart,
    this.onEnd,
  });

  /// Identificativo salvato quando la guida è stata vista.
  final String screen;
  final List<GuideStep> steps;
  final Widget child;

  /// Falso quando la schermata è sotto un'altra (per esempio la scheda Home
  /// mentre è aperta un'altra scheda).
  final bool enabled;

  /// All'apertura e alla chiusura della guida: la partita ferma l'orologio.
  final VoidCallback? onStart;
  final VoidCallback? onEnd;

  @override
  State<GuideHost> createState() => GuideHostState();
}

class GuideHostState extends State<GuideHost> {
  /// Fotogrammi senza elementi nuovi prima di partire: i dati caricati dopo
  /// l'apertura (progressi, puzzle) hanno il tempo di comparire.
  static const _quietFrames = 12;

  final Map<String, GlobalKey> _keys = {};
  final ValueNotifier<int> _layout = ValueNotifier(0);
  OverlayEntry? _entry;
  bool _done = false;
  bool _waiting = false;
  bool _layoutScheduled = false;
  int _quiet = 0;
  Animation<double>? _watched;

  GlobalKey keyFor(String id) => _keys.putIfAbsent(id, GlobalKey.new);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // «Rivedi le guide»: la schermata ancora aperta riparte alla prossima occasione.
    if (_done &&
        GuideScope.maybeOf(context)?.shouldShow(widget.screen) == true) {
      _done = false;
    }
    _consider();
  }

  @override
  void didUpdateWidget(GuideHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    _consider();
  }

  /// Vera quando la schermata è davanti, visibile e finita di animarsi.
  bool _ready() {
    if (_done || _entry != null || !widget.enabled) return false;
    final guide = GuideScope.maybeOf(context);
    if (guide == null || !guide.shouldShow(widget.screen)) return false;
    if (!TickerMode.valuesOf(context).enabled || _offstage()) return false;
    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) return false;
    final animation = route?.animation;
    if (animation != null && !animation.isCompleted) {
      _watched?.removeStatusListener(_onRouteAnimation);
      _watched = animation..addStatusListener(_onRouteAnimation);
      return false;
    }
    return true;
  }

  /// Una scheda della barra fuori scena non mostra la guida.
  bool _offstage() {
    var off = false;
    context.visitAncestorElements((e) {
      final object = e is RenderObjectElement ? e.renderObject : null;
      if (object is RenderOffstage && object.offstage) {
        off = true;
        return false;
      }
      return true;
    });
    return off;
  }

  void _consider() {
    if (!_ready()) return;
    _quiet = 0;
    if (_waiting) return;
    _waiting = true;
    _wait();
  }

  void _wait() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (++_quiet < _quietFrames) {
        WidgetsBinding.instance.scheduleFrame();
        _wait();
        return;
      }
      _waiting = false;
      _show();
    });
  }

  void _onRouteAnimation(AnimationStatus status) {
    if (status == AnimationStatus.completed) _consider();
  }

  /// Gli elementi hanno cambiato posto: la guida rimisura il rettangolo.
  void _layoutChanged() {
    if (_entry == null || _layoutScheduled) return;
    _layoutScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _layoutScheduled = false;
      _layout.value++;
    });
  }

  void _show() {
    if (!_ready()) return;
    final l10n = AppLocalizations.of(context);
    final kid = SettingsScope.maybeOf(context)?.kidMode ?? false;
    final steps = [
      for (final s in widget.steps)
        GuidePage(targetKey: keyFor(s.anchor), text: s.text(l10n, kid)),
    ];
    // Senza nessun elemento in vista non c'è nulla da spiegare.
    if (!steps.any((s) => s.isUsable)) return;
    _entry = OverlayEntry(
      builder: (context) =>
          GuideOverlay(steps: steps, relayout: _layout, onClose: _close),
    );
    Overlay.of(context, rootOverlay: true).insert(_entry!);
    widget.onStart?.call();
    setState(() {});
  }

  void _close() {
    final entry = _entry;
    if (entry == null) return;
    entry.remove();
    entry.dispose();
    _entry = null;
    _done = true;
    unawaited(GuideScope.maybeOf(context)?.markSeen(widget.screen));
    widget.onEnd?.call();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _watched?.removeStatusListener(_onRouteAnimation);
    _entry?.remove();
    _entry?.dispose();
    _layout.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _HostScope(this, child: widget.child);
}
