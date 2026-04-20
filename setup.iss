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
 ;#define StagingDir  "C:\FPC\fpc-source\fpc-dist"
#endif

#define AppName      "Free Pascal Compiler (Eleazar)"
#define AppPublisher "Warren Postma / Eleazar Project (not affiliated with FreePascal.org)"
#define AppURL       "https://www.freepascal.org/"
#define BinDir       StagingDir + "\bin\" + TargetSuffix
#define U            StagingDir + "\units\" + TargetSuffix
#define MsgDir       StagingDir + "\msg"
#define DocDir       StagingDir + "\doc"
#define FpmkinstDir  StagingDir + "\fpmkinst"

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
[Types]
Name: "full";    Description: "Full installation"
Name: "compact"; Description: "Compiler, RTL and core FCL"
Name: "minimal"; Description: "Compiler and RTL only"
Name: "custom";  Description: "Custom"; Flags: iscustom

; ---------------------------------------------------------------------------
[Components]

; Core -- always installed
Name: "compiler";            Description: "Compiler and RTL (required)";               Types: full compact minimal custom; Flags: fixed

; RTL extensions
Name: "rtl";                 Description: "RTL extensions";                            Types: full compact
Name: "rtl\objpas";          Description: "Object Pascal / Delphi-compat units";       Types: full compact
Name: "rtl\generics";        Description: "Generic containers";                        Types: full compact
Name: "rtl\console";         Description: "Console I/O";                               Types: full compact
Name: "rtl\extra";           Description: "Extra RTL units";                           Types: full compact
Name: "rtl\unicode";         Description: "Unicode support";                           Types: full compact

; Free Component Library
Name: "fcl";                 Description: "Free Component Library (FCL)";              Types: full compact
Name: "fcl\base";            Description: "FCL base (streams, files, strings)";        Types: full compact
Name: "fcl\process";         Description: "Process management";                        Types: full compact
Name: "fcl\registry";        Description: "Windows registry";                          Types: full compact
Name: "fcl\res";             Description: "Resource files";                            Types: full compact
Name: "fcl\sound";           Description: "Audio (Windows MCI)";                       Types: full
Name: "fcl\stl";             Description: "STL-style generic collections";             Types: full compact
Name: "fcl\net";             Description: "Sockets, FTP, HTTP client";                 Types: full compact
Name: "fcl\web";             Description: "Web and network";                           Types: full compact
Name: "fcl\json";            Description: "JSON parser and writer";                    Types: full compact
Name: "fcl\xml";             Description: "XML / DOM / SAX";                           Types: full compact
Name: "fcl\webserver";       Description: "HTTP server / FastCGI / mod_pascal";        Types: full
Name: "fcl\data";            Description: "Database abstraction (fcl-db)";             Types: full compact
Name: "fcl\image";           Description: "Image loading and format conversion";       Types: full compact
Name: "fcl\report";          Description: "Report generation";                         Types: full
Name: "fcl\pdf";             Description: "PDF output";                                Types: full
Name: "fcl\passrc";          Description: "Pascal source parser";                      Types: full
Name: "fcl\js";              Description: "JavaScript AST / pas2js support";           Types: full
Name: "fcl\fpcunit";         Description: "FPCUnit test framework";                    Types: full compact
Name: "fcl\sdo";             Description: "Service Data Objects";                      Types: full

; New in FPC 3.3.1 trunk
Name: "new";                 Description: "New packages in 3.3.1 trunk";               Types: full
Name: "new\fcl_hash";        Description: "Crypto hashes: SHA-2, RSA, ECDSA, PEM, ASN.1"; Types: full
Name: "new\fcl_yaml";        Description: "YAML parser";                               Types: full
Name: "new\fcl_md";          Description: "Markdown parser and HTML/LaTeX renderers";  Types: full
Name: "new\fcl_mustache";    Description: "Mustache template engine";                  Types: full
Name: "new\fcl_jsonschema";  Description: "JSON Schema validator";                     Types: full
Name: "new\fcl_openapi";     Description: "OpenAPI / REST client support";             Types: full
Name: "new\fcl_css";         Description: "CSS parser";                                Types: full
Name: "new\fcl_ebnf";        Description: "EBNF grammar parser";                      Types: full
Name: "new\fcl_syntax";      Description: "Syntax highlighting base";                 Types: full
Name: "new\fcl_async";       Description: "Async I/O framework";                      Types: full
Name: "new\testinsight";     Description: "TestInsight test runner integration";       Types: full
Name: "new\redis";           Description: "Redis client";                              Types: full
Name: "new\uuid";            Description: "UUID generation";                           Types: full

