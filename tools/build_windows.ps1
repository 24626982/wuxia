param([string]$GodotPath = '')
$ErrorActionPreference = 'Stop'
$projectDirectory = Split-Path -Parent $PSScriptRoot
if (-not $GodotPath) {
    $godotCommand = Get-Command godot, godot4 -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $godotCommand) { throw 'Specify -GodotPath with the path to your local Godot 4.7.2 executable.' }
    $GodotPath = $godotCommand.Source
}
if (-not (Test-Path -LiteralPath $GodotPath -PathType Leaf)) { throw 'The specified local Godot executable does not exist.' }
$buildDirectory = Join-Path $projectDirectory 'builds\windows'
New-Item -ItemType Directory -Path $buildDirectory -Force | Out-Null
& $GodotPath --headless --path $projectDirectory --editor --import --quit
if ($LASTEXITCODE -ne 0) { throw 'Local resource import failed.' }
& $GodotPath --headless --path $projectDirectory --export-release 'Windows Offline' (Join-Path $buildDirectory 'Wuxia.exe')
if ($LASTEXITCODE -ne 0) { throw 'Native export failed. Install the matching export templates locally, then retry.' }
Write-Output "Offline desktop build: $buildDirectory"
