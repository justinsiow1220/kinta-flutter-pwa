param(
  [string]$BaseHref = '/kinta-pwa-test/',
  [string]$DeployPath = 'C:\xampp\htdocs\kinta-pwa-test'
)

$ErrorActionPreference = 'Stop'
if (-not $BaseHref.StartsWith('/') -or -not $BaseHref.EndsWith('/')) {
  throw 'BaseHref must begin and end with a slash, for example /kinta-pwa-test/.'
}

$projectRoot = Split-Path -Parent $PSScriptRoot
Push-Location $projectRoot
try {
  flutter build web --release --base-href $BaseHref
  if ($LASTEXITCODE -ne 0) {
    throw "Flutter web build failed with exit code $LASTEXITCODE."
  }

  $webRoot = Join-Path $projectRoot 'build/web'
  $workerPath = Join-Path $webRoot 'kinta_service_worker.js'
  if (-not (Test-Path $workerPath)) {
    throw 'The built KINTA service worker was not found in build/web.'
  }

  $chromeRendererFiles = @(
    'canvaskit/canvaskit.js',
    'canvaskit/canvaskit.wasm',
    'canvaskit/chromium/canvaskit.js',
    'canvaskit/chromium/canvaskit.wasm'
  )
  $files = Get-ChildItem -LiteralPath $webRoot -Recurse -File | ForEach-Object {
    $relative = $_.FullName.Substring($webRoot.Length).TrimStart('\').Replace('\', '/')
    if ($relative -eq 'kinta_service_worker.js' -or
        $relative -eq 'kinta_precache_manifest.json' -or
        $relative -eq 'flutter_service_worker.js' -or
        $relative.EndsWith('.symbols')) {
      return
    }
    if ($relative.StartsWith('canvaskit/') -and $relative -notin $chromeRendererFiles) {
      return
    }
    $relative
  } | Sort-Object -Unique

  $manifestJson = @{ version = [DateTime]::UtcNow.ToString('yyyyMMddHHmmss'); files = @($files) } |
    ConvertTo-Json -Depth 4 -Compress
  $manifestPath = Join-Path $webRoot 'kinta_precache_manifest.json'
  [System.IO.File]::WriteAllText($manifestPath, $manifestJson, [System.Text.UTF8Encoding]::new($false))

  $sha = [System.Security.Cryptography.SHA256]::Create()
  try {
    $digest = $sha.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($manifestJson))
    $hash = [BitConverter]::ToString($digest).Replace('-', '').Substring(0, 12).ToLowerInvariant()
  } finally {
    $sha.Dispose()
  }
  $worker = Get-Content -LiteralPath $workerPath -Raw
  $worker = $worker.Replace('__KINTA_BUILD_ID__', $hash)
  [System.IO.File]::WriteAllText($workerPath, $worker, [System.Text.UTF8Encoding]::new($false))

  New-Item -ItemType Directory -Force -Path $DeployPath | Out-Null
  Copy-Item -Path (Join-Path $webRoot '*') -Destination $DeployPath -Recurse -Force
  Write-Host "KINTA PWA copied to $DeployPath"
  Write-Host "App shell files pre-cached: $($files.Count)"
  Write-Host "Open: http://localhost$BaseHref"
} finally {
  Pop-Location
}