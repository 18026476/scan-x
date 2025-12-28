param(
  [Parameter(Mandatory=$true)]
  [string]$ProjectRoot
)

$ErrorActionPreference = "Stop"

function Write-Utf8NoBom([string]$path, [string]$content) {
  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($path, $content, $utf8NoBom)
}

$ProjectRoot = [System.IO.Path]::GetFullPath($ProjectRoot)
$dash = Join-Path $ProjectRoot "lib\features\dashboard\dashboard_screen.dart"
if (-not (Test-Path -LiteralPath $dash)) { throw "Not found: $dash" }

$bak = "$dash.bak_$(Get-Date -Format yyyyMMdd_HHmmss)"
Copy-Item -LiteralPath $dash -Destination $bak -Force
Write-Host "Backup: $bak"

$text = Get-Content -LiteralPath $dash -Raw

# Ensure shared_preferences import exists
if ($text -notmatch "package:shared_preferences/shared_preferences\.dart") {
  $text = $text -replace "(import\s+['""]package:flutter/material\.dart['""];\s*)", "`$1`r`nimport 'package:shared_preferences/shared_preferences.dart';`r`n"
  Write-Host "Added shared_preferences import."
}

# Patch _loadAiToggles() ONLY if it exists (no injection)
$loadPattern = "Future<void>\s+_loadAiToggles\s*\(\s*\)\s*async\s*\{[\s\S]*?\}"
if ($text -match $loadPattern) {
  $newLoad = @"
Future<void> _loadAiToggles() async {
  final p = await SharedPreferences.getInstance();

  bool r(String newKey, String oldKey, bool def) =>
      p.getBool(newKey) ?? p.getBool(oldKey) ?? def;

  setState(() {
    _aiAssistantEnabled =
        r('scanx.ai.assistant', 'aiAssistantEnabled', true);

    _aiExplainVulnsEnabled =
        r('scanx.ai.explain_vulns', 'aiExplainVuln', true);

    _aiOneClickFixesEnabled =
        r('scanx.ai.guided_fixes', 'aiOneClickFix', true);

    _aiRiskScoringEnabled =
        r('scanx.ai.risk_scoring', 'aiRiskScoring', true);

    _aiRouterPlaybooksEnabled =
        r('scanx.ai.router_playbooks', 'aiRouterHardening', true);

    _aiUnnecessaryServicesEnabled =
        r('scanx.ai.unnecessary_services', 'aiDetectUnnecessaryServices', true);

    _aiProactiveWarningsEnabled =
        r('scanx.ai.proactive_warnings', 'aiProactiveWarnings', true);
  });
}
"@
  $text = [System.Text.RegularExpressions.Regex]::Replace($text, $loadPattern, $newLoad)
  Write-Host "Patched _loadAiToggles() to read new + legacy keys."
} else {
  Write-Host "WARN: _loadAiToggles() not found. No toggle-loader patch applied."
}

# Replace the hardcoded OFF string with a neutral placeholder (string replacement is safe)
$text = $text -replace "AI assistant is OFF in Settings\. Turn it ON to see insights and\s*recommendations\.", "AI assistant status is loading..."

# Now replace that placeholder with a DART ternary expression string.
# IMPORTANT: This is a literal Dart snippet inside a Dart string; we are not executing _aiAssistantEnabled in PowerShell.
$text = $text -replace "AI assistant status is loading\.\.\.", "' + (_aiAssistantEnabled ? 'AI assistant is ON. Run a scan to generate insights.' : 'AI assistant is OFF in Settings. Turn it ON to see insights and recommendations.') + '"

Write-Utf8NoBom -path $dash -content $text
Write-Host "Updated: $dash"
Write-Host "DONE"