; Compression and archives
Name: "compression";         Description: "Compression and archives";                  Types: full compact
Name: "compression\zlib";    Description: "zlib / deflate";                            Types: full compact
Name: "compression\bzip2";   Description: "bzip2";                                     Types: full
Name: "compression\paszlib"; Description: "Pascal zlib bindings";                      Types: full
Name: "compression\unzip";   Description: "Unzip";                                     Types: full

; Database backends
Name: "db";                  Description: "Database backends";                         Types: full
Name: "db\sqlite";           Description: "SQLite";                                    Types: full compact
Name: "db\mysql";            Description: "MySQL / MariaDB";                           Types: full
Name: "db\postgres";         Description: "PostgreSQL";                                Types: full
Name: "db\oracle";           Description: "Oracle";                                    Types: full
Name: "db\ibase";            Description: "Firebird / InterBase";                      Types: full
Name: "db\odbc";             Description: "ODBC (generic)";                            Types: full
Name: "db\dblib";            Description: "MS SQL Server (dblib)";                     Types: full

; Graphics and media
Name: "media";               Description: "Graphics, audio and media";                 Types: full
Name: "media\opengl";        Description: "OpenGL and OpenGL ES";                      Types: full
Name: "media\opencl";        Description: "OpenCL GPU compute";                        Types: full
Name: "media\openal";        Description: "OpenAL audio";                              Types: full
Name: "media\sdl";           Description: "SDL (Simple DirectMedia Layer)";            Types: full
Name: "media\pasjpeg";       Description: "JPEG codec (pure Pascal)";                  Types: full
Name: "media\graph";         Description: "BGI-compatible graph unit";                 Types: full
Name: "media\nvapi";         Description: "NVIDIA GPU API (Windows)";                  Types: full

; Windows platform
Name: "win";                 Description: "Windows platform units";                    Types: full compact
Name: "win\base";            Description: "Windows base API (winunits-base)";          Types: full compact
Name: "win\jedi";            Description: "JEDI Windows headers (winunits-jedi)";      Types: full
Name: "win\vcl";             Description: "VCL compatibility layer";                   Types: full
Name: "win\wince";           Description: "Windows CE / Mobile units";                 Types: full

; Networking libraries
Name: "net";                 Description: "Network / internet libraries";               Types: full
Name: "net\openssl";         Description: "OpenSSL bindings";                          Types: full compact
Name: "net\gnutls";          Description: "GnuTLS bindings";                           Types: full
Name: "net\libcurl";         Description: "libcurl HTTP/FTP bindings";                 Types: full
Name: "net\libmicrohttpd";   Description: "libmicrohttpd embedded HTTP server";        Types: full
Name: "net\libenet";         Description: "ENet reliable UDP networking";              Types: full

; Scripting
Name: "scripting";           Description: "Scripting / embedded languages";            Types: full
Name: "scripting\lua";       Description: "Lua bindings";                              Types: full
Name: "scripting\tcl";       Description: "Tcl/Tk bindings";                           Types: full

; Utilities and misc
Name: "util";                Description: "Utilities and misc libraries";               Types: full
Name: "util\hash";           Description: "General hash tables (hash)";                Types: full compact
Name: "util\regexpr";        Description: "Regular expressions";                       Types: full compact
Name: "util\chm";            Description: "CHM help file support";                     Types: full
Name: "util\numlib";         Description: "Numerical / math library";                  Types: full
Name: "util\symbolic";       Description: "Symbolic math";                             Types: full
Name: "util\fpindexer";      Description: "Full-text indexer";                         Types: full
Name: "util\libffi";         Description: "libffi (foreign function interface)";       Types: full
Name: "util\libtar";         Description: "Tar archive support";                       Types: full
Name: "util\libusb";         Description: "USB device access (libusb)";                Types: full
Name: "util\gdbint";         Description: "GDB debugger integration";                  Types: full
Name: "util\odata";          Description: "OData protocol client";                     Types: full
Name: "util\googleapi";      Description: "Google API client";                         Types: full
Name: "util\fv";             Description: "Free Vision TUI framework";                 Types: full
Name: "util\fpmkunit";       Description: "FPMake build system units";                 Types: full
Name: "util\fppkg";          Description: "FPC package manager (fppkg)";               Types: full
Name: "util\webidl";         Description: "Web IDL browser API bindings";              Types: full
Name: "util\pastojs";        Description: "Pas2JS Pascal-to-JavaScript";               Types: full

; WebAssembly
Name: "wasm";                Description: "WebAssembly tools and runtimes";            Types: full
Name: "wasm\utils";          Description: "WASM utilities (wasm-utils, wasm-job, wasm-oi)"; Types: full
Name: "wasm\runtimes";       Description: "wasmedge / wasmtime runtime bindings";      Types: full

