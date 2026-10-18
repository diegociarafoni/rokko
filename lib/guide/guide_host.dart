import 'dart:async';

import 'package:flutter/material.dart';

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
    // Gli elementi che arrivano dopo i dati risvegliano una guida in attesa.
    context.getInheritedWidgetOfExactType<_HostScope>()?.state._consider();
  }

  @override
  Widget build(BuildContext context) {
    final host = context.getInheritedWidgetOfExactType<_HostScope>()?.state;
    if (host == null) return widget.child;
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
  });

  /// Identificativo salvato quando la guida è stata vista.
  final String screen;
  final List<GuideStep> steps;
  final Widget child;

  /// Falso quando la schermata è sotto un'altra (per esempio la scheda Home
  /// mentre è aperta un'altra scheda).
  final bool enabled;

  @override
  State<GuideHost> createState() => GuideHostState();
}

class GuideHostState extends State<GuideHost> {
  final Map<String, GlobalKey> _keys = {};
  OverlayEntry? _entry;
  bool _done = false;
  bool _scheduled = false;
  Animation<double>? _watched;

  GlobalKey keyFor(String id) => _keys.putIfAbsent(id, GlobalKey.new);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _consider();
  }

  @override
  void didUpdateWidget(GuideHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    _consider();
  }

  /// Parte quando la schermata è davanti, visibile e finita di animarsi.
  void _consider() {
    if (_done || _entry != null || _scheduled || !widget.enabled) return;
    final guide = GuideScope.maybeOf(context);
    if (guide == null || !guide.shouldShow(widget.screen)) return;
    if (!TickerMode.valuesOf(context).enabled) return;
    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) return;
    final animation = route?.animation;
    if (animation != null && !animation.isCompleted) {
      _watched?.removeStatusListener(_onRouteAnimation);
      _watched = animation..addStatusListener(_onRouteAnimation);
      return;
    }
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (mounted) _show();
    });
  }

  void _onRouteAnimation(AnimationStatus status) {
    if (status == AnimationStatus.completed) _consider();
  }

  void _show() {
    if (_done || _entry != null || !widget.enabled) return;
    final guide = GuideScope.maybeOf(context);
    if (guide == null || !guide.shouldShow(widget.screen)) return;
    final l10n = AppLocalizations.of(context);
    final kid = SettingsScope.maybeOf(context)?.kidMode ?? false;
    final steps = [
      for (final s in widget.steps)
        GuidePage(targetKey: keyFor(s.anchor), text: s.text(l10n, kid)),
    ];
    // Finché nessun elemento è in vista (dati in arrivo) si aspetta.
    if (!steps.any((s) => s.isUsable)) return;
    _entry = OverlayEntry(
      builder: (context) => GuideOverlay(steps: steps, onClose: _close),
    );
    Overlay.of(context, rootOverlay: true).insert(_entry!);
    setState(() {});
  }

  void _close() {
    _entry?.remove();
    _entry = null;
    _done = true;
    unawaited(GuideScope.maybeOf(context)?.markSeen(widget.screen));
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _watched?.removeStatusListener(_onRouteAnimation);
    _entry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _HostScope(
    this,
    // Il tasto indietro chiude la guida, non la schermata.
    child: PopScope(
      canPop: _entry == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: widget.child,
    ),
  );
}
