$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

function Section($t){
    Write-Host ""
    Write-Host "=== $t ===" -ForegroundColor Cyan
}

function Save-File($path,$content){
    $dir = Split-Path -Parent $path
    if($dir -and !(Test-Path $dir)){
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
    }
    Set-Content -LiteralPath $path -Value $content -Encoding UTF8
}

# Logging
$ts = Get-Date -Format "yyyyMMdd_HHmmss"
$logRoot = Join-Path ".\release_test_logs" $ts
New-Item -ItemType Directory -Force -Path $logRoot | Out-Null

# Locate Release
function Find-ReleaseRoot{
    Get-ChildItem ".\build\windows" -Recurse -Filter "scanx_app.exe" -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -match "\\runner\\Release\\scanx_app\.exe$" } |
    Select-Object -First 1 |
    ForEach-Object { Split-Path $_.FullName -Parent }
}

Section "Locate Release"

$relRoot = Find-ReleaseRoot
if(!$relRoot){
    flutter build windows --release | Out-Host
    $relRoot = Find-ReleaseRoot
    if(!$relRoot){ throw "Release not found." }
}

$tools = Join-Path $relRoot "tools\nmap"
$nmap  = Join-Path $tools "nmap.exe"
if(!(Test-Path $nmap)){ throw "Bundled Nmap missing." }

Write-Host "✓ Release + bundled Nmap validated" -ForegroundColor Green

# Remove system Nmap from PATH
$originalPath = $env:Path
$env:Path = ($env:Path -split ';' | Where-Object { $_ -notmatch "Nmap" }) -join ';'

# Detect physical LAN
Section "Detect Physical LAN"

$routes = Get-NetRoute -DestinationPrefix "0.0.0.0/0" | Sort-Object RouteMetric
$primary = $null

foreach($r in $routes){
    $adapter = Get-NetAdapter -InterfaceIndex $r.InterfaceIndex
    if($adapter.Status -eq "Up" -and
       $adapter.HardwareInterface -eq $true -and
       $adapter.InterfaceDescription -notmatch "Virtual|VMware|Hyper-V|VirtualBox|vEthernet|Docker|WSL"){
        $primary = $r
        break
    }
}

if(!$primary){ throw "No physical LAN found." }

$ipInfo = Get-NetIPAddress -InterfaceIndex $primary.InterfaceIndex -AddressFamily IPv4 |
          Where-Object { $_.IPAddress -notmatch "^169\.254" } |
          Select-Object -First 1

$parts = $ipInfo.IPAddress.Split('.')
$subnet = "$($parts[0]).$($parts[1]).$($parts[2]).0/24"
Write-Host "Using subnet: $subnet" -ForegroundColor Yellow

# Discover live hosts
Section "Discover Live Hosts"
$live = & $nmap "--datadir" $tools "-n" "-sn" $subnet 2>&1
$liveIPs = @()

foreach($line in ($live -split "`r?`n")){
    if($line -match "^Nmap scan report for\s+(\d{1,3}(\.\d{1,3}){3})"){
        $liveIPs += $Matches[1]
    }
}

if($liveIPs.Count -eq 0){ throw "No live hosts detected." }

Write-Host "✓ Live hosts: $($liveIPs.Count)" -ForegroundColor Green

# Find SMB host
Section "Detect SMB Host"
$smbHost = $null

foreach($ip in $liveIPs){
    $scan = & $nmap "--datadir" $tools "-n" "-Pn" "-p" "445" "--open" $ip 2>&1
    if(($scan | Out-String) -match "445/tcp\s+open"){
        $smbHost = $ip
        break
    }
}

if(!$smbHost){ throw "No SMB host found." }

Write-Host "✓ SMB Host Found: $smbHost" -ForegroundColor Green

# Structured XML scan
Section "Structured XML Scan"
$xmlPath = Join-Path $logRoot "smb_scan.xml"

& $nmap "--datadir" $tools "-n" "-Pn" "-sV" `
        "-p" "445" `
        "--script" "smb-os-discovery" `
        "-oX" $xmlPath `
        $smbHost | Out-Null

$env:Path = $originalPath

# Robust XML parsing
Section "Parse XML"

[xml]$xml = Get-Content $xmlPath
$hostNode = $xml.nmaprun.host
$portNode = $hostNode.ports.port | Where-Object { $_.portid -eq "445" }

$portOpen = ($portNode.state.state -eq "open")
$smbDetected = $portOpen

$osIdentified = $false
$enumRestricted = $false
$computerName = $null
$domain = $null

$scripts = @()

if($hostNode.hostscript.script){ $scripts += $hostNode.hostscript.script }
if($portNode.script){ $scripts += $portNode.script }

foreach($script in $scripts){
    if($script.id -eq "smb-os-discovery"){
        foreach($elem in $script.elem){
            if($elem.key -eq "os"){ $osIdentified = $true }
            if($elem.key -eq "computer_name"){ $computerName = $elem.'#text' }
            if($elem.key -eq "domain"){ $domain = $elem.'#text' }
        }
        if(-not $osIdentified){ $enumRestricted = $true }
    }
}

# Classification
if($smbDetected -and $osIdentified){
    $classification = "SMB (Confirmed + OS Identified)"
}
elseif($smbDetected -and $enumRestricted){
    $classification = "SMB (Confirmed – Enumeration Restricted / Hardened)"
}
elseif($smbDetected){
    $classification = "SMB (Service Detected)"
}
else{
    $classification = "SMB Not Detected"
}

$result = [ordered]@{
    host = $smbHost
    port_445_open = $portOpen
    smb_detected = $smbDetected
    os_identified = $osIdentified
    enumeration_restricted = $enumRestricted
    computer_name = $computerName
    domain = $domain
    classification = $classification
}

$jsonPath = Join-Path $logRoot "smb_result.json"
$result | ConvertTo-Json -Depth 5 | Set-Content $jsonPath -Encoding UTF8

Write-Host ""
Write-Host "==== FINAL STRUCTURED RESULT ====" -ForegroundColor Cyan
$result | ConvertTo-Json -Depth 5
Write-Host ""
Write-Host "Logs folder: $logRoot"
