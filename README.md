# AstroLab

AstroLab este o platformă educațională interactivă dedicată astronomiei, dezvoltată cu Flutter. Aplicația oferă lecții structurate pe module și capitole, quizuri adaptive, un sistem de progres și clasament, simulări astronomice în timp real și generare de diplome. Platforma este disponibilă pe Web, Android, iOS, Windows, macOS și Linux.

---

# Cuprins

1. [Descrierea proiectului](#1-descrierea-proiectului)
2. [Tehnologii utilizate](#2-tehnologii-utilizate)
3. [Arhitectura aplicației](#3-arhitectura-aplicației)
4. [Funcționalități principale](#4-funcționalități-principale)
5. [Instalare și rulare locală](#5-instalare-și-rulare-locală)
6. [Variabile de mediu](#6-variabile-de-mediu)
7. [Structura proiectului](#7-structura-proiectului)
8. [Testare](#8-testare)
9. [Deployment automat](#9-deployment-automat)
10. [Licențiere](#10-licențiere)

---

# 1. Descrierea proiectului

AstroLab își propune să transforme studiul astronomiei într-o experiență accesibilă, interactivă și captivantă pentru elevii de gimnaziu și liceu. Conținutul educațional este organizat în module tematice, precum Sistemul Solar, stelele, galaxiile sau fenomenele cosmice, fiecare modul fiind împărțit în capitole și lecții.

Fiecare lecție include:

* conținut teoretic;
* exerciții interactive;
* quizuri de verificare;
* suport pentru formule matematice și notații LaTeX.

Aplicația include și un test de plasament asistat de inteligență artificială, realizat cu Google Gemini, care analizează nivelul utilizatorului și recomandă un punct de pornire personalizat în curriculum.

## Probleme rezolvate de AstroLab

* Lipsa unei platforme moderne de învățare a astronomiei în limba română.
* Lipsa feedback-ului imediat și personalizat în procesul de învățare.
* Dificultatea de a vizualiza fenomene astronomice fără echipamente specializate.
* Accesul limitat la resurse interactive și simulări astronomice educaționale.

---

# 2. Tehnologii utilizate

## Framework principal — Flutter / Dart

AstroLab este dezvoltat cu Flutter, ceea ce permite utilizarea unei singure baze de cod pentru toate platformele suportate:

* Web
* Android
* iOS
* Windows
* macOS
* Linux

Flutter a fost ales datorită:

* performanței native;
* interfeței moderne bazate pe Material 3;
* ecosistemului extins de pachete;
* suportului excelent pentru aplicații multiplatformă.

---

## Backend și autentificare — Firebase

Aplicația utilizează Firebase pentru:

* autentificare;
* stocarea progresului utilizatorilor;
* clasamente;
* relații de prietenie;
* sincronizarea datelor în timp real.

### Servicii Firebase utilizate

* Firebase Authentication
* Firebase Realtime Database
* Firebase Storage

Cheile și configurațiile Firebase sunt injectate la compilare prin `--dart-define`, fără a fi hardcodate în codul sursă.

---

## Inteligență artificială — Google Gemini API

Gemini este utilizat în cadrul serviciului `PlacementService` pentru:

* evaluarea răspunsurilor utilizatorului;
* estimarea nivelului de cunoștințe;
* recomandarea unui traseu educațional personalizat.

---

## Date astronomice în timp real — AstronomyAPI

`AstronomyApiService` comunică cu `api.astronomyapi.com` pentru a obține:

* pozițiile planetelor;
* fazele Lunii;
* hărți stelare și constelații;
* evenimente astronomice.

Datele sunt generate pe baza coordonatelor geografice și a datei selectate de utilizator.

---

## Randare matematică — flutter_math_fork

Formulele matematice și expresiile LaTeX sunt randate nativ în aplicație, inclusiv:

* formule inline (`$...$`);
* formule display (`$$...$$`).

---

## Generare PDF — pdf + printing

Aplicația poate genera diplome personalizate în format PDF pentru:

* finalizarea capitolelor;
* finalizarea modulelor;
* realizări speciale.

Diplomele pot fi descărcate, salvate sau tipărite direct din aplicație.

---

## Persistență locală — shared_preferences

Datele sesiunii sunt stocate local:

* token-uri de autentificare;
* profilul utilizatorului;
* opțiunea „Remember me”.

Acest lucru permite autentificarea automată la redeschiderea aplicației.

---

## Design și fonturi — google_fonts

AstroLab utilizează:

* o temă întunecată cu accente cosmice;
* fonturi moderne prin `google_fonts`;
* un sistem centralizat de culori și stiluri.

---

# 3. Arhitectura aplicației

Proiectul utilizează o arhitectură modulară pe straturi, fără framework extern de state management, bazându-se pe:

* `StatefulWidget`;
* propagarea stării prin constructori;
* separarea clară a responsabilităților.

```text
lib/
  main.dart
  models/
  data/
  services/
  screens/
  widgets/
  theme/
  utils/
```

---

## Stratul de modele (`models/`)

Conține clasele de date:

* `Module`
* `Chapter`
* `QuizQuestion`
* `QuizOption`
* `AnswerField`

Modelele sunt:

* imutabile;
* independente de UI;
* fără logică de business.

---

## Stratul de date (`data/`)

`CurriculumParser`:

* transformă fișierele JSON în obiecte Dart;
* validează structura curriculumului;
* aruncă excepții pentru date invalide.

`CurriculumRepository`:

* încarcă modulele;
* păstrează datele în cache pe durata sesiunii.

---

## Stratul de servicii (`services/`)

| Serviciu              | Responsabilitate                           |
| --------------------- | ------------------------------------------ |
| `AuthService`         | Autentificare email/parolă și Google OAuth |
| `SessionService`      | Persistența sesiunii locale                |
| `ProgressService`     | Gestionarea progresului și a scorului      |
| `LeaderboardService`  | Clasamente și prietenii                    |
| `PlacementService`    | Test de plasament cu AI                    |
| `AstronomyApiService` | Date astronomice în timp real              |

Toate apelurile de rețea utilizează `async/await`, iar erorile sunt tratate prin excepții dedicate.

---

## Stratul de ecrane (`screens/`)

Fiecare ecran reprezintă un flux distinct al aplicației:

* `HomeScreen` — pagina principală publică;
* `AuthScreen` — autentificare și înregistrare;
* `DashboardScreen` — hub-ul principal al utilizatorului;
* `LessonsScreen` — listă de module și capitole;
* `LessonScreen` — afișarea lecțiilor;
* `QuizScreen` — quiz interactiv;
* `QuizAnalysisScreen` — analiză detaliată a răspunsurilor;
* `LeaderboardScreen` — clasament global;
* `CuriosityCornerScreen` — simulări și informații astronomice;
* `AchievementsScreen` — diplome și realizări.

---

## Stratul de widget-uri (`widgets/`)

Componente reutilizabile:

* `CosmicBackground`
* `LatexMixed`
* `GlowingButton`
* `ChapterPathWidget`
* `HeroSection`
* `Navbar`
* `LessonTableWidget`

Acestea contribuie la:

* consistența interfeței;
* reutilizarea codului;
* separarea logicii UI.

---

# 4. Funcționalități principale

## Curriculum structurat

Conținutul educațional este organizat în:

* module;
* capitole;
* lecții;
* quizuri;
* teste finale.

Datele sunt definite în fișiere JSON și pot fi actualizate fără modificarea codului aplicației.

---

## Quizuri interactive

Sunt suportate mai multe tipuri de întrebări:

* alegere multiplă;
* răspuns numeric cu toleranță;
* răspuns text.

Utilizatorul primește:

* feedback imediat;
* explicații pentru răspunsurile corecte;
* analiză detaliată la final.

---

## Test de plasament cu AI

Google Gemini analizează răspunsurile utilizatorului și stabilește:

* nivelul de dificultate recomandat;
* capitolul de pornire;
* lecțiile potrivite nivelului său.

---

## Sistem de progres și scor

Aplicația urmărește:

* lecțiile finalizate;
* quizurile completate;
* scorul total;
* realizările utilizatorului.

Datele sunt sincronizate în Firebase Realtime Database.

---

## Clasament și sistem social

Utilizatorii pot:

* vedea clasamentul global;
* trimite cereri de prietenie;
* accepta prieteni;
* compara scorurile cu prietenii.

---

## Simulări astronomice

`CuriosityCornerScreen` oferă:

* poziții planetare;
* fazele Lunii;
* hărți ale constelațiilor;
* simulări astronomice generate dinamic.

---

## Diplome PDF

La finalizarea capitolelor sau modulelor, utilizatorii pot genera diplome personalizate în format PDF.

---

# 5. Instalare și rulare locală

## Cerințe preliminare

* Flutter SDK `3.44.0` sau mai nou
* Dart SDK `3.10.4` sau mai nou
* Proiect Firebase configurat
* Cont AstronomyAPI
* Cheie Google Gemini API

---

## Instalare

### 1. Clonarea repository-ului

```bash
git clone https://github.com/<user>/astrolab.git
cd astrolab
```

---

### 2. Instalarea dependențelor

```bash
flutter pub get
```

---

### 3. Configurarea variabilelor de mediu

```bash
cp .env.example .env
```

Completează fișierul `.env` cu valorile corespunzătoare.

---

### 4. Rularea aplicației Web

```bash
flutter run -d chrome \
  --dart-define=FIREBASE_API_KEY_WEB=<valoare> \
  --dart-define=FIREBASE_APP_ID_WEB=<valoare> \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=<valoare> \
  --dart-define=FIREBASE_PROJECT_ID=<valoare> \
  --dart-define=FIREBASE_AUTH_DOMAIN=<valoare> \
  --dart-define=FIREBASE_DB_URL=<valoare> \
  --dart-define=GOOGLE_WEB_CLIENT_ID=<valoare> \
  --dart-define=GEMINI_API_KEY=<valoare> \
  --dart-define=ASTRONOMY_API_APP_ID=<valoare> \
  --dart-define=ASTRONOMY_API_APP_SECRET=<valoare>
```

---

## Build release Web

```bash
flutter build web --release --base-href="/" --dart-define=...
```

---

## Build Windows

Poți utiliza scriptul PowerShell:

```powershell
.\build.ps1
```

---

# 6. Variabile de mediu

Toate secretele aplicației sunt injectate la compilare și nu sunt stocate în codul sursă.

| Variabilă                  | Descriere                      |
| -------------------------- | ------------------------------ |
| `FIREBASE_API_KEY_WEB`     | Cheia Firebase pentru Web      |
| `FIREBASE_API_KEY_ANDROID` | Cheia Firebase pentru Android  |
| `FIREBASE_API_KEY_IOS`     | Cheia Firebase pentru iOS      |
| `FIREBASE_APP_ID_WEB`      | ID aplicație Firebase Web      |
| `FIREBASE_APP_ID_ANDROID`  | ID aplicație Firebase Android  |
| `FIREBASE_APP_ID_IOS`      | ID aplicație Firebase iOS      |
| `FIREBASE_PROJECT_ID`      | ID proiect Firebase            |
| `FIREBASE_DB_URL`          | URL Firebase Realtime Database |
| `GOOGLE_WEB_CLIENT_ID`     | Client ID OAuth Google         |
| `GOOGLE_DESKTOP_CLIENT_ID` | Client ID OAuth Desktop        |
| `GEMINI_API_KEY`           | Cheie Google Gemini API        |
| `ASTRONOMY_API_APP_ID`     | App ID AstronomyAPI            |
| `ASTRONOMY_API_APP_SECRET` | Secret AstronomyAPI            |

---

# 7. Structura proiectului

```text
astrolab/
  lib/
    models/
    data/
    services/
    screens/
    widgets/
    theme/
    utils/

  assets/
    curriculum/
    certificates/
    images/

  test/

  .github/
    workflows/

  android/
  ios/
  web/
  windows/
  linux/
  macos/
```

---

# 8. Testare

Proiectul include teste automate pentru:

* parsarea curriculumului;
* logica progresului;
* parserul conținutului lecțiilor;
* randarea aplicației.

## Rulare teste

```bash
flutter test
```

---

# 9. Deployment automat

Pipeline-ul CI/CD GitHub Actions:

* rulează la fiecare push pe `main`;
* instalează Flutter;
* verifică secretele necesare;
* construiește versiunea Web;
* publică aplicația pe GitHub Pages.

Fișier:

```text
.github/workflows/deploy-gh-pages.yml
```

Toate secretele sunt stocate în GitHub Secrets și nu apar în cod sau în log-urile de build.

---

# 10. Licențiere

Acest proiect este distribuit sub licența MIT.

## Biblioteci și dependențe utilizate

* Flutter — BSD 3-Clause
* Firebase SDK — Apache 2.0
* google_sign_in — BSD 3-Clause
* flutter_math_fork — Apache 2.0
* pdf / printing — Apache 2.0

Lista completă a dependențelor este disponibilă în `pubspec.yaml`.
