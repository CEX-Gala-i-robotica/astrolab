# -- Load .env -----------------------------------------------------
$envFile = Get-Content .env

foreach ($line in $envFile) {
    if ($line -match '^\s*([^#][^=]+)=(.+)$') {
        $name = $Matches[1].Trim()
        $value = $Matches[2].Trim()
        Set-Item -Path "Env:$name" -Value $value
    }
}

# -- Dart defines --------------------------------------------------
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
    "--dart-define=GOOGLE_DESKTOP_CLIENT_SECRET=$($env:GOOGLE_DESKTOP_CLIENT_SECRET)"
)

# -- Meniu mod build -----------------------------------------------
function Get-BuildMode {
    Write-Host ""
    Write-Host "  +==================================+" -ForegroundColor Magenta
    Write-Host "  |         Mod de build             |" -ForegroundColor Magenta
    Write-Host "  +==================================+" -ForegroundColor Magenta
    Write-Host "  |                                  |" -ForegroundColor Magenta
    Write-Host "  |   1.  Release                    |" -ForegroundColor Magenta
    Write-Host "  |   2.  Debug                      |" -ForegroundColor Magenta
    Write-Host "  |   3.  Profile                    |" -ForegroundColor Magenta
    Write-Host "  |                                  |" -ForegroundColor Magenta
    Write-Host "  +==================================+" -ForegroundColor Magenta
    Write-Host ""

    $modeChoice = Read-Host "  Alege modul (1/2/3)"

    switch ($modeChoice) {
        "1" { return "--release" }
        "2" { return "--debug" }
        "3" { return "--profile" }
        default {
            Write-Host "  ! Optiune invalida, se foloseste Release." -ForegroundColor Yellow
            return "--release"
        }
    }
}

# -- Meniu principal -----------------------------------------------
Clear-Host
Write-Host ""
Write-Host "  +==================================+" -ForegroundColor Cyan
Write-Host "  |      Flutter Build Launcher      |" -ForegroundColor Cyan
Write-Host "  +==================================+" -ForegroundColor Cyan
Write-Host "  |                                  |" -ForegroundColor Cyan
Write-Host "  |   1.  Desktop Windows            |" -ForegroundColor Cyan
Write-Host "  |   2.  Web                        |" -ForegroundColor Cyan
Write-Host "  |   3.  Android (APK)              |" -ForegroundColor Cyan
Write-Host "  |   4.  Android (App Bundle / AAB) |" -ForegroundColor Cyan
Write-Host "  |                                  |" -ForegroundColor Cyan
Write-Host "  +==================================+" -ForegroundColor Cyan
Write-Host ""

$choice = Read-Host "  Alege platforma (1/2/3/4)"

switch ($choice) {

    "1" {
        $mode = Get-BuildMode
        Write-Host ""
        Write-Host "  >> Build Windows Desktop ($mode)..." -ForegroundColor Green
        Write-Host ""
        flutter build windows $mode @dartDefines
        if ($LASTEXITCODE -eq 0) {
            Write-Host ""
            Write-Host "  [OK] Build reusit! Output: build\windows\x64\runner\Release\" -ForegroundColor Green
        } else {
            Write-Host ""
            Write-Host "  [EROARE] Build esuat cu codul $LASTEXITCODE" -ForegroundColor Red
        }
    }

    "2" {
        $mode = Get-BuildMode
        Write-Host ""
        Write-Host "  >> Build Web ($mode)..." -ForegroundColor Green
        Write-Host ""
        flutter build web $mode @dartDefines
        if ($LASTEXITCODE -eq 0) {
            Write-Host ""
            Write-Host "  [OK] Build reusit! Output: build\web\" -ForegroundColor Green
        } else {
            Write-Host ""
            Write-Host "  [EROARE] Build esuat cu codul $LASTEXITCODE" -ForegroundColor Red
        }
    }

    "3" {
        $mode = Get-BuildMode
        Write-Host ""
        Write-Host "  >> Build Android APK ($mode)..." -ForegroundColor Green
        Write-Host ""
        $splitChoice = Read-Host "  Vrei APK split per ABI? (y/N)"
        if ($splitChoice -eq "y" -or $splitChoice -eq "Y") {
            flutter build apk $mode --split-per-abi @dartDefines
            if ($LASTEXITCODE -eq 0) {
                Write-Host ""
                Write-Host "  [OK] APK-uri split: build\app\outputs\flutter-apk\" -ForegroundColor Green
            }
        } else {
            flutter build apk $mode @dartDefines
            if ($LASTEXITCODE -eq 0) {
                Write-Host ""
                Write-Host "  [OK] APK universal: build\app\outputs\flutter-apk\app-release.apk" -ForegroundColor Green
            }
        }
        if ($LASTEXITCODE -ne 0) {
            Write-Host ""
            Write-Host "  [EROARE] Build esuat cu codul $LASTEXITCODE" -ForegroundColor Red
        }
    }

    "4" {
        $mode = Get-BuildMode
        Write-Host ""
        Write-Host "  >> Build Android App Bundle - AAB ($mode)..." -ForegroundColor Green
        Write-Host ""
        flutter build appbundle $mode @dartDefines
        if ($LASTEXITCODE -eq 0) {
            Write-Host ""
            Write-Host "  [OK] Build reusit! Output: build\app\outputs\bundle\release\app-release.aab" -ForegroundColor Green
        } else {
            Write-Host ""
            Write-Host "  [EROARE] Build esuat cu codul $LASTEXITCODE" -ForegroundColor Red
        }
    }

    default {
        Write-Host ""
        Write-Host "  X Optiune invalida. Ruleaza scriptul din nou." -ForegroundColor Red
        Write-Host ""
    }
}

Write-Host ""
Read-Host "  Apasa ENTER pentru a inchide"