param([string]$Version = '0.3.0')
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$out = Join-Path $root 'dist'
New-Item -ItemType Directory -Path $out -Force | Out-Null
$apk = Join-Path $root 'build/app/outputs/flutter-apk/app-release.apk'
if (-not (Test-Path -LiteralPath $apk)) { throw 'Build the release APK first.' }
Copy-Item -LiteralPath $apk -Destination (Join-Path $out "elTahi-demo-$Version.apk")
Copy-Item -LiteralPath (Join-Path $root 'assets/icon/app-icon.png') -Destination (Join-Path $out 'elTahi-icon.png')
Copy-Item -LiteralPath (Join-Path $root 'DEMO.md') -Destination (Join-Path $out 'DEMO.md')
Add-Type -AssemblyName System.IO.Compression
$zipPath = Join-Path $out "elTahi-demo-source-$Version.zip"
$temporaryZip = Join-Path $out (([guid]::NewGuid().ToString()) + '.zip')
$zip = [IO.Compression.ZipFile]::Open($temporaryZip, [IO.Compression.ZipArchiveMode]::Create)
try {
    Get-ChildItem -LiteralPath $root -File -Recurse -Force | ForEach-Object {
        $relative = [IO.Path]::GetRelativePath($root, $_.FullName).Replace('\', '/')
        if ($relative -match '(^|/)(build|dist|\.dart_tool|\.gradle|\.idea|\.cxx|\.kotlin|ephemeral|\.symlinks|Pods)(/|$)' -or
            $relative -match '(\.log|\.iml|\.jks|\.keystore)$' -or
            $relative -match '(local\.properties|key\.properties|Generated\.xcconfig|flutter_export_environment\.sh|\.flutter-plugins-dependencies)$') { return }
        [IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $_.FullName, "elTahi-demo/$relative", [IO.Compression.CompressionLevel]::Optimal) | Out-Null
    }
} finally { $zip.Dispose() }
Move-Item -LiteralPath $temporaryZip -Destination $zipPath -Force
Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $out "elTahi-demo-$Version.apk"), $zipPath | Format-Table