; Messages and documentation
Name: "msg";                 Description: "Compiler messages (all languages)";         Types: full compact
Name: "doc";                 Description: "Documentation (PDF)";                       Types: full

; ---------------------------------------------------------------------------
[Files]

; ===== COMPILER BINARIES ====================================================
Source: "{#BinDir}\*"; \
  DestDir: "{app}\bin\{#TargetSuffix}"; \
  Components: compiler; \
  Flags: recursesubdirs createallsubdirs ignoreversion

; ===== RTL ==================================================================
#if DirExists("{#U}\rtl")
Source: "{#U}\rtl\*";          DestDir: "{app}\units\{#TargetSuffix}\rtl";          Components: compiler;      Flags: recursesubdirs createallsubdirs ignoreversion
#endif
#if DirExists("{#U}\rtl-objpas")
Source: "{#U}\rtl-objpas\*";   DestDir: "{app}\units\{#TargetSuffix}\rtl-objpas";   Components: rtl\objpas;    Flags: recursesubdirs createallsubdirs ignoreversion
#endif
#if DirExists("{#U}\rtl-generics")
Source: "{#U}\rtl-generics\*"; DestDir: "{app}\units\{#TargetSuffix}\rtl-generics"; Components: rtl\generics;  Flags: recursesubdirs createallsubdirs ignoreversion
#endif
#if DirExists("{#U}\rtl-console")
Source: "{#U}\rtl-console\*";  DestDir: "{app}\units\{#TargetSuffix}\rtl-console";  Components: rtl\console;   Flags: recursesubdirs createallsubdirs ignoreversion
#endif
#if DirExists("{#U}\rtl-extra")
Source: "{#U}\rtl-extra\*";    DestDir: "{app}\units\{#TargetSuffix}\rtl-extra";    Components: rtl\extra;     Flags: recursesubdirs createallsubdirs ignoreversion
#endif
#if DirExists("{#U}\rtl-unicode")
Source: "{#U}\rtl-unicode\*";  DestDir: "{app}\units\{#TargetSuffix}\rtl-unicode";  Components: rtl\unicode;   Flags: recursesubdirs createallsubdirs ignoreversion
#endif

; ===== FCL -- BASE ==========================================================
#if DirExists("{#U}\fcl-base")
Source: "{#U}\fcl-base\*";     DestDir: "{app}\units\{#TargetSuffix}\fcl-base";     Components: fcl\base;      Flags: recursesubdirs createallsubdirs ignoreversion
#endif
#if DirExists("{#U}\fcl-extra")
Source: "{#U}\fcl-extra\*";    DestDir: "{app}\units\{#TargetSuffix}\fcl-extra";    Components: fcl\base;      Flags: recursesubdirs createallsubdirs ignoreversion
#endif
#if DirExists("{#U}\fcl-process")
Source: "{#U}\fcl-process\*";  DestDir: "{app}\units\{#TargetSuffix}\fcl-process";  Components: fcl\process;   Flags: recursesubdirs createallsubdirs ignoreversion
#endif
#if DirExists("{#U}\fcl-registry")
Source: "{#U}\fcl-registry\*"; DestDir: "{app}\units\{#TargetSuffix}\fcl-registry"; Components: fcl\registry;  Flags: recursesubdirs createallsubdirs ignoreversion
#endif
#if DirExists("{#U}\fcl-res")
Source: "{#U}\fcl-res\*";      DestDir: "{app}\units\{#TargetSuffix}\fcl-res";      Components: fcl\res;       Flags: recursesubdirs createallsubdirs ignoreversion
#endif
#if DirExists("{#U}\fcl-sound")
Source: "{#U}\fcl-sound\*";    DestDir: "{app}\units\{#TargetSuffix}\fcl-sound";    Components: fcl\sound;     Flags: recursesubdirs createallsubdirs ignoreversion
#endif
#if DirExists("{#U}\fcl-stl")
Source: "{#U}\fcl-stl\*";      DestDir: "{app}\units\{#TargetSuffix}\fcl-stl";      Components: fcl\stl;       Flags: recursesubdirs createallsubdirs ignoreversion
#endif

