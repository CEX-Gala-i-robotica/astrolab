$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$installersDir = Join-Path $root "installers"
$innoScript = Join-Path $root "astrolab.iss"

Set-Location $root
New-Item -ItemType Directory -Force -Path $installersDir | Out-Null

if (Test-Path ".env") {
    $envFile = Get-Content ".env"
    foreach ($line in $envFile) {
        if ($line -match '^\s*([^#][^=]+)=(.*)$') {
            $name = $Matches[1].Trim()
            $value = $Matches[2].Trim()
            Set-Item -Path "Env:$name" -Value $value
        }
    }
}

$dartDefines = @(
    "--dart-define=FIREBASE_API_KEY_WEB=$($env:FIREBASE_API_KEY_WEB)",
    "--dart-define=FIREBASE_API_KEY_ANDROID=$($env:FIREBASE_API_KEY_ANDROID)",
    "--dart-define=FIREBASE_API_KEY_IOS=$($env:FIREBASE_API_KEY_IOS)",
    "--dart-define=FIREBASE_APP_ID_ANDROID=$($env:FIREBASE_APP_ID_ANDROID)",
    "--dart-define=FIREBASE_APP_ID_IOS=$($env:FIREBASE_APP_ID_IOS)",
    "--dart-define=FIREBASE_APP_ID_WEB=$($env:FIREBASE_APP_ID_WEB)",
    "--dart-define=FIREBASE_APP_ID_WINDOWS=$($env:FIREBASE_APP_ID_WINDOWS)",
    "--dart-define=FIREBASE_MESSAGING_SENDER_ID=$($env:FIREBASE_MESSAGING_SENDER_ID)",
    "--dart-define=FIREBASE_PROJECT_ID=$($env:FIREBASE_PROJECT_ID)",
    "--dart-define=FIREBASE_STORAGE_BUCKET=$($env:FIREBASE_STORAGE_BUCKET)",
    "--dart-define=FIREBASE_AUTH_DOMAIN=$($env:FIREBASE_AUTH_DOMAIN)",
    "--dart-define=FIREBASE_IOS_BUNDLE_ID=$($env:FIREBASE_IOS_BUNDLE_ID)",
    "--dart-define=FIREBASE_DB_URL=$($env:FIREBASE_DB_URL)",
    "--dart-define=GOOGLE_WEB_CLIENT_ID=$($env:GOOGLE_WEB_CLIENT_ID)",
    "--dart-define=ASTRONOMY_API_APP_ID=$($env:ASTRONOMY_API_APP_ID)",
    "--dart-define=ASTRONOMY_API_APP_SECRET=$($env:ASTRONOMY_API_APP_SECRET)",
    "--dart-define=OAUTH_CALLBACK_SCHEME=$($env:OAUTH_CALLBACK_SCHEME)",
    "--dart-define=GOOGLE_DESKTOP_CLIENT_ID=$($env:GOOGLE_DESKTOP_CLIENT_ID)",
    "--dart-define=GOOGLE_DESKTOP_CLIENT_SECRET=$($env:GOOGLE_DESKTOP_CLIENT_SECRET)",
    "--dart-define=GEMINI_API_KEY=$($env:GEMINI_API_KEY)"
)

function Invoke-Checked {
    param(
        [Parameter(Mandatory = $true)][string]$Label,
        [Parameter(Mandatory = $true)][scriptblock]$Command
    )

    Write-Host ""
    Write-Host "  >> $Label" -ForegroundColor Green
    Write-Host ""
    & $Command
    if ($LASTEXITCODE -ne 0) {
        throw "$Label failed with exit code $LASTEXITCODE"
    }
}

function Get-BuildMode {
    Write-Host ""
    Write-Host "  +==================================+" -ForegroundColor Magenta
    Write-Host "  |         Build mode               |" -ForegroundColor Magenta
    Write-Host "  +==================================+" -ForegroundColor Magenta
    Write-Host "  |   1.  Release                    |" -ForegroundColor Magenta
    Write-Host "  |   2.  Debug                      |" -ForegroundColor Magenta
    Write-Host "  |   3.  Profile                    |" -ForegroundColor Magenta
    Write-Host "  +==================================+" -ForegroundColor Magenta
    Write-Host ""

    $modeChoice = Read-Host "  Alege modul (1/2/3)"
    switch ($modeChoice) {
        "2" { return "--debug" }
        "3" { return "--profile" }
        default { return "--release" }
    }
}

function Get-WindowsConfigFromMode {
    param([string]$Mode)
    switch ($Mode) {
        "--debug" { return "Debug" }
        "--profile" { return "Profile" }
        default { return "Release" }
    }
}

function Find-InnoCompiler {
    if ($env:INNO_SETUP_ISCC -and (Test-Path $env:INNO_SETUP_ISCC)) {
        return $env:INNO_SETUP_ISCC
    }

    $command = Get-Command "ISCC.exe" -ErrorAction SilentlyContinue
    if ($command) {
        return $command.Source
    }

    $candidates = @(
        "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe",
        "$env:ProgramFiles\Inno Setup 6\ISCC.exe",
        "${env:ProgramFiles(x86)}\Inno Setup 5\ISCC.exe",
        "$env:ProgramFiles\Inno Setup 5\ISCC.exe"
    )

    foreach ($candidate in $candidates) {
        if ($candidate -and (Test-Path $candidate)) {
            return $candidate
        }
    }

    return $null
}

