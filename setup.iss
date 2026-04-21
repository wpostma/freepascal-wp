; Free Pascal Compiler -- Inno Setup 6 installer script
; This is not the main Free Pascal installer script, this is the installer for Warren's Friendly Fork
; known informaly as the Eleazar project.  Not affiliated with the main FreePascal project.
;
; Compiled by package.ps1, which passes these defines on the ISCC command line:
;   /DStagingDir=C:\FPC\fpc-source\fpc-dist\fpc-3.3.1.x86_64-win64
;   /DAppVersion=3.3.1
;   /DTargetSuffix=x86_64-win64
;
; To compile manually:
;   "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" ^
;       /DStagingDir=<path> /DAppVersion=3.3.1 /DTargetSuffix=x86_64-win64 setup.iss

#ifndef AppVersion
  #define AppVersion "3.3.1"
#endif
#ifndef TargetSuffix
  #define TargetSuffix "x86_64-win64"
#endif
#ifndef StagingDir
  #error StagingDir must be defined: /DStagingDir=C:\path\to\staging
  ;#define StagingDir  "C:\FPC\fpc-source\fpc-dist\"
#endif

#define AppName      "Free Pascal Compiler (Eleazar)"
#define AppPublisher "Warren Postma / Eleazar Project (not affiliated with FreePascal.org)"
#define AppURL       "https://www.freepascal.org/"
#define BinDir       StagingDir + "\bin\" + TargetSuffix
#define Win32BinDir  StagingDir + "\bin\win32"
#define U            StagingDir + "\units\" + TargetSuffix
#define MsgDir       StagingDir + "\msg"
#define DocDir       StagingDir + "\doc"
#define FpmkinstDir  StagingDir + "\fpmkinst"
#define SrcZip       StagingDir + "\src_" + AppVersion + ".zip"