; ===== FCL -- WEB / NETWORK =================================================
#if DirExists("{#U}\fcl-net")
Source: "{#U}\fcl-net\*";      DestDir: "{app}\units\{#TargetSuffix}\fcl-net";      Components: fcl\net;       Flags: recursesubdirs createallsubdirs ignoreversion
#endif
#if DirExists("{#U}\fcl-web")
Source: "{#U}\fcl-web\*";      DestDir: "{app}\units\{#TargetSuffix}\fcl-web";      Components: fcl\web;       Flags: recursesubdirs createallsubdirs ignoreversion
#endif
#if DirExists("{#U}\fcl-json")
Source: "{#U}\fcl-json\*";     DestDir: "{app}\units\{#TargetSuffix}\fcl-json";     Components: fcl\json;      Flags: recursesubdirs createallsubdirs ignoreversion
#endif
#if DirExists("{#U}\fcl-xml")
Source: "{#U}\fcl-xml\*";      DestDir: "{app}\units\{#TargetSuffix}\fcl-xml";      Components: fcl\xml;       Flags: recursesubdirs createallsubdirs ignoreversion
#endif
#if DirExists("{#U}\fastcgi")
Source: "{#U}\fastcgi\*";      DestDir: "{app}\units\{#TargetSuffix}\fastcgi";      Components: fcl\webserver; Flags: recursesubdirs createallsubdirs ignoreversion
#endif
#if DirExists("{#U}\httpd22")
Source: "{#U}\httpd22\*";      DestDir: "{app}\units\{#TargetSuffix}\httpd22";      Components: fcl\webserver; Flags: recursesubdirs createallsubdirs ignoreversion
#endif
#if DirExists("{#U}\httpd24")
Source: "{#U}\httpd24\*";      DestDir: "{app}\units\{#TargetSuffix}\httpd24";      Components: fcl\webserver; Flags: recursesubdirs createallsubdirs ignoreversion
#endif

; ===== FCL -- DATA / IMAGES / REPORTS =======================================
#if DirExists("{#U}\fcl-db")
Source: "{#U}\fcl-db\*";      DestDir: "{app}\units\{#TargetSuffix}\fcl-db";        Components: fcl\data;      Flags: recursesubdirs createallsubdirs ignoreversion
#endif
#if DirExists("{#U}\fcl-image")
Source: "{#U}\fcl-image\*";   DestDir: "{app}\units\{#TargetSuffix}\fcl-image";     Components: fcl\image;     Flags: recursesubdirs createallsubdirs ignoreversion
#endif
#if DirExists("{#U}\fcl-report")
Source: "{#U}\fcl-report\*";  DestDir: "{app}\units\{#TargetSuffix}\fcl-report";    Components: fcl\report;    Flags: recursesubdirs createallsubdirs ignoreversion
#endif
#if DirExists("{#U}\fcl-pdf")
Source: "{#U}\fcl-pdf\*";     DestDir: "{app}\units\{#TargetSuffix}\fcl-pdf";       Components: fcl\pdf;       Flags: recursesubdirs createallsubdirs ignoreversion
#endif

; ===== FCL -- COMPILER / TOOLING ============================================
#if DirExists("{#U}\fcl-passrc")
Source: "{#U}\fcl-passrc\*";  DestDir: "{app}\units\{#TargetSuffix}\fcl-passrc";    Components: fcl\passrc;    Flags: recursesubdirs createallsubdirs ignoreversion
#endif
#if DirExists("{#U}\fcl-js")
Source: "{#U}\fcl-js\*";      DestDir: "{app}\units\{#TargetSuffix}\fcl-js";        Components: fcl\js;        Flags: recursesubdirs createallsubdirs ignoreversion
#endif
#if DirExists("{#U}\fcl-fpcunit")
Source: "{#U}\fcl-fpcunit\*"; DestDir: "{app}\units\{#TargetSuffix}\fcl-fpcunit";   Components: fcl\fpcunit;   Flags: recursesubdirs createallsubdirs ignoreversion
#endif
#if DirExists("{#U}\fcl-sdo")
Source: "{#U}\fcl-sdo\*";     DestDir: "{app}\units\{#TargetSuffix}\fcl-sdo";       Components: fcl\sdo;       Flags: recursesubdirs createallsubdirs ignoreversion
#endif

