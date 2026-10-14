#ifndef ReleaseDir
  #define ReleaseDir "..\app\build\windows\x64\runner\Release"
#endif
#ifndef OutputDir
  #define OutputDir "..\outputs"
#endif
[Setup]
AppId={{A3D73737-AD19-42F9-A207-C65D5A7ABF23}
AppName=奶娃片刻
AppVersion=0.1.2
AppPublisher=Naiwa Moment
DefaultDirName={localappdata}\Programs\NaiwaMoment
DefaultGroupName=奶娃片刻
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
OutputDir={#OutputDir}
OutputBaseFilename=NaiwaMoment-0.1.2-Windows-Setup
SetupIconFile=..\app\windows\runner\resources\app_icon.ico
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
UninstallDisplayIcon={app}\naiwa_moment.exe
MinVersion=10.0

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "在桌面创建快捷方式"; Flags: unchecked

[Files]
Source: "{#ReleaseDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\奶娃片刻"; Filename: "{app}\naiwa_moment.exe"
Name: "{autodesktop}\奶娃片刻"; Filename: "{app}\naiwa_moment.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\naiwa_moment.exe"; Description: "打开奶娃片刻"; Flags: nowait postinstall skipifsilent
