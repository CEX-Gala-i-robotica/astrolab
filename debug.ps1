# ── Load .env ─────────────────────────────────────────────
$envFile = Get-Content .env

foreach ($line in $envFile) {
  if ($line -match '^\s*([^#][^=]+)=(.+)$') {
    $name = $Matches[1].Trim()
    $value = $Matches[2].Trim()
    Set-Item -Path "Env:$name" -Value $value
  }
}

# ── Dart defines (comune pentru toate platformele) ─────────
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
  "--dart-define=OAUTH_CALLBACK_SCHEME=$($env:OAUTH_CALLBACK_SCHEME)",
  "--dart-define=GOOGLE_DESKTOP_CLIENT_ID=$($env:GOOGLE_DESKTOP_CLIENT_ID)",
  "--dart-define=GOOGLE_DESKTOP_CLIENT_SECRET=$($env:GOOGLE_DESKTOP_CLIENT_SECRET)"
)

# ── Meniu ──────────────────────────────────────────────────
Clear-Host
Write-Host ""
Write-Host "  +==================================+" -ForegroundColor Cyan
Write-Host "  |      Flutter Run Launcher        |" -ForegroundColor Cyan
Write-Host "  +==================================+" -ForegroundColor Cyan
Write-Host "  |                                  |" -ForegroundColor Cyan
Write-Host "  |   1.  Desktop Windows            |" -ForegroundColor Cyan
Write-Host "  |   2.  Web (Chrome)               |" -ForegroundColor Cyan
Write-Host "  |   3.  Android                    |" -ForegroundColor Cyan
Write-Host "  |                                  |" -ForegroundColor Cyan
Write-Host "  +==================================+" -ForegroundColor Cyan
Write-Host ""

$choice = Read-Host "  Alege platforma (1/2/3)"

switch ($choice) {

  "1" {
    Write-Host ""
    Write-Host "  >> Pornesc pe Windows Desktop..." -ForegroundColor Green
    Write-Host ""
    flutter run -d windows @dartDefines
  }

  "2" {
    Write-Host ""
    Write-Host "  >> Pornesc pe Web (Chrome) pe portul 5000..." -ForegroundColor Green
    Write-Host ""
    flutter run -d chrome --web-port 5000 @dartDefines
  }

  "3" {
    Write-Host ""
    Write-Host "  +==================================================+" -ForegroundColor Yellow
    Write-Host "  |  Porneste emulatorul Android din Android Studio  |" -ForegroundColor Yellow
    Write-Host "  |  sau conecteaza un device fizic prin USB.        |" -ForegroundColor Yellow
    Write-Host "  |                                                  |" -ForegroundColor Yellow
    Write-Host "  |  Apasa ENTER cand emulatorul e pornit...         |" -ForegroundColor Yellow
    Write-Host "  +==================================================+" -ForegroundColor Yellow
    Write-Host ""
    Read-Host "  [ ENTER pentru a continua ]"

    Write-Host ""
    Write-Host "  >> Caut device-uri Android disponibile..." -ForegroundColor Cyan
    Write-Host ""
    flutter devices

    Write-Host ""
    $deviceId = Read-Host "  Introdu device ID-ul (sau apasa ENTER pentru auto-detect)"

    Write-Host ""
    Write-Host "  >> Pornesc pe Android..." -ForegroundColor Green
    Write-Host ""

    if ($deviceId -eq "") {
      flutter run -d android @dartDefines
    } else {
      flutter run -d $deviceId @dartDefines
    }
  }

  default {
    Write-Host ""
    Write-Host "  X Optiune invalida. Ruleaza scriptul din nou." -ForegroundColor Red
    Write-Host ""
  }
}