function Build-WindowsInstaller {
    param([string]$Mode)

    $config = Get-WindowsConfigFromMode $Mode
    $sourceDir = Join-Path $root "build\windows\x64\runner\$config"
    $exePath = Join-Path $sourceDir "astrolab.exe"

    if (!(Test-Path $exePath)) {
        throw "Windows executable not found: $exePath"
    }

    $iscc = Find-InnoCompiler
    if (!$iscc) {
        Write-Host ""
        Write-Host "  ! Inno Setup Compiler was not found. Install Inno Setup 6 or set INNO_SETUP_ISCC." -ForegroundColor Yellow
        Write-Host "  ! Windows build exists, but installer was not generated." -ForegroundColor Yellow
        return
    }

    $env:ASTROLAB_WINDOWS_SOURCE_DIR = $sourceDir
    $env:ASTROLAB_INSTALLERS_DIR = $installersDir
    $env:ASTROLAB_INSTALLER_VERSION = "1.0.0"

    Invoke-Checked "Build Windows installer with Inno Setup" {
        & $iscc $innoScript
    }

    Write-Host ""
    Write-Host "  [OK] Windows installer: installers\astrolab.exe" -ForegroundColor Green
}

function Copy-AndroidApk {
    $source = Join-Path $root "build\app\outputs\flutter-apk\app-release.apk"
    if (!(Test-Path $source)) {
        $source = Join-Path $root "build\app\outputs\flutter-apk\app-debug.apk"
    }
    if (!(Test-Path $source)) {
        $source = Join-Path $root "build\app\outputs\flutter-apk\app-profile.apk"
    }
    if (!(Test-Path $source)) {
        throw "APK not found in build\app\outputs\flutter-apk"
    }

    $dest = Join-Path $installersDir "astrolab.apk"
    Copy-Item -LiteralPath $source -Destination $dest -Force
    Write-Host ""
    Write-Host "  [OK] Android APK copied to installers\astrolab.apk" -ForegroundColor Green
}

function Trigger-GitHubPagesWorkflow {
    $gh = Get-Command "gh" -ErrorAction SilentlyContinue
    if (!$gh) {
        Write-Host ""
        Write-Host "  ! GitHub CLI not found. Install gh and authenticate to trigger the Pages workflow automatically." -ForegroundColor Yellow
        return
    }

    $branch = (git rev-parse --abbrev-ref HEAD).Trim()
    if (!$branch) {
        $branch = "main"
    }

    Invoke-Checked "Trigger GitHub Pages workflow on branch $branch" {
        gh workflow run deploy-gh-pages.yml --ref $branch
    }

    Write-Host ""
    Write-Host "  [OK] GitHub Pages workflow triggered." -ForegroundColor Green
}

Clear-Host
Write-Host ""
Write-Host "  +==================================+" -ForegroundColor Cyan
Write-Host "  |      Flutter Build Launcher      |" -ForegroundColor Cyan
Write-Host "  +==================================+" -ForegroundColor Cyan
Write-Host "  |   1.  Desktop Windows + installer|" -ForegroundColor Cyan
Write-Host "  |   2.  Web + GitHub Pages workflow|" -ForegroundColor Cyan
Write-Host "  |   3.  Android APK + installers   |" -ForegroundColor Cyan
Write-Host "  |   4.  Android App Bundle / AAB   |" -ForegroundColor Cyan
Write-Host "  |   5.  Full release pack          |" -ForegroundColor Cyan
Write-Host "  +==================================+" -ForegroundColor Cyan
Write-Host ""

$choice = Read-Host "  Alege platforma (1/2/3/4/5)"

try {
    switch ($choice) {
        "1" {
            $mode = Get-BuildMode
            Invoke-Checked "Build Windows Desktop ($mode)" {
                flutter build windows $mode @dartDefines
            }
            Build-WindowsInstaller $mode
        }

        "2" {
            $mode = Get-BuildMode
            Invoke-Checked "Build Web ($mode)" {
                flutter build web $mode --base-href="/astrolab/" @dartDefines
            }
            Write-Host ""
            Write-Host "  [OK] Web build: build\web\" -ForegroundColor Green
            Trigger-GitHubPagesWorkflow
        }

        "3" {
            $mode = Get-BuildMode
            Invoke-Checked "Build Android APK ($mode)" {
                flutter build apk $mode @dartDefines
            }
            Copy-AndroidApk
        }

        "4" {
            $mode = Get-BuildMode
            Invoke-Checked "Build Android App Bundle ($mode)" {
                flutter build appbundle $mode @dartDefines
            }
            $source = Join-Path $root "build\app\outputs\bundle\release\app-release.aab"
            if (Test-Path $source) {
                Copy-Item -LiteralPath $source -Destination (Join-Path $installersDir "astrolab.aab") -Force
                Write-Host ""
                Write-Host "  [OK] Android AAB copied to installers\astrolab.aab" -ForegroundColor Green
            }
        }

        "5" {
            Invoke-Checked "Build Windows Desktop (--release)" {
                flutter build windows --release @dartDefines
            }
            Build-WindowsInstaller "--release"

            Invoke-Checked "Build Android APK (--release)" {
                flutter build apk --release @dartDefines
            }
            Copy-AndroidApk

            Invoke-Checked "Build Web (--release)" {
                flutter build web --release --base-href="/astrolab/" @dartDefines
            }
            Trigger-GitHubPagesWorkflow
        }

        default {
            Write-Host ""
            Write-Host "  X Optiune invalida. Ruleaza scriptul din nou." -ForegroundColor Red
        }
    }
}
catch {
    Write-Host ""
    Write-Host "  [EROARE] $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "  Output local: $installersDir" -ForegroundColor Cyan
Read-Host "  Apasa ENTER pentru a inchide"
