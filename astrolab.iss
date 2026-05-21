#pragma code_page(65001)
#define MyAppName "AstroLab"
#define MyAppVersion GetEnv("ASTROLAB_INSTALLER_VERSION")
#if MyAppVersion == ""
  #define MyAppVersion "1.0.0"
#endif
#define MyAppPublisher "AstroLab"
#define MyAppURL "https://github.com/CEX-Gala-i-robotica/astrolab"
#define MyAppExeName "astrolab.exe"
#define SourceDir GetEnv("ASTROLAB_WINDOWS_SOURCE_DIR")
#define OutputDirValue GetEnv("ASTROLAB_INSTALLERS_DIR")

[Setup]
AppId={{86F7158B-5A88-4F8E-A808-2F2692F34F1D}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion} Setup Wizard
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
UninstallDisplayIcon={app}\{#MyAppExeName}
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
OutputDir={#OutputDirValue}
OutputBaseFilename=astrolab
SetupIconFile=windows\runner\resources\app_icon.ico
SolidCompression=yes
WizardStyle=modern
DisableWelcomePage=no
DisableDirPage=no
DisableProgramGroupPage=no

[Languages]
Name: "romanian"; MessagesFile: "compiler:Languages\Romanian.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[CustomMessages]
romanian.WelcomeLabel1=Instalare AstroLab
romanian.WelcomeLabel2=Platformă interactivă pentru astronomie și astrofizică
romanian.WelcomeLabel3=Bine ai venit în AstroLab. Acest installer va instala aplicația desktop pentru Windows, cu lecții, exerciții aplicative, quiz-uri, clasamente, diplome și instrumente astronomice.%n%nApasă Următorul pentru a începe instalarea.
romanian.LoadingComponents=Se încarcă instalatorul...
english.WelcomeLabel1=AstroLab Installation
english.WelcomeLabel2=Interactive astronomy and astrophysics platform
english.WelcomeLabel3=Welcome to AstroLab. This wizard will install the Windows desktop app with lessons, applied exercises, quizzes, leaderboards, certificates, and astronomy tools.%n%nClick Next to begin the installation.
english.LoadingComponents=Loading installer...

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "{#SourceDir}\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#SourceDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

[Code]
var
  SplashPage: TForm;
  SplashLabel: TLabel;
  SplashProgress: TNewProgressBar;

procedure ShowSplashScreen;
begin
  SplashPage := TForm.Create(nil);
  SplashPage.BorderStyle := bsNone;
  SplashPage.Position := poScreenCenter;
  SplashPage.ClientWidth := 500;
  SplashPage.ClientHeight := 250;
  SplashPage.Color := clWhite;
  SplashPage.Caption := '';

  with TLabel.Create(SplashPage) do
  begin
    Parent := SplashPage;
    Caption := '{#MyAppName}';
    Left := 0;
    Top := 40;
    Width := 500;
    Height := 30;
    Alignment := taCenter;
    Font.Size := 20;
    Font.Style := [fsBold];
    Font.Color := clNavy;
    Transparent := True;
  end;

  SplashProgress := TNewProgressBar.Create(SplashPage);
  SplashProgress.Parent := SplashPage;
  SplashProgress.Left := 50;
  SplashProgress.Top := 130;
  SplashProgress.Width := 400;
  SplashProgress.Height := 25;
  SplashProgress.Min := 0;
  SplashProgress.Max := 100;
  SplashProgress.Position := 0;

  SplashLabel := TLabel.Create(SplashPage);
  SplashLabel.Parent := SplashPage;
  SplashLabel.Caption := 'Initializing installation...';
  SplashLabel.Left := 0;
  SplashLabel.Top := 170;
  SplashLabel.Width := 500;
  SplashLabel.Height := 20;
  SplashLabel.Alignment := taCenter;
  SplashLabel.Font.Size := 9;
  SplashLabel.Font.Color := clGray;
  SplashLabel.Transparent := True;

  SplashPage.Show;
  SplashPage.Update;
end;

procedure UpdateSplashProgress(Progress: Integer; StatusText: String);
begin
  SplashProgress.Position := Progress;
  SplashLabel.Caption := StatusText + ' (' + IntToStr(Progress) + '%)';
  SplashPage.Update;
end;

procedure HideSplashScreen;
begin
  SplashPage.Close;
  SplashPage.Free;
end;

procedure InitializeWizard;
var
  WelcomeText: TNewStaticText;
  TextHeight: Integer;
  I: Integer;
begin
  ShowSplashScreen;
  try
    for I := 10 to 100 do
    begin
      UpdateSplashProgress(I, CustomMessage('LoadingComponents'));
      Sleep(12);
    end;

    WizardForm.WelcomeLabel1.Caption := CustomMessage('WelcomeLabel1');
    WizardForm.WelcomeLabel1.Font.Style := [fsBold];
    WizardForm.WelcomeLabel1.Font.Size := 12;
    WizardForm.WelcomeLabel1.Top := ScaleY(30);
    WizardForm.WelcomeLabel1.Left := ScaleX(20);
    WizardForm.WelcomeLabel1.Width := WizardForm.ClientWidth - ScaleX(40);
    WizardForm.WelcomeLabel1.AutoSize := True;

    WizardForm.WelcomeLabel2.Caption := CustomMessage('WelcomeLabel2');
    WizardForm.WelcomeLabel2.Font.Style := [fsBold];
    WizardForm.WelcomeLabel2.Font.Size := 9;
    WizardForm.WelcomeLabel2.Top := WizardForm.WelcomeLabel1.Top + WizardForm.WelcomeLabel1.Height + ScaleY(8);
    WizardForm.WelcomeLabel2.Left := ScaleX(20);
    WizardForm.WelcomeLabel2.Width := WizardForm.ClientWidth - ScaleX(40);
    WizardForm.WelcomeLabel2.AutoSize := True;

    WelcomeText := TNewStaticText.Create(WizardForm);
    try
      WelcomeText.Parent := WizardForm;
      WelcomeText.Left := ScaleX(20);
      WelcomeText.Width := WizardForm.ClientWidth - ScaleX(40);
      WelcomeText.WordWrap := True;
      WelcomeText.Caption := CustomMessage('WelcomeLabel3');
      WelcomeText.Font.Size := 8;
      TextHeight := WelcomeText.Height;
    finally
      WelcomeText.Free;
    end;

    WelcomeText := TNewStaticText.Create(WizardForm);
    WelcomeText.Parent := WizardForm.WelcomePage;
    WelcomeText.Left := ScaleX(20);
    WelcomeText.Top := WizardForm.WelcomeLabel2.Top + WizardForm.WelcomeLabel2.Height + ScaleY(20);
    WelcomeText.Width := WizardForm.ClientWidth - ScaleX(40);
    WelcomeText.Height := TextHeight + ScaleY(20);
    WelcomeText.AutoSize := False;
    WelcomeText.WordWrap := True;
    WelcomeText.Caption := CustomMessage('WelcomeLabel3');
    WelcomeText.Font.Size := 8;
    WizardForm.WelcomePage.Height := WelcomeText.Top + WelcomeText.Height + ScaleY(80);
  finally
    HideSplashScreen;
  end;
end;