; ---------------------------------------------------------------------------
[Setup]
AppId={{C8A2F5B3-47D1-4E9A-B0F2-FPC{#AppVersion}WIN}
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName} {#AppVersion} ({#TargetSuffix})
AppPublisher={#AppPublisher}
AppPublisherURL={#AppURL}
AppSupportURL={#AppURL}
AppUpdatesURL={#AppURL}
; Default install to C:\FPC\<version> matching the layout of released builds
DefaultDirName=C:\FPC\{#AppVersion}
DefaultGroupName=Free Pascal {#AppVersion}
AllowNoIcons=yes

; Allow non-admin users to install to their own profile
;PrivilegesRequiredOverridesAllowed=dialog

Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern

OutputBaseFilename=fpc-{#AppVersion}.{#TargetSuffix}-setup

; ---------------------------------------------------------------------------
[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"; LicenseFile: "license.txt"

; ---------------------------------------------------------------------------
[Files]
Source: "{#BinDir}\fpc.exe";              DestDir: "{app}\bin\{#TargetSuffix}"; Flags: recursesubdirs createallsubdirs ignoreversion
Source: "{#BinDir}\fpcmake.exe";          DestDir: "{app}\bin\{#TargetSuffix}"; Flags: recursesubdirs createallsubdirs ignoreversion
Source: "{#BinDir}\*";                    DestDir: "{app}\bin\{#TargetSuffix}"; Flags: recursesubdirs createallsubdirs ignoreversion
Source: "{#Win32BinDir}\*";               DestDir: "{app}\bin\win32"; Flags: ignoreversion
Source: "{#U}\*";                         DestDir: "{app}\units\{#TargetSuffix}"; Flags: recursesubdirs createallsubdirs ignoreversion
Source: "{#FpmkinstDir}\*";               DestDir: "{app}\fpmkinst\{#TargetSuffix}"; Flags: recursesubdirs createallsubdirs ignoreversion
Source: "{#MsgDir}\*";                    DestDir: "{app}\msg"; Flags: ignoreversion
Source: "{#DocDir}\*";                    DestDir: "{app}\doc"; Flags: recursesubdirs createallsubdirs ignoreversion
Source: "rtl\*";                          DestDir: "{app}\src\rtl"; Flags: recursesubdirs createallsubdirs ignoreversion
Source: "packages\*";                     DestDir: "{app}\src\packages"; Flags: recursesubdirs createallsubdirs ignoreversion
Source: "{#StagingDir}\examples\*";       DestDir: "{app}\examples"; Flags: recursesubdirs createallsubdirs ignoreversion
;Source: "{#SrcZip}";                      DestDir: "{app}"; Flags: ignoreversion

; ---------------------------------------------------------------------------
[Tasks]
Name: addtopath; Description: "Add compiler bin directory to system PATH"; Flags: checkedonce

; ---------------------------------------------------------------------------
[Registry]
; Add both bin dirs to the system PATH (HKLM) -- only if task selected.
Root: HKLM; \
  Subkey: "SYSTEM\CurrentControlSet\Control\Session Manager\Environment"; \
  ValueType: expandsz; \
  ValueName: "Path"; \
  ValueData: "{app}\bin\{#TargetSuffix};{olddata}"; \
  Tasks: addtopath; \
  Check: NeedsAddPath(ExpandConstant('{app}\bin\{#TargetSuffix}')); \
  Flags: preservestringtype

Root: HKLM; \
  Subkey: "SYSTEM\CurrentControlSet\Control\Session Manager\Environment"; \
  ValueType: expandsz; \
  ValueName: "Path"; \
  ValueData: "{app}\bin\win32;{olddata}"; \
  Tasks: addtopath; \
  Check: NeedsAddPath(ExpandConstant('{app}\bin\win32')); \
  Flags: preservestringtype

; ---------------------------------------------------------------------------
[Icons]
Name: "{group}\Free Pascal {#AppVersion}";          Filename: "{app}\bin\{#TargetSuffix}\fpc.exe"
Name: "{group}\Uninstall Free Pascal {#AppVersion}";Filename: "{uninstallexe}"

; ---------------------------------------------------------------------------
[Run]
; Generate fpc.cfg so the installed compiler can locate its units and messages.
Filename: "{app}\bin\{#TargetSuffix}\fpcmkcfg.exe"; \
  Parameters: "-d ""basepath={app}"" -o ""{app}\bin\{#TargetSuffix}\fpc.cfg"""; \
  StatusMsg: "Configuring FPC..."; \
  Flags: runhidden

; ---------------------------------------------------------------------------
[UninstallDelete]
; fpc.cfg is generated post-install, so the uninstaller won't know about it
Type: files;     Name: "{app}\bin\{#TargetSuffix}\fpc.cfg"
; src\ is extracted post-install from the shipped zip
Type: filesandordirs; Name: "{app}\src"
Type: files;     Name: "{app}\src_{#AppVersion}.zip"

; ---------------------------------------------------------------------------
[Code]

// Returns true if Param is not already present in the system PATH.
function NeedsAddPath(Param: string): Boolean;
var
  OrigPath: string;
begin
  if not RegQueryStringValue(HKLM,
      'SYSTEM\CurrentControlSet\Control\Session Manager\Environment',
      'Path', OrigPath) then
  begin
    Result := True;
    Exit;
  end;
  Result := Pos(';' + Uppercase(Param) + ';',
                ';' + Uppercase(OrigPath) + ';') = 0;
end;

// WM_SETTINGCHANGE = $1A.  lParam=0 means "all environment variables changed".
procedure CurStepChanged(CurStep: TSetupStep);
var
  SrcZip, SrcDir: string;
  ResultCode: Integer;
begin
  if CurStep <> ssPostInstall then Exit;

  SrcZip := ExpandConstant('{app}\src_{#AppVersion}.zip');
  SrcDir := ExpandConstant('{app}\src');
  if FileExists(SrcZip) then
  begin
    ForceDirectories(SrcDir);
    Exec(ExpandConstant('{sys}') + '\WindowsPowerShell\v1.0\powershell.exe',
         '-NoProfile -NonInteractive -Command "Expand-Archive -Force -LiteralPath ''' +
         SrcZip + ''' -DestinationPath ''' + SrcDir + '''"',
         '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  end;

  SendBroadcastMessage($001A, 0, 0);
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
var
  OrigPath, NewPath: string;
  BinDir: string;
begin
  if CurUninstallStep <> usPostUninstall then Exit;

  if not RegQueryStringValue(HKLM,
      'SYSTEM\CurrentControlSet\Control\Session Manager\Environment',
      'Path', OrigPath) then Exit;

  NewPath := OrigPath;

  BinDir := ExpandConstant('{app}\bin\{#TargetSuffix}');
  StringChange(NewPath, ';' + BinDir, '');
  StringChange(NewPath, BinDir + ';', '');
  StringChange(NewPath, BinDir,       '');

  BinDir := ExpandConstant('{app}\bin\win32');
  StringChange(NewPath, ';' + BinDir, '');
  StringChange(NewPath, BinDir + ';', '');
  StringChange(NewPath, BinDir,       '');

  if NewPath <> OrigPath then
    RegWriteExpandStringValue(HKLM,
        'SYSTEM\CurrentControlSet\Control\Session Manager\Environment',
        'Path', NewPath);

  SendBroadcastMessage($001A, 0, 0);
end;
