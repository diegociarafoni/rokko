import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// Un passo pronto da mostrare: l'elemento e il testo già tradotto.
class GuidePage {
  const GuidePage({required this.targetKey, required this.text});

  final GlobalKey targetKey;
  final String text;

  RenderBox? get _box {
    final object = targetKey.currentContext?.findRenderObject();
    return object is RenderBox && object.attached && object.hasSize
        ? object
        : null;
  }

  /// Vero se l'elemento è sulla schermata (non assente, non nascosto).
  bool get isUsable => _box != null && !_box!.size.isEmpty;
}

/// Oscura la schermata, lascia in luce l'elemento del passo e mostra la
/// spiegazione con «Salta» e «Avanti».
class GuideOverlay extends StatefulWidget {
  const GuideOverlay({super.key, required this.steps, required this.onClose});

  final List<GuidePage> steps;
  final VoidCallback onClose;

  @override
  State<GuideOverlay> createState() => _GuideOverlayState();
}

class _GuideOverlayState extends State<GuideOverlay>
    with WidgetsBindingObserver {
  late GuidePage _current;
  Rect? _target;

  /// I passi il cui elemento c'è ora: quelli che arrivano con i dati si
  /// aggiungono, quelli di funzioni assenti non contano.
  List<GuidePage> get _usable => [
    for (final s in widget.steps)
      if (s == _current || s.isUsable) s,
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _current = widget.steps.firstWhere((s) => s.isUsable);
    _enter();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() => _measure();

  /// Porta l'elemento in vista e ne misura il rettangolo a layout finito.
  void _enter() {
    final context = _current.targetKey.currentContext;
    final object = context?.findRenderObject();
    if (context != null && object != null) {
      Scrollable.maybeOf(context)?.position
          .ensureVisible(object, alignment: 0.35);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  void _measure() {
    if (!mounted) return;
    final box = _current._box;
    final rect = box == null ? null : box.localToGlobal(Offset.zero) & box.size;
    if (rect != _target) setState(() => _target = rect);
  }

  void _next() {
    final steps = widget.steps;
    final after = steps.skip(steps.indexOf(_current) + 1);
    final next = after.where((s) => s.isUsable).firstOrNull;
    if (next == null) {
      widget.onClose();
      return;
    }
    setState(() {
      _current = next;
      _target = null;
    });
    _enter();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final target = _target?.inflate(6);
    final usable = _usable;
    final index = usable.indexOf(_current);
    final last = !widget.steps
        .skip(widget.steps.indexOf(_current) + 1)
        .any((s) => s.isUsable);
    final card = Material(
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.guideStepCounter(index + 1, usable.length),
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            // Il testo scorre se, ingrandito, non sta nello spazio che resta.
            Flexible(
              child: SingleChildScrollView(
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    _current.text,
                    key: const Key('guide-text'),
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                TextButton(
                  key: const Key('guide-skip'),
                  onPressed: widget.onClose,
                  child: Text(l10n.guideSkip),
                ),
                FilledButton(
                  key: const Key('guide-next'),
                  onPressed: _next,
                  child: Text(last ? l10n.guideDone : l10n.guideNext),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    final left = 16 + padding.left;
    final right = 16 + padding.right;
    // Dalla parte con più spazio; se nessuna ne ha abbastanza la scheda sta in
    // fondo allo schermo e copre un po' l'elemento.
    final roomBelow = target == null
        ? 0.0
        : size.height - padding.bottom - target.bottom - 20;
    final roomAbove = target == null ? 0.0 : target.top - padding.top - 20;
    const needed = 190.0;
    final placeBelow =
        target != null &&
        roomBelow >= needed &&
        (roomBelow >= roomAbove || roomAbove < needed);
    final placeAbove = target != null && !placeBelow && roomAbove >= needed;
    final cardArea = Positioned(
      left: left,
      right: right,
      top: placeBelow
          ? target.bottom + 12
          : (target == null ? size.height * 0.3 : null),
      bottom: placeAbove
          ? size.height - target.top + 12
          : (!placeBelow && target != null ? padding.bottom + 8 : null),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: placeBelow
              ? roomBelow
              : placeAbove
              ? roomAbove
              : size.height * 0.62,
        ),
        child: card,
      ),
    );
    return BlockSemantics(
      child: Stack(
        children: [
          Positioned.fill(
            // Un tocco fuori dalla scheda non attraversa verso la schermata.
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
              child: CustomPaint(
                painter: _ScrimPainter(
                  hole: target,
                  color: Colors.black.withValues(alpha: 0.72),
                ),
              ),
            ),
          ),
          cardArea,
        ],
      ),
    );
  }
}

class _ScrimPainter extends CustomPainter {
  const _ScrimPainter({required this.hole, required this.color});

  final Rect? hole;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final full = Path()..addRect(Offset.zero & size);
    final cut = hole;
    final path = cut == null
        ? full
        : Path.combine(
            PathOperation.difference,
            full,
            Path()..addRRect(
              RRect.fromRectAndRadius(cut, const Radius.circular(14)),
            ),
          );
    canvas.drawPath(path, Paint()..color = color);
    if (cut != null) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(cut, const Radius.circular(14)),
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(_ScrimPainter old) =>
      old.hole != hole || old.color != color;
}
