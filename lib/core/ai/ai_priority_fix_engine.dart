// lib/core/ai/ai_priority_fix_engine.dart
//
// SCAN-X AI Priority Fix Engine
// Deterministic, explainable, no ML required.
// Picks ONE high-impact fix that improves security fastest.

import '../services/scan_service.dart';

class PriorityFixRecommendation {
  final String title;
  final String why;
  final String actionSteps;
  final int estimatedHealthGain; // 0..30
  final int estimatedRiskReduction; // 0..90

  const PriorityFixRecommendation({
    required this.title,
    required this.why,
    required this.actionSteps,
    required this.estimatedHealthGain,
    required this.estimatedRiskReduction,
  });
}

class AiPriorityFixEngine {
  static PriorityFixRecommendation? recommend(ScanResult result) {
    if (result.hosts.isEmpty) return null;

    final portCounts = <int, int>{};
    bool hasHighRisk = false;

    for (final h in result.hosts) {
      if (h.risk == RiskLevel.high) hasHighRisk = true;
      for (final p in h.openPorts) {
        portCounts[p.port] = (portCounts[p.port] ?? 0) + 1;
      }
    }

    final candidates = <_FixCandidate>[
      _FixCandidate(
        port: 23,
        title: 'Disable Telnet access',
        why: 'Telnet is unencrypted and frequently targeted by botnets.',
        steps: 'Disable Telnet. Use SSH (22) with strong credentials instead.',
        baseHealthGain: 18,
        baseRiskReduction: 60,
        criticalBoost: 30,
      ),
      _FixCandidate(
        port: 3389,
        title: 'Restrict Remote Desktop (RDP)',
        why: 'RDP is commonly brute-forced and abused.',
        steps: 'Disable RDP or restrict it to LAN/VPN only.',
        baseHealthGain: 16,
        baseRiskReduction: 55,
        criticalBoost: 25,
      ),
      _FixCandidate(
        port: 445,
        title: 'Restrict Windows file sharing (SMB)',
        why: 'SMB exposure enables lateral movement and ransomware.',
        steps: 'Disable SMB where possible. Disable SMBv1.',
        baseHealthGain: 14,
        baseRiskReduction: 45,
        criticalBoost: 20,
      ),
      _FixCandidate(
        port: 1900,
        title: 'Disable UPnP',
        why: 'UPnP may automatically expose services externally.',
        steps: 'Disable UPnP in router settings.',
        baseHealthGain: 12,
        baseRiskReduction: 35,
        criticalBoost: 10,
      ),
    ];

    _FixCandidate? best;
    int bestScore = -1;

    for (final c in candidates) {
      final count = portCounts[c.port] ?? 0;
      if (count == 0) continue;

      int score = count * 10 + c.criticalBoost;
      if (hasHighRisk) score += c.baseRiskReduction ~/ 6;

      if (score > bestScore) {
        bestScore = score;
        best = c;
      }
    }

    if (best == null) return null;

    final exposure = portCounts[best.port] ?? 1;

    return PriorityFixRecommendation(
      title: best.title,
      why: best.why,
      actionSteps: best.steps,
      estimatedHealthGain:
          (best.baseHealthGain + (exposure - 1) * 2).clamp(6, 30),
      estimatedRiskReduction:
          (best.baseRiskReduction + (exposure - 1) * 5).clamp(15, 90),
    );
  }
}

class _FixCandidate {
  final int port;
  final String title;
  final String why;
  final String steps;
  final int baseHealthGain;
  final int baseRiskReduction;
  final int criticalBoost;

  const _FixCandidate({
    required this.port,
    required this.title,
    required this.why,
    required this.steps,
    required this.baseHealthGain,
    required this.baseRiskReduction,
    required this.criticalBoost,
  });
}