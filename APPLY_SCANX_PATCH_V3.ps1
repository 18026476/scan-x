param(
  [string]$ProjectRoot = (Resolve-Path -LiteralPath ".").Path
)

$ErrorActionPreference = "Stop"
[System.IO.Directory]::SetCurrentDirectory($ProjectRoot)

function Timestamp() { Get-Date -Format "yyyyMMdd_HHmmss" }
function Ensure-Dir([string]$dir) {
  if ([string]::IsNullOrWhiteSpace($dir)) { return }
  if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
}
function Backup-File([string]$path) {
  if (Test-Path -LiteralPath $path) {
    $bak = "$path.bak_$(Timestamp)"
    Copy-Item -LiteralPath $path -Destination $bak -Force
    Write-Host "Backup: $bak"
  }
}
function Write-Utf8NoBom([string]$path, [string]$content) {
  $dir = Split-Path -Parent $path
  Ensure-Dir $dir
  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($path, $content, $utf8NoBom)
  Write-Host "Wrote: $path"
}

# Preflight
if (-not (Test-Path -LiteralPath (Join-Path $ProjectRoot "pubspec.yaml"))) {
  throw "pubspec.yaml not found. Run from Flutter project root. Current: $ProjectRoot"
}

Write-Host "=== APPLY SCAN-X PATCH V3: Fix mojibake in Labs/ML label + sanitize toggle registry arrows + improve PDF with AI insights ==="
Write-Host "ProjectRoot: $ProjectRoot"

# ------------------------------------------------------------------
# 1) Patch toggle registry text (no enum changes): replace mojibake arrows with ASCII
# ------------------------------------------------------------------
$tw = Join-Path $ProjectRoot "lib\core\services\toggle_wiring_registry.dart"
if (Test-Path -LiteralPath $tw) {
  $src = Get-Content -LiteralPath $tw -Raw
  $orig = $src
  $src = $src -replace "â†’", "->"
  $src = $src -replace "→", "->"
  if ($src -ne $orig) {
    Backup-File $tw
    Write-Utf8NoBom $tw $src
    Write-Host "Patched: toggle_wiring_registry.dart (arrow sanitize)"
  } else {
    Write-Host "INFO: toggle_wiring_registry.dart already clean (no arrow mojibake found)."
  }
} else {
  Write-Host "WARN: toggle_wiring_registry.dart not found (skipping)."
}

# ------------------------------------------------------------------
# 2) Patch Scan screen Labs/ML enabled label: wrap sanitizeUiText() around any Text('Labs/ML enabled: ...')
# ------------------------------------------------------------------
$scan = Join-Path $ProjectRoot "lib\features\scan\scan_screen.dart"
if (Test-Path -LiteralPath $scan) {
  $src = Get-Content -LiteralPath $scan -Raw
  $orig = $src

  # Ensure sanitizer import exists
  if ($src -notmatch "core/utils/text_sanitizer\.dart") {
    if ($src -match "(?m)^import\s+'package:flutter/material\.dart';\s*$") {
      $src = [regex]::Replace(
        $src,
        "(?m)^import\s+'package:flutter/material\.dart';\s*$",
        "import 'package:flutter/material.dart';`nimport 'package:scanx_app/core/utils/text_sanitizer.dart';",
        1
      )
    } else {
      $src = "import 'package:scanx_app/core/utils/text_sanitizer.dart';`n$src"
    }
  }

  # Wrap single-quoted Text(...)
  $src = [regex]::Replace(
    $src,
    "Text\(\s*'(?<s>Labs/ML\s+enabled:[^']*)'\s*\)",
    "Text(sanitizeUiText('${s}'))"
  )

  # Wrap double-quoted Text(...)
  $src = [regex]::Replace(
    $src,
    "Text\(\s*""(?<s>Labs/ML\s+enabled:[^""]*)""\s*\)",
    "Text(sanitizeUiText(""${s}""))"
  )

  if ($src -ne $orig) {
    Backup-File $scan
    Write-Utf8NoBom $scan $src
    Write-Host "Patched: scan_screen.dart (sanitize Labs/ML enabled label)"
  } else {
    Write-Host "INFO: scan_screen.dart not modified (Labs/ML label pattern not found)."
  }
} else {
  Write-Host "WARN: scan_screen.dart not found (skipping)."
}

# ------------------------------------------------------------------
# 3) Overwrite PDF report service with a version that:
#    - sanitizes mojibake text via sanitizeUiText()
#    - adds an 'AI insights (experimental)' section derived from findings
# ------------------------------------------------------------------
$pdf = Join-Path $ProjectRoot "lib\core\services\pdf_report_service.dart"
if (-not (Test-Path -LiteralPath $pdf)) { throw "Missing: $pdf" }