; ===== NEW IN 3.3.1 TRUNK ===================================================
#if DirExists("{#U}\fcl-hash")
Source: "{#U}\fcl-hash\*";       DestDir: "{app}\units\{#TargetSuffix}\fcl-hash";       Components: new\fcl_hash;       Flags: recursesubdirs createallsubdirs ignoreversion
#endif
#if DirExists("{#U}\fcl-yaml")
Source: "{#U}\fcl-yaml\*";       DestDir: "{app}\units\{#TargetSuffix}\fcl-yaml";       Components: new\fcl_yaml;       Flags: recursesubdirs createallsubdirs ignoreversion
#endif
#if DirExists("{#U}\fcl-md")
Source: "{#U}\fcl-md\*";         DestDir: "{app}\units\{#TargetSuffix}\fcl-md";         Components: new\fcl_md;         Flags: recursesubdirs createallsubdirs ignoreversion
#endif
#if DirExists("{#U}\fcl-mustache")
Source: "{#U}\fcl-mustache\*";   DestDir: "{app}\units\{#TargetSuffix}\fcl-mustache";   Components: new\fcl_mustache;   Flags: recursesubdirs createallsubdirs ignoreversion
#endif
#if DirExists("{#U}\fcl-jsonschema")
Source: "{#U}\fcl-jsonschema\*"; DestDir: "{app}\units\{#TargetSuffix}\fcl-jsonschema"; Components: new\fcl_jsonschema; Flags: recursesubdirs createallsubdirs ignoreversion
#endif
#if DirExists("{#U}\fcl-openapi")
Source: "{#U}\fcl-openapi\*";    DestDir: "{app}\units\{#TargetSuffix}\fcl-openapi";    Components: new\fcl_openapi;    Flags: recursesubdirs createallsubdirs ignoreversion
#endif
#if DirExists("{#U}\fcl-css")
Source: "{#U}\fcl-css\*";        DestDir: "{app}\units\{#TargetSuffix}\fcl-css";        Components: new\fcl_css;        Flags: recursesubdirs createallsubdirs ignoreversion
#endif
#if DirExists("{#U}\fcl-ebnf")
Source: "{#U}\fcl-ebnf\*";       DestDir: "{app}\units\{#TargetSuffix}\fcl-ebnf";       Components: new\fcl_ebnf;       Flags: recursesubdirs createallsubdirs ignoreversion
#endif
#if DirExists("{#U}\fcl-syntax")
Source: "{#U}\fcl-syntax\*";     DestDir: "{app}\units\{#TargetSuffix}\fcl-syntax";     Components: new\fcl_syntax;     Flags: recursesubdirs createallsubdirs ignoreversion
#endif
#if DirExists("{#U}\fcl-async")
Source: "{#U}\fcl-async\*";      DestDir: "{app}\units\{#TargetSuffix}\fcl-async";      Components: new\fcl_async;      Flags: recursesubdirs createallsubdirs ignoreversion
#endif
#if DirExists("{#U}\testinsight")
Source: "{#U}\testinsight\*";    DestDir: "{app}\units\{#TargetSuffix}\testinsight";    Components: new\testinsight;    Flags: recursesubdirs createallsubdirs ignoreversion
#endif
#if DirExists("{#U}\redis")
Source: "{#U}\redis\*";          DestDir: "{app}\units\{#TargetSuffix}\redis";          Components: new\redis;          Flags: recursesubdirs createallsubdirs ignoreversion
#endif
#if DirExists("{#U}\uuid")
Source: "{#U}\uuid\*";           DestDir: "{app}\units\{#TargetSuffix}\uuid";           Components: new\uuid;           Flags: recursesubdirs createallsubdirs ignoreversion
#endif

; ===== COMPRESSION ==========================================================
#if DirExists("{#U}\zlib")
Source: "{#U}\zlib\*";    DestDir: "{app}\units\{#TargetSuffix}\zlib";    Components: compression\zlib;    Flags: recursesubdirs createallsubdirs ignoreversion
#endif
#if DirExists("{#U}\bzip2")
Source: "{#U}\bzip2\*";   DestDir: "{app}\units\{#TargetSuffix}\bzip2";   Components: compression\bzip2;   Flags: recursesubdirs createallsubdirs ignoreversion
#endif
#if DirExists("{#U}\paszlib")
Source: "{#U}\paszlib\*"; DestDir: "{app}\units\{#TargetSuffix}\paszlib"; Components: compression\paszlib; Flags: recursesubdirs createallsubdirs ignoreversion
#endif
#if DirExists("{#U}\unzip")
Source: "{#U}\unzip\*";   DestDir: "{app}\units\{#TargetSuffix}\unzip";   Components: compression\unzip;   Flags: recursesubdirs createallsubdirs ignoreversion
#endif

; ===== DATABASE BACKENDS ====================================================
#if DirExists("{#U}\sqlite")
Source: "{#U}\sqlite\*";   DestDir: "{app}\units\{#TargetSuffix}\sqlite";   Components: db\sqlite;   Flags: recursesubdirs createallsubdirs ignoreversion
#endif
#if DirExists("{#U}\mysql")
Source: "{#U}\mysql\*";    DestDir: "{app}\units\{#TargetSuffix}\mysql";    Components: db\mysql;    Flags: recursesubdirs createallsubdirs ignoreversion
#endif
#if DirExists("{#U}\postgres")
Source: "{#U}\postgres\*"; DestDir: "{app}\units\{#TargetSuffix}\postgres"; Components: db\postgres; Flags: recursesubdirs createallsubdirs ignoreversion
#endif
#if DirExists("{#U}\oracle")
Source: "{#U}\oracle\*";   DestDir: "{app}\units\{#TargetSuffix}\oracle";   Components: db\oracle;   Flags: recursesubdirs createallsubdirs ignoreversion
#endif
#if DirExists("{#U}\ibase")
Source: "{#U}\ibase\*";    DestDir: "{app}\units\{#TargetSuffix}\ibase";    Components: db\ibase;    Flags: recursesubdirs createallsubdirs ignoreversion
#endif
#if DirExists("{#U}\odbc")
Source: "{#U}\odbc\*";     DestDir: "{app}\units\{#TargetSuffix}\odbc";     Components: db\odbc;     Flags: recursesubdirs createallsubdirs ignoreversion
#endif
#if DirExists("{#U}\dblib")
Source: "{#U}\dblib\*";    DestDir: "{app}\units\{#TargetSuffix}\dblib";    Components: db\dblib;    Flags: recursesubdirs createallsubdirs ignoreversion
#endif

