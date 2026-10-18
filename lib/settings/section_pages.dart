import 'dart:async';

import 'package:flutter/material.dart';

import '../backup/backup_page.dart';
import '../guide/guide_host.dart';
import '../l10n/app_localizations.dart';
import '../progress/profile_page.dart';
import '../progress/progress_controller.dart';
import 'adult_gate.dart';
import 'app_language.dart';
import 'notation.dart';
import 'settings.dart';
import 'settings_labels.dart';
import 'settings_widgets.dart';

/// Pagina di una sezione delle Impostazioni: ogni interruttore ha sotto una
/// riga che dice cosa cambia.
abstract class _SectionPage extends StatelessWidget {
  const _SectionPage({super.key, required this.controller, this.progress});

  final SettingsController controller;

  /// Progressi che sbloccano temi e pezzi; senza, tutto è disponibile.
  final ProgressController? progress;

  Listenable get _listenable => Listenable.merge([controller, progress]);

  AppSettings get _s => controller.value;

  void _set(AppSettings Function(AppSettings) change) =>
      controller.update(change(controller.value));
}

class BoardSettingsPage extends _SectionPage {
  const BoardSettingsPage({
    super.key,
    required super.controller,
    super.progress,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SettingsSectionScaffold(
      title: l10n.settingsSectionBoard,
      listenable: _listenable,
      pinned: (_) => SettingsPreviewCard(settings: _s),
      builder: (context) {
        final s = _s;
        return [
          SwitchListTile(
            key: const Key('sound'),
            title: Text(l10n.settingsSound),
            subtitle: Text(l10n.settingsSoundDescription),
            value: s.sound,
            onChanged: (v) => _set((c) => c.copyWith(sound: v)),
          ),
          ListTile(
            title: Text(l10n.settingsVolume),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.settingsVolumeDescription),
                SettingsVolumeSlider(
                  value: s.volume,
                  enabled: s.sound,
                  onChangeEnd: (v) => _set((c) => c.copyWith(volume: v)),
                ),
              ],
            ),
          ),
          SwitchListTile(
            key: const Key('haptics'),
            title: Text(l10n.settingsHaptics),
            subtitle: Text(l10n.settingsHapticsDescription),
            value: s.haptics,
            onChanged: (v) => _set((c) => c.copyWith(haptics: v)),
          ),
          SwitchListTile(
            key: const Key('coordinates'),
            title: Text(l10n.settingsCoordinates),
            subtitle: Text(l10n.settingsCoordinatesDescription),
            value: s.showCoordinates,
            onChanged: (v) => _set((c) => c.copyWith(showCoordinates: v)),
          ),
          SwitchListTile(
            key: const Key('coordinatesOutside'),
            title: Text(l10n.settingsCoordinatesOutside),
            subtitle: Text(l10n.settingsCoordinatesOutsideDescription),
            value: s.coordinatesOutside,
            onChanged: s.showCoordinates
                ? (v) => _set((c) => c.copyWith(coordinatesOutside: v))
                : null,
          ),
          SwitchListTile(
            key: const Key('lastMove'),
            title: Text(l10n.settingsLastMove),
            subtitle: Text(l10n.settingsLastMoveDescription),
            value: s.showLastMove,
            onChanged: (v) => _set((c) => c.copyWith(showLastMove: v)),
          ),
          SwitchListTile(
            key: const Key('legalMoves'),
            title: Text(l10n.settingsLegalMoves),
            subtitle: Text(l10n.settingsLegalMovesDescription),
            value: s.showLegalMoves,
            onChanged: (v) => _set((c) => c.copyWith(showLegalMoves: v)),
          ),
          SwitchListTile(
            key: const Key('drawShapes'),
            title: Text(l10n.settingsDrawShapes),
            subtitle: Text(l10n.settingsDrawShapesDescription),
            value: s.drawShapes,
            onChanged: (v) => _set((c) => c.copyWith(drawShapes: v)),
          ),
          SettingsChoiceTile<MarkColor>(
            title: l10n.settingsMarkColor,
            description: l10n.settingsMarkColorDescription,
            values: MarkColor.values,
            selected: s.markColor,
            label: (c) => markColorLabel(l10n, c),
            onSelected: (c) => _set((s) => s.copyWith(markColor: c)),
          ),
          SettingsChoiceTile<AnimationSpeed>(
            title: l10n.settingsAnimations,
            description: l10n.settingsAnimationsDescription,
            values: AnimationSpeed.values,
            selected: s.animation,
            label: (a) => animationLabel(l10n, a),
            onSelected: (a) => _set((c) => c.copyWith(animation: a)),
          ),
          SettingsChoiceTile<MoveNotation>(
            title: l10n.settingsNotation,
            description: l10n.settingsNotationDescription,
            values: MoveNotation.values,
            selected: s.notation,
            label: (n) => notationLabel(l10n, n),
            onSelected: (n) => _set((c) => c.copyWith(notation: n)),
          ),
        ];
      },
    );
  }
}

