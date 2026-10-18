import 'package:flutter/material.dart';

import '../about/about_page.dart';
import '../guide/guide_host.dart';
import '../guide/guide_steps.dart';
import '../l10n/app_localizations.dart';
import '../progress/progress_controller.dart';
import '../style/style_page.dart';
import '../theme/rokko_theme.dart';
import '../theme/sheets.dart';
import 'section_pages.dart';
import 'settings.dart';
import 'settings_search.dart';

/// Voci del menu delle Impostazioni, nell'ordine in cui compaiono; il profilo
/// bambino e le informazioni stanno in fondo, separati.
enum SettingsSection { profile, style, board, game, accessibility, kid, about }

/// Menu di sezioni: icona, nome e una riga che dice cosa contiene. Le
/// impostazioni stanno nelle pagine delle sezioni; il campo in cima cerca una
/// voce per nome e porta alla sua sezione.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.controller, this.progress});

  final SettingsController controller;

  /// Progressi che sbloccano temi e pezzi; senza, tutto è disponibile e il
  /// Profilo ha solo il backup.
  final ProgressController? progress;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _search = TextEditingController();

  SettingsController get controller => widget.controller;
  ProgressController? get progress => widget.progress;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Widget _page(SettingsSection section) => switch (section) {
    SettingsSection.profile => ProfileSettingsPage(
      controller: controller,
      progress: progress,
    ),
    SettingsSection.style => StylePage(
      controller: controller,
      progress: progress,
    ),
    SettingsSection.board => BoardSettingsPage(
      controller: controller,
      progress: progress,
    ),
    SettingsSection.game => GameSettingsPage(
      controller: controller,
      progress: progress,
    ),
    SettingsSection.accessibility => AccessibilitySettingsPage(
      controller: controller,
      progress: progress,
    ),
    SettingsSection.kid => KidSettingsPage(
      controller: controller,
      progress: progress,
    ),
    SettingsSection.about => const AboutPage(),
  };

  (IconData, String, String) _entry(
    AppLocalizations l10n,
    SettingsSection section,
  ) => switch (section) {
    SettingsSection.profile => (
      Icons.person_outline,
      l10n.settingsSectionProfile,
      l10n.settingsSectionProfileHint,
    ),
    SettingsSection.style => (
      Icons.palette_outlined,
      l10n.styleTitle,
      l10n.styleEntrySubtitle,
    ),
    SettingsSection.board => (
      Icons.grid_on,
      l10n.settingsSectionBoard,
      l10n.settingsSectionBoardHint,
    ),
    SettingsSection.game => (
      Icons.sports_esports_outlined,
      l10n.settingsSectionGame,
      l10n.settingsSectionGameHint,
    ),
    SettingsSection.accessibility => (
      Icons.accessibility_new,
      l10n.settingsSectionAccessibility,
      l10n.settingsSectionAccessibilityHint,
    ),
    SettingsSection.kid => (
      Icons.child_care,
      l10n.kidProfile,
      l10n.kidProfileDescription,
    ),
    SettingsSection.about => (
      Icons.info_outline,
      l10n.aboutTitle,
      l10n.aboutEntrySubtitle,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = RokkoTokens.of(context);
    const sections = SettingsSection.values;
    void open(SettingsSection section) {
      // Senza, la tastiera della ricerca riappare al ritorno.
      FocusScope.of(context).unfocus();
      Navigator.push(
        context,
        MaterialPageRoute<void>(builder: (_) => _page(section)),
      );
    }

    Widget tile(SettingsSection section) {
      final (icon, title, hint) = _entry(l10n, section);
      return GuideAnchor(
        id: 'settings.${section.name}',
        child: ListTile(
          key: Key('section-${section.name}'),
          leading: Icon(icon, color: tokens.action),
          title: Text(title),
          subtitle: Text(hint),
          trailing: const Icon(Icons.chevron_right),
          minTileHeight: tokens.minTouch,
          onTap: () => open(section),
        ),
      );
    }

    return GuideHost(
      screen: 'settings',
      steps: settingsGuide,
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.settingsTitle)),
        body: ListenableBuilder(
          listenable: _search,
          builder: (context, _) {
            final query = _search.text;
            final hits = settingsHits(
              l10n,
              query,
              hasProgress: progress != null,
            );
            return ListView(
              scrollCacheExtent: guideCacheExtent(context, 'settings'),
              padding: context.withSystemBottom(
                const EdgeInsets.only(bottom: 24),
              ),
              children: [
                GuideAnchor(
                  id: 'settings.search',
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: TextField(
                      key: const Key('settingsSearch'),
                      controller: _search,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: l10n.settingsSearchHint,
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: query.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.close),
                                tooltip: l10n.settingsSearchClear,
                                onPressed: _search.clear,
                              ),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                ),
                if (query.trim().isEmpty)
                  for (final s in sections)
                    if (s == SettingsSection.kid) ...[
                      const Divider(height: 24),
                      tile(s),
                    ] else
                      tile(s)
                else if (hits.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      l10n.settingsSearchEmpty,
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  for (final h in hits)
                    ListTile(
                      title: Text(h.title),
                      subtitle: switch (h.sectionTitle == h.title
                          ? h.description
                          : h.sectionTitle) {
                        final String text when text.isNotEmpty => Text(text),
                        _ => null,
                      },
                      trailing: const Icon(Icons.chevron_right),
                      minTileHeight: tokens.minTouch,
                      onTap: () => open(h.section),
                    ),
              ],
            );
          },
        ),
      ),
    );
  }
}