; ===== GRAPHICS AND MEDIA ===================================================
#if DirExists("{#U}\opengl")
Source: "{#U}\opengl\*";   DestDir: "{app}\units\{#TargetSuffix}\opengl";   Components: media\opengl;  Flags: recursesubdirs createallsubdirs ignoreversion
#endif
#if DirExists("{#U}\opengles")
Source: "{#U}\opengles\*"; DestDir: "{app}\units\{#TargetSuffix}\opengles"; Components: media\opengl;  Flags: recursesubdirs createallsubdirs ignoreversion
#endif
#if DirExists("{#U}\opencl")
Source: "{#U}\opencl\*";   DestDir: "{app}\units\{#TargetSuffix}\opencl";   Components: media\opencl;  Flags: recursesubdirs createallsubdirs ignoreversion
#endif
#if DirExists("{#U}\openal")
Source: "{#U}\openal\*";   DestDir: "{app}\units\{#TargetSuffix}\openal";   Components: media\openal;  Flags: recursesubdirs createallsubdirs ignoreversion
#endif
#if DirExists("{#U}\sdl")
Source: "{#U}\sdl\*";      DestDir: "{app}\units\{#TargetSuffix}\sdl";      Components: media\sdl;     Flags: recursesubdirs createallsubdirs ignoreversion
#endif
#if DirExists("{#U}\pasjpeg")
Source: "{#U}\pasjpeg\*";  DestDir: "{app}\units\{#TargetSuffix}\pasjpeg";  Components: media\pasjpeg; Flags: recursesubdirs createallsubdirs ignoreversion
#endif
#if DirExists("{#U}\graph")
Source: "{#U}\graph\*";    DestDir: "{app}\units\{#TargetSuffix}\graph";    Components: media\graph;   Flags: recursesubdirs createallsubdirs ignoreversion
#endif
#if DirExists("{#U}\nvapi")
Source: "{#U}\nvapi\*";    DestDir: "{app}\units\{#TargetSuffix}\nvapi";    Components: media\nvapi;   Flags: recursesubdirs createallsubdirs ignoreversion
#endif

; ===== WINDOWS PLATFORM =====================================================
#if DirExists("{#U}\winunits-base")
Source: "{#U}\winunits-base\*"; DestDir: "{app}\units\{#TargetSuffix}\winunits-base"; Components: win\base;  Flags: recursesubdirs createallsubdirs ignoreversion
#endif
#if DirExists("{#U}\winunits-jedi")
Source: "{#U}\winunits-jedi\*"; DestDir: "{app}\units\{#TargetSuffix}\winunits-jedi"; Components: win\jedi;  Flags: recursesubdirs createallsubdirs ignoreversion
#endif
#if DirExists("{#U}\vcl-compat")
Source: "{#U}\vcl-compat\*";    DestDir: "{app}\units\{#TargetSuffix}\vcl-compat";    Components: win\vcl;   Flags: recursesubdirs createallsubdirs ignoreversion
#endif
#if DirExists("{#U}\winceunits")
Source: "{#U}\winceunits\*";    DestDir: "{app}\units\{#TargetSuffix}\winceunits";    Components: win\wince; Flags: recursesubdirs createallsubdirs ignoreversion
#endif

; ===== NETWORKING LIBRARIES =================================================
#if DirExists("{#U}\openssl")
Source: "{#U}\openssl\*";       DestDir: "{app}\units\{#TargetSuffix}\openssl";       Components: net\openssl;       Flags: recursesubdirs createallsubdirs ignoreversion
#endif
#if DirExists("{#U}\gnutls")
Source: "{#U}\gnutls\*";        DestDir: "{app}\units\{#TargetSuffix}\gnutls";        Components: net\gnutls;        Flags: recursesubdirs createallsubdirs ignoreversion
#endif
#if DirExists("{#U}\libcurl")
Source: "{#U}\libcurl\*";       DestDir: "{app}\units\{#TargetSuffix}\libcurl";       Components: net\libcurl;       Flags: recursesubdirs createallsubdirs ignoreversion
#endif
#if DirExists("{#U}\libmicrohttpd")
Source: "{#U}\libmicrohttpd\*"; DestDir: "{app}\units\{#TargetSuffix}\libmicrohttpd"; Components: net\libmicrohttpd; Flags: recursesubdirs createallsubdirs ignoreversion
#endif
#if DirExists("{#U}\libenet")
Source: "{#U}\libenet\*";       DestDir: "{app}\units\{#TargetSuffix}\libenet";       Components: net\libenet;       Flags: recursesubdirs createallsubdirs ignoreversion
#endif