class GameSettingsPage extends _SectionPage {
  const GameSettingsPage({
    super.key,
    required super.controller,
    super.progress,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SettingsSectionScaffold(
      title: l10n.settingsSectionGame,
      listenable: _listenable,
      builder: (context) {
        final s = _s;
        return [
          SettingsChoiceTile<MoveMethod>(
            title: l10n.settingsMoveMethod,
            description: l10n.settingsMoveMethodDescription,
            values: MoveMethod.values,
            selected: s.moveMethod,
            label: (m) => moveMethodLabel(l10n, m),
            onSelected: (m) => _set((s) => s.copyWith(moveMethod: m)),
          ),
          SwitchListTile(
            key: const Key('autoQueen'),
            title: Text(l10n.settingsAutoQueen),
            subtitle: Text(l10n.settingsAutoQueenDescription),
            value: s.autoQueen,
            onChanged: (v) => _set((c) => c.copyWith(autoQueen: v)),
          ),
          SwitchListTile(
            key: const Key('keepAwake'),
            title: Text(l10n.settingsKeepAwake),
            subtitle: Text(l10n.settingsKeepAwakeDescription),
            value: s.keepAwake,
            onChanged: (v) => _set((c) => c.copyWith(keepAwake: v)),
          ),
          SwitchListTile(
            key: const Key('autoFlip'),
            title: Text(l10n.settingsAutoFlip),
            subtitle: Text(l10n.settingsAutoFlipDescription),
            value: s.autoFlip,
            onChanged: (v) => _set((c) => c.copyWith(autoFlip: v)),
          ),
          SwitchListTile(
            key: const Key('premove'),
            title: Text(l10n.settingsPremove),
            subtitle: Text(l10n.settingsPremoveDescription),
            value: s.premove,
            onChanged: (v) => _set((c) => c.copyWith(premove: v)),
          ),
          SwitchListTile(
            key: const Key('evalBar'),
            title: Text(l10n.settingsEvalBar),
            subtitle: Text(l10n.settingsEvalBarDescription),
            value: s.evalBar,
            onChanged: (v) => _set((c) => c.copyWith(evalBar: v)),
          ),
          SwitchListTile(
            key: const Key('tableMode'),
            title: Text(l10n.settingsTableMode),
            subtitle: Text(l10n.settingsTableModeDescription),
            value: s.tableMode,
            onChanged: (v) => _set((c) => c.copyWith(tableMode: v)),
          ),
          SwitchListTile(
            key: const Key('explainWhy'),
            title: Text(l10n.settingsExplainWhy),
            subtitle: Text(l10n.settingsExplainWhyDescription),
            value: s.explainWhy,
            onChanged: (v) => _set((c) => c.copyWith(explainWhy: v)),
          ),
        ];
      },
    );
  }
}

class AccessibilitySettingsPage extends _SectionPage {
  const AccessibilitySettingsPage({
    super.key,
    required super.controller,
    super.progress,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final guides = GuideScope.maybeOf(context);
    return SettingsSectionScaffold(
      title: l10n.settingsSectionAccessibility,
      listenable: Listenable.merge([_listenable, guides]),
      pinned: (_) => SettingsPreviewCard(settings: _s),
      builder: (context) {
        final s = _s;
        return [
          SettingsChoiceTile<AppLanguage>(
            title: l10n.settingsLanguage,
            description: l10n.settingsLanguageDescription,
            values: AppLanguage.values,
            selected: s.language,
            label: (a) => languageLabel(l10n, a),
            onSelected: (a) => _set((c) => c.copyWith(language: a)),
          ),
          SettingsChoiceTile<ThemeMode>(
            title: l10n.settingsAppTheme,
            description: l10n.settingsAppThemeDescription,
            values: ThemeMode.values,
            selected: s.themeMode,
            label: (m) => themeModeLabel(l10n, m),
            onSelected: (m) => _set((c) => c.copyWith(themeMode: m)),
          ),
          SwitchListTile(
            key: const Key('colorBlind'),
            title: Text(l10n.settingsColorBlind),
            subtitle: Text(l10n.settingsColorBlindDescription),
            value: s.colorBlind,
            onChanged: (v) => _set((c) => c.copyWith(colorBlind: v)),
          ),
          SwitchListTile(
            key: const Key('zenMode'),
            title: Text(l10n.settingsZenMode),
            subtitle: Text(l10n.settingsZenModeDescription),
            value: s.zenMode,
            onChanged: (v) => _set((c) => c.copyWith(zenMode: v)),
          ),
          SwitchListTile(
            key: const Key('confirmMove'),
            title: Text(l10n.settingsConfirmMove),
            subtitle: Text(l10n.settingsConfirmMoveDescription),
            value: s.confirmMove,
            onChanged: (v) => _set((c) => c.copyWith(confirmMove: v)),
          ),
          if (guides != null) ...[
            SwitchListTile(
              key: const Key('guideEnabled'),
              title: Text(l10n.guideOptionEnabled),
              subtitle: Text(l10n.guideOptionEnabledDescription),
              value: guides.enabled,
              onChanged: guides.setEnabled,
            ),
            ListTile(
              key: const Key('guideReplay'),
              title: Text(l10n.guideOptionReplay),
              subtitle: Text(l10n.guideOptionReplayDescription),
              onTap: () {
                unawaited(guides.reset());
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(content: Text(l10n.guideOptionReplayDone)),
                  );
              },
            ),
          ],
        ];
      },
    );
  }
}

/// Profilo, progressi e copie di sicurezza; senza progressi resta il backup.
class ProfileSettingsPage extends _SectionPage {
  const ProfileSettingsPage({
    super.key,
    required super.controller,
    super.progress,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = progress;
    return SettingsSectionScaffold(
      title: l10n.settingsSectionProfile,
      listenable: _listenable,
      builder: (context) => [
        if (p != null) ...[
          ListTile(
            key: const Key('openProfile'),
            leading: const Icon(Icons.person_outline),
            title: Text(l10n.settingsOpenProfile),
            subtitle: Text(l10n.settingsOpenProfileDescription),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => ProfilePage(controller: p),
              ),
            ),
          ),
          // Scelta da adulti: nel profilo bambino non si cambia da qui.
          if (!_s.kidMode)
            SwitchListTile(
              key: const Key('progressEnabled'),
              title: Text(l10n.settingsProgressEnabled),
              subtitle: Text(l10n.settingsProgressEnabledDescription),
              value: p.settings.enabled,
              onChanged: (v) =>
                  p.updateSettings(p.settings.copyWith(enabled: v)),
            ),
        ],
        if (p != null && p.settings.enabled)
          SwitchListTile(
            key: const Key('unlockAll'),
            title: Text(l10n.settingsUnlockAll),
            subtitle: Text(l10n.settingsUnlockAllDescription),
            value: p.settings.unlockAll,
            onChanged: (v) async {
              // Sbloccare tutto toglie il percorso al bambino: serve un adulto.
              if (_s.kidMode && !await askAdult(context)) return;
              await p.updateSettings(p.settings.copyWith(unlockAll: v));
            },
          ),
        ListTile(
          key: const Key('backup'),
          leading: const Icon(Icons.backup_outlined),
          title: Text(l10n.settingsBackup),
          subtitle: Text(l10n.settingsBackupDescription),
          trailing: const Icon(Icons.chevron_right),
          onTap: () async {
            // Ripristinare una copia può sostituire i progressi.
            if (_s.kidMode && !await askAdult(context)) return;
            if (!context.mounted) return;
            final page = await BackupPage.system();
            if (context.mounted) {
              await Navigator.push(
                context,
                MaterialPageRoute<void>(builder: (_) => page),
              );
            }
          },
        ),
      ],
    );
  }
}

/// Profilo bambino (RP-06): per uscirne serve la domanda per adulti.
class KidSettingsPage extends _SectionPage {
  const KidSettingsPage({super.key, required super.controller, super.progress});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SettingsSectionScaffold(
      title: l10n.kidProfile,
      listenable: _listenable,
      builder: (context) => [
        SwitchListTile(
          key: const Key('kidMode'),
          title: Text(l10n.kidProfile),
          subtitle: Text(l10n.kidProfileDescription),
          value: _s.kidMode,
          onChanged: (v) async {
            if (!v && !await askAdult(context)) return;
            _set((c) => c.copyWith(kidMode: v));
          },
        ),
      ],
    );
  }
}
