import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/settings_service.dart';

class AiLabsTab extends StatefulWidget {
  const AiLabsTab({super.key});
  @override
  State<AiLabsTab> createState() => _AiLabsTabState();
}

class _AiLabsTabState extends State<AiLabsTab> {
  static const _kAiMaster = 'scanx.ai.assistant';
  static const _kExplain = 'scanx.ai.explain_vulns';
  static const _kFixes = 'scanx.ai.guided_fixes';
  static const _kRisk = 'scanx.ai.risk_scoring';
  static const _kRouterPlaybooks = 'scanx.ai.router_playbooks';
  static const _kUnnecessary = 'scanx.ai.unnecessary_services';
  static const _kProactive = 'scanx.ai.proactive_warnings';

  static const _kSnifferLite = 'scanx.lab.sniffer_lite';
  static const _kWifiDeauth = 'scanx.lab.wifi_deauth';
  static const _kRogueAp = 'scanx.lab.rogue_ap';
  static const _kHiddenSsid = 'scanx.lab.hidden_ssid';
  static const _kBehaviourMl = 'scanx.ml.behaviour_threat';
  static const _kLocalMl = 'scanx.ml.local_profiling';
  static const _kIotFp = 'scanx.ml.iot_fingerprinting';

  bool _loaded = false;

  bool aiMaster = true;
  bool explain = true;
  bool fixes = true;

  bool risk = true;
  bool routerPlaybooks = true;
  bool unnecessary = true;
  bool proactive = true;

  bool snifferLite = false;
  bool wifiDeauth = false;
  bool rogueAp = false;
  bool hiddenSsid = false;

  bool behaviourMl = false;
  bool localMl = false;
  bool iotFp = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      aiMaster = p.getBool(_kAiMaster) ?? true;
      explain = p.getBool(_kExplain) ?? true;
      fixes = p.getBool(_kFixes) ?? true;

      risk = p.getBool(_kRisk) ?? true;
      routerPlaybooks = p.getBool(_kRouterPlaybooks) ?? true;
      unnecessary = p.getBool(_kUnnecessary) ?? true;
      proactive = p.getBool(_kProactive) ?? true;

      snifferLite = p.getBool(_kSnifferLite) ?? false;
      wifiDeauth = p.getBool(_kWifiDeauth) ?? false;
      rogueAp = p.getBool(_kRogueAp) ?? false;
      hiddenSsid = p.getBool(_kHiddenSsid) ?? false;

      behaviourMl = p.getBool(_kBehaviourMl) ?? false;
      localMl = p.getBool(_kLocalMl) ?? false;
      iotFp = p.getBool(_kIotFp) ?? false;

      _loaded = true;
    });
    _syncIntoSettingsService();
  }

  Future<void> _setBool(String key, bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(key, value);
    _syncIntoSettingsService();
  }

  void _syncIntoSettingsService() {
    try {
      final s = SettingsService() as dynamic;

      try {
        if ((s.setBool is Function)) {
          s.setBool(_kAiMaster, aiMaster);
          s.setBool(_kExplain, explain);
          s.setBool(_kFixes, fixes);
          s.setBool(_kRisk, risk);
          s.setBool(_kRouterPlaybooks, routerPlaybooks);
          s.setBool(_kUnnecessary, unnecessary);
          s.setBool(_kProactive, proactive);
          s.setBool(_kSnifferLite, snifferLite);
          s.setBool(_kWifiDeauth, wifiDeauth);
          s.setBool(_kRogueAp, rogueAp);
          s.setBool(_kHiddenSsid, hiddenSsid);
          s.setBool(_kBehaviourMl, behaviourMl);
          s.setBool(_kLocalMl, localMl);
          s.setBool(_kIotFp, iotFp);
          return;
        }
      } catch (_) {}

      try {
        if ((s.updateSetting is Function)) {
          s.updateSetting(_kAiMaster, aiMaster);
          s.updateSetting(_kExplain, explain);
          s.updateSetting(_kFixes, fixes);
          s.updateSetting(_kRisk, risk);
          s.updateSetting(_kRouterPlaybooks, routerPlaybooks);
          s.updateSetting(_kUnnecessary, unnecessary);
          s.updateSetting(_kProactive, proactive);
          s.updateSetting(_kSnifferLite, snifferLite);
          s.updateSetting(_kWifiDeauth, wifiDeauth);
          s.updateSetting(_kRogueAp, rogueAp);
          s.updateSetting(_kHiddenSsid, hiddenSsid);
          s.updateSetting(_kBehaviourMl, behaviourMl);
          s.updateSetting(_kLocalMl, localMl);
          s.updateSetting(_kIotFp, iotFp);
          return;
        }
      } catch (_) {}
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (!_loaded) return const Center(child: CircularProgressIndicator());

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
      children: [
        Text('AI assistant', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),

        SwitchListTile(
          title: const Text('SCAN-X AI assistant', style: TextStyle(fontWeight: FontWeight.w800)),
          subtitle: const Text('Explains findings and suggests next steps in plain language.'),
          value: aiMaster,
          onChanged: (v) async {
            setState(() => aiMaster = v);
            await _setBool(_kAiMaster, v);

            if (!v) {
              setState(() { explain = false; fixes = false; });
              await _setBool(_kExplain, false);
              await _setBool(_kFixes, false);
            }
          },
        ),

        Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.outlineVariant.withOpacity(0.6)),
          ),
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Explain vulnerabilities', style: TextStyle(fontWeight: FontWeight.w800)),
                subtitle: const Text('Shows €œwhat this means€ cards for each issue.'),
                value: explain,
                onChanged: aiMaster ? (v) async { setState(() => explain = v); await _setBool(_kExplain, v); } : null,
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: const Text('Guided fixes', style: TextStyle(fontWeight: FontWeight.w800)),
                subtitle: const Text('Provides safe step-by-step recommendations.'),
                value: fixes,
                onChanged: aiMaster ? (v) async { setState(() => fixes = v); await _setBool(_kFixes, v); } : null,
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),
        Text('Advanced', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text('Most users can leave these ON. Turn OFF only if you want fewer suggestions.',
          style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 10),

        ExpansionTile(
          title: Text('AI analysis options', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
          subtitle: const Text('Controls risk scoring and router guidance.'),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Container(
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cs.outlineVariant.withOpacity(0.6)),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('AI-driven risk scoring', style: TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: const Text('Smarter overall network health score.'),
                    value: risk,
                    onChanged: aiMaster ? (v) async { setState(() => risk = v); await _setBool(_kRisk, v); } : null,
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Router hardening playbooks', style: TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: const Text('Generates router lock-down checklists.'),
                    value: routerPlaybooks,
                    onChanged: aiMaster ? (v) async { setState(() => routerPlaybooks = v); await _setBool(_kRouterPlaybooks, v); } : null,
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Detect unnecessary services', style: TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: const Text('Flags risky services rarely needed at home.'),
                    value: unnecessary,
                    onChanged: aiMaster ? (v) async { setState(() => unnecessary = v); await _setBool(_kUnnecessary, v); } : null,
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Proactive warnings', style: TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: const Text('Warns before issues become high-risk.'),
                    value: proactive,
                    onChanged: aiMaster ? (v) async { setState(() => proactive = v); await _setBool(_kProactive, v); } : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