; ===== SCRIPTING ============================================================
#if DirExists("{#U}\lua")
Source: "{#U}\lua\*"; DestDir: "{app}\units\{#TargetSuffix}\lua"; Components: scripting\lua; Flags: recursesubdirs createallsubdirs ignoreversion
#endif
#if DirExists("{#U}\tcl")
Source: "{#U}\tcl\*"; DestDir: "{app}\units\{#TargetSuffix}\tcl"; Components: scripting\tcl; Flags: recursesubdirs createallsubdirs ignoreversion
#endif

; ===== UTILITIES ============================================================
#if DirExists("{#U}\hash")
Source: "{#U}\hash\*";      DestDir: "{app}\units\{#TargetSuffix}\hash";      Components: util\hash;      Flags: recursesubdirs createallsubdirs ignoreversion
#endif
#if DirExists("{#U}\regexpr")
Source: "{#U}\regexpr\*";   DestDir: "{app}\units\{#TargetSuffix}\regexpr";   Components: util\regexpr;   Flags: recursesubdirs createallsubdirs ignoreversion
#endif
#if DirExists("{#U}\chm")
Source: "{#U}\chm\*";       DestDir: "{app}\units\{#TargetSuffix}\chm";       Components: util\chm;       Flags: recursesubdirs createallsubdirs ignoreversion
#endif
#if DirExists("{#U}\numlib")
Source: "{#U}\numlib\*";    DestDir: "{app}\units\{#TargetSuffix}\numlib";    Components: util\numlib;    Flags: recursesubdirs createallsubdirs ignoreversion
#endif
#if DirExists("{#U}\symbolic")
Source: "{#U}\symbolic\*";  DestDir: "{app}\units\{#TargetSuffix}\symbolic";  Components: util\symbolic;  Flags: recursesubdirs createallsubdirs ignoreversion
#endif
#if DirExists("{#U}\fpindexer")
Source: "{#U}\fpindexer\*"; DestDir: "{app}\units\{#TargetSuffix}\fpindexer"; Components: util\fpindexer; Flags: recursesubdirs createallsubdirs ignoreversion
#endif
#if DirExists("{#U}\libffi")
Source: "{#U}\libffi\*";    DestDir: "{app}\units\{#TargetSuffix}\libffi";    Components: util\libffi;    Flags: recursesubdirs createallsubdirs ignoreversion
#endif
#if DirExists("{#U}\libtar")
Source: "{#U}\libtar\*";    DestDir: "{app}\units\{#TargetSuffix}\libtar";    Components: util\libtar;    Flags: recursesubdirs createallsubdirs ignoreversion
#endif
#if DirExists("{#U}\libusb")
Source: "{#U}\libusb\*";    DestDir: "{app}\units\{#TargetSuffix}\libusb";    Components: util\libusb;    Flags: recursesubdirs createallsubdirs ignoreversion
#endif
#if DirExists("{#U}\gdbint")
Source: "{#U}\gdbint\*";    DestDir: "{app}\units\{#TargetSuffix}\gdbint";    Components: util\gdbint;    Flags: recursesubdirs createallsubdirs ignoreversion
#endif
#if DirExists("{#U}\odata")
Source: "{#U}\odata\*";     DestDir: "{app}\units\{#TargetSuffix}\odata";     Components: util\odata;     Flags: recursesubdirs createallsubdirs ignoreversion
#endif
#if DirExists("{#U}\googleapi")
Source: "{#U}\googleapi\*"; DestDir: "{app}\units\{#TargetSuffix}\googleapi"; Components: util\googleapi; Flags: recursesubdirs createallsubdirs ignoreversion
#endif
#if DirExists("{#U}\fv")
Source: "{#U}\fv\*";        DestDir: "{app}\units\{#TargetSuffix}\fv";        Components: util\fv;        Flags: recursesubdirs createallsubdirs ignoreversion
#endif
#if DirExists("{#U}\fpmkunit")
Source: "{#U}\fpmkunit\*";  DestDir: "{app}\units\{#TargetSuffix}\fpmkunit";  Components: util\fpmkunit;  Flags: recursesubdirs createallsubdirs ignoreversion
#endif
#if DirExists("{#U}\fppkg")
Source: "{#U}\fppkg\*";     DestDir: "{app}\units\{#TargetSuffix}\fppkg";     Components: util\fppkg;     Flags: recursesubdirs createallsubdirs ignoreversion
#endif
#if DirExists("{#U}\webidl")
Source: "{#U}\webidl\*";    DestDir: "{app}\units\{#TargetSuffix}\webidl";    Components: util\webidl;    Flags: recursesubdirs createallsubdirs ignoreversion
#endif
#if DirExists("{#U}\pastojs")
Source: "{#U}\pastojs\*";   DestDir: "{app}\units\{#TargetSuffix}\pastojs";   Components: util\pastojs;   Flags: recursesubdirs createallsubdirs ignoreversion
#endif