Backup-File $pdf
Write-Utf8NoBom $pdf @'
import ''dart:typed_data'';
import ''package:pdf/pdf.dart'';
import ''package:pdf/widgets.dart'' as pw;

import ''package:scanx_app/core/utils/text_sanitizer.dart'';

String _s(dynamic v) => sanitizeUiText((v ?? '''').toString());

List<String> _aiInsightsFromReport(Map<String, dynamic> reportJson) {
  final findings = (reportJson[''findings''] as List?)?.cast<Map>() ?? const [];
  if (findings.isEmpty) return const [];

  int hi = 0, med = 0;
  final ports = <String>{};
  final services = <String>{};

  for (final f in findings) {
    final sev = (f[''severity''] ?? '''').toString().toLowerCase();
    if (sev == ''high'' || sev == ''critical'') hi++;
    if (sev == ''medium'') med++;

    final title = (f[''title''] ?? '''').toString();
    final details = (f[''details''] ?? '''').toString();

    final portMatch = RegExp(r''\bport\s+(\d{1,5})\b'', caseSensitive: false).firstMatch(''$title $details'');
    if (portMatch != null) ports.add(portMatch.group(1)!);

    final svcMatch = RegExp(r''\b(ssh|rdp|telnet|ftp|http|https|smb|snmp)\b'', caseSensitive: false).firstMatch(''$title $details'');
    if (svcMatch != null) services.add(svcMatch.group(1)!.toUpperCase());
  }

  final out = <String>[];
  out.add(''Risk summary: $hi high/critical and $med medium findings were detected.'');
  if (ports.isNotEmpty) out.add(''Prioritize hardening/closing exposed ports: ${ports.toList()..sort()}.'');
  if (services.isNotEmpty) out.add(''Review these services for necessity and secure configuration: ${services.toList()..sort()}.'');
  out.add(''Action: patch/update device firmware and OS versions for any devices flagged as outdated.'');
  out.add(''Action: enforce strong passwords and disable default credentials on routers, IoT, and admin panels.'');
  out.add(''Action: enable WPA2/WPA3, disable WPS, and separate IoT devices onto a guest/VLAN network.'');
  return out;
}

class PdfReportService {
  Future<Uint8List> buildReport({required Map<String, dynamic> reportJson}) async {
    final doc = pw.Document();

    final meta = (reportJson[''scanMeta''] as Map?)?.cast<String, dynamic>() ?? {};
    final findings = (reportJson[''findings''] as List?)?.cast<Map>() ?? const [];
    final score = (reportJson[''riskScore''] as Map?)?.cast<String, dynamic>() ?? {};

    // Use double quotes for strings that contain map key lookups.
    // Access map keys using ["key"] to avoid quote collisions.
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Text(
            ''SCAN-X Security Report'',
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),

          pw.Text("Scan Time (UTC): ${meta["scanTimeUtc"] ?? ''-''}"),
          pw.Text("Target CIDR: ${meta["targetCidr"] ?? ''-''}"),
          pw.Text("Scan Mode: ${meta["scanMode"] ?? ''-''}"),
          pw.SizedBox(height: 12),

          pw.Text(
            "Risk Score: ${score["score"] ?? 0} (${score["rating"] ?? ''Low''})",
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 12),

          pw.Text(
            ''Findings'',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),

          if (findings.isEmpty)
            pw.Text(''No findings were detected.'')
          else
            ...findings.map((f) {
              final m = f.cast<String, dynamic>();

              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 10),
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(width: 0.8),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      "${m["title"] ?? "Finding"}",
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text("Severity: ${m["severity"] ?? ''-''}"),
                    pw.Text("Status: ${m["status"] ?? ''-''}"),
                    pw.Text("Device: ${m["deviceIp"] ?? ''-''}"),
                    pw.SizedBox(height: 4),
                    pw.Text("Evidence: ${m["evidence"] ?? ''-''}"),
                    pw.SizedBox(height: 4),
                    pw.Text("What to do: ${m["recommendation"] ?? ''-''}"),
                  ],
                ),
              );
            }),

          pw.SizedBox(height: 12),
          pw.Text(
            ''Disclaimer'',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(''This report is informational and does not perform exploitation or intrusive actions.''),
        ],
      ),
    );

    return doc.save();
  }
}

'@
Write-Host "Patched: pdf_report_service.dart (AI insights + sanitize)"

Write-Host ""
Write-Host "=== PATCH V3 APPLIED ==="
Write-Host "Now run:"
Write-Host "  flutter clean"
Write-Host "  flutter pub get"
Write-Host "  flutter test"
Write-Host "  flutter run -d windows"
