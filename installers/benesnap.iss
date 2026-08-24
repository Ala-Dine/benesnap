; Inno Setup script for benesnap.
; Build the Release exe first:  flutter build windows --release
; Then compile this script:     "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" installers\benesnap.iss
; The installer is written to:  installers\Output\

#define MyAppName "benesnap"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "com.example"
#define MyAppExeName "benesnap.exe"
#define MyReleaseDir "..\build\windows\x64\runner\Release"
#define MyAppIcon "..\windows\runner\resources\app_icon.ico"

[Setup]
AppId={{68B9AB69-4F3D-4181-8918-D0DE7533DB55}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
; This is the icon shown on the setup.exe file itself (installer icon).
SetupIconFile={#MyAppIcon}
UninstallDisplayIcon={app}\{#MyAppExeName}
Compression=lzma
SolidCompression=yes
OutputDir=Output
OutputBaseFilename={#MyAppName}-setup-{#MyAppVersion}
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
; Everything produced by the Release build (exe, dlls, data\ folder with flutter_assets).
Source: "{#MyReleaseDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
; IconFilename is optional here since the exe already has app_icon.ico baked in,
; but pointing at it explicitly keeps the shortcut icon in sync if the exe icon
; is ever changed without a rebuild.
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#MyAppName}}"; Flags: nowait postinstall skipifsilent