; ===== WEBASSEMBLY ==========================================================
#if DirExists("{#U}\wasm-utils")
Source: "{#U}\wasm-utils\*"; DestDir: "{app}\units\{#TargetSuffix}\wasm-utils"; Components: wasm\utils;    Flags: recursesubdirs createallsubdirs ignoreversion
#endif
#if DirExists("{#U}\wasm-job")
Source: "{#U}\wasm-job\*";   DestDir: "{app}\units\{#TargetSuffix}\wasm-job";   Components: wasm\utils;    Flags: recursesubdirs createallsubdirs ignoreversion
#endif
#if DirExists("{#U}\wasm-oi")
Source: "{#U}\wasm-oi\*";    DestDir: "{app}\units\{#TargetSuffix}\wasm-oi";    Components: wasm\utils;    Flags: recursesubdirs createallsubdirs ignoreversion
#endif
#if DirExists("{#U}\wasmedge")
Source: "{#U}\wasmedge\*";   DestDir: "{app}\units\{#TargetSuffix}\wasmedge";   Components: wasm\runtimes; Flags: recursesubdirs createallsubdirs ignoreversion
#endif
#if DirExists("{#U}\wasmtime")
Source: "{#U}\wasmtime\*";   DestDir: "{app}\units\{#TargetSuffix}\wasmtime";   Components: wasm\runtimes; Flags: recursesubdirs createallsubdirs ignoreversion
#endif

; ===== FPMKINST METADATA ====================================================
Source: "{#FpmkinstDir}\*"; \
  DestDir: "{app}\fpmkinst"; \
  Components: util\fpmkunit; \
  Flags: recursesubdirs createallsubdirs ignoreversion

; ===== MESSAGES AND DOCS ====================================================
Source: "{#MsgDir}\*"; DestDir: "{app}\msg"; Components: msg; Flags: ignoreversion
Source: "{#DocDir}\*"; DestDir: "{app}\doc"; Components: doc; Flags: recursesubdirs createallsubdirs ignoreversion

; ---------------------------------------------------------------------------
[Tasks]
Name: addtopath; Description: "Add compiler bin directory to system PATH"; Flags: checkedonce

; ---------------------------------------------------------------------------
[Registry]
; Add the compiler bin dir to the system PATH (HKLM) -- only if task selected.
Root: HKLM; \
  Subkey: "SYSTEM\CurrentControlSet\Control\Session Manager\Environment"; \
  ValueType: expandsz; \
  ValueName: "Path"; \
  ValueData: "{app}\bin\{#TargetSuffix};{olddata}"; \
  Tasks: addtopath; \
  Check: NeedsAddPath(ExpandConstant('{app}\bin\{#TargetSuffix}')); \
  Flags: preservestringtype uninsdeletevalue

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
Type: files; Name: "{app}\bin\{#TargetSuffix}\fpc.cfg"

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
begin
  if CurStep = ssPostInstall then
    SendBroadcastMessage($001A, 0, 0);
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
var
  OrigPath, NewPath: string;
  BinDir: string;
begin
  if CurUninstallStep <> usPostUninstall then Exit;

  BinDir := ExpandConstant('{app}\bin\{#TargetSuffix}');
  if not RegQueryStringValue(HKLM,
      'SYSTEM\CurrentControlSet\Control\Session Manager\Environment',
      'Path', OrigPath) then Exit;

  // Remove our entry (with either leading or trailing semicolon)
  NewPath := OrigPath;
  StringChange(NewPath, ';' + BinDir, '');
  StringChange(NewPath, BinDir + ';', '');
  StringChange(NewPath, BinDir,       '');

  if NewPath <> OrigPath then
    RegWriteExpandStringValue(HKLM,
        'SYSTEM\CurrentControlSet\Control\Session Manager\Environment',
        'Path', NewPath);

  SendBroadcastMessage($001A, 0, 0);
end;
