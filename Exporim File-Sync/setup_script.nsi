#This file is part of Exporim File-Sync.
#
#Exporim File-Sync is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
#Exporim File-Sync is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
#You should have received a copy of the GNU General Public License along with Exporim File-Sync.  If not, see <http://www.gnu.org/licenses/>.
#Created by:	Clément Pit--Claudel.
#Web site:		https://github.com/gmedina-exporim/Exporim-File-Sync.

!include MUI2.nsh

; Pass the real version at build time: makensis /DVERSION=1.2.3 setup_script.nsi
; (package.bat/release.bat derive this from git). Falls back to 0.0.0-dev so the
; script still runs stand-alone for a quick local test build.
!ifndef VERSION
	!define VERSION "0.0.0-dev"
!endif

!define 		COMPANY		"Exporim Software"
!define 		PRODUCTNAME	"Exporim File-Sync"

!define 		REGPATH		"Software\${COMPANY}"
!define 		SUBREGPATH	"${REGPATH}\${PRODUCTNAME}"

!define 		COMPANYPATH	"$PROGRAMFILES64\${COMPANY}"
!define 		PROGRAMPATH	"${COMPANYPATH}\${PRODUCTNAME}"
!define			PRODUCTPATH	"${COMPANY}\${PRODUCTNAME}"

; Self-contained publish output (see package.bat / release.bat):
;   dotnet build "Exporim File-Sync.sln" -c Release
;   dotnet publish "Exporim File-Sync\Exporim File-Sync.vbproj" -c Release -r win-x64 --self-contained true -o publish
!define			PUBLISHDIR	"..\publish"

SetCompressor /SOLID lzma

Name "${PRODUCTNAME} ${VERSION}"
OutFile "..\Exporim_File-Sync_Setup.exe"
InstallDir "${PROGRAMPATH}"
InstallDirRegKey HKLM "${SUBREGPATH}" "InstallPath"

RequestExecutionLevel admin
Var StartMenuFolder

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY

!define MUI_STARTMENUPAGE_REGISTRY_ROOT			"HKCU"
!define MUI_STARTMENUPAGE_REGISTRY_KEY			"${SUBREGPATH}"
!define MUI_STARTMENUPAGE_REGISTRY_VALUENAME	"StartMenuFolder"
!define MUI_STARTMENUPAGE_DEFAULTFOLDER			"${PRODUCTPATH}"
!insertmacro MUI_PAGE_STARTMENU AppStartMenu $StartMenuFolder

!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_WELCOME
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_UNPAGE_FINISH

!insertmacro MUI_LANGUAGE "Bulgarian"
!insertmacro MUI_LANGUAGE "Czech"
!insertmacro MUI_LANGUAGE "Dutch"
!insertmacro MUI_LANGUAGE "Danish"
!insertmacro MUI_LANGUAGE "English"
!insertmacro MUI_LANGUAGE "Estonian"
!insertmacro MUI_LANGUAGE "French"
!insertmacro MUI_LANGUAGE "German"
!insertmacro MUI_LANGUAGE "Hebrew"
!insertmacro MUI_LANGUAGE "Indonesian"
!insertmacro MUI_LANGUAGE "Italian"
!insertmacro MUI_LANGUAGE "Korean"
!insertmacro MUI_LANGUAGE "Portuguese"
!insertmacro MUI_LANGUAGE "Polish"
!insertmacro MUI_LANGUAGE "Russian"
!insertmacro MUI_LANGUAGE "SimpChinese"
!insertmacro MUI_LANGUAGE "Spanish"
!insertmacro MUI_LANGUAGE "Swedish"

!macro ExitIfRunning
	Beginning:
		FindProcDLL::FindProc "Exporim File-Sync.exe"
		IntCmp $R0 0 OkCase
			MessageBox MB_ABORTRETRYIGNORE|MB_ICONEXCLAMATION "Exporim File-Sync is running. Please close it before continuing." IDABORT AbortCase IDRETRY RetryCase
				Goto OkCase

	AbortCase:
		Abort

	RetryCase:
		Goto Beginning

	OkCase:
!macroend

Function .onInit
	!insertmacro MUI_LANGDLL_DISPLAY
	!insertmacro ExitIfRunning
FunctionEnd

Function un.onInit
	!insertmacro MUI_UNGETLANGUAGE
	!insertmacro ExitIfRunning
FunctionEnd

Section "Installer Section" InstallSection
	SetOutPath $INSTDIR

	; Self-contained publish output: the app, the .NET 8 runtime, compress.dll +
	; its SharpZipLib dependency, languages\*.lng, COPYING, Release notes.txt -
	; everything dotnet publish produced, recursively, rather than an
	; itemized list that would go stale every time the runtime's file set changes.
	File /r "${PUBLISHDIR}\*.*"

	!insertmacro MUI_STARTMENU_WRITE_BEGIN AppStartMenu
	CreateDirectory "$SMPROGRAMS\$StartMenuFolder"
	CreateShortCut "$SMPROGRAMS\$StartMenuFolder\${PRODUCTNAME}.lnk" "$INSTDIR\${PRODUCTNAME}.exe"
	CreateShortCut "$SMPROGRAMS\$StartMenuFolder\Uninstall.lnk" "$INSTDIR\Uninstall.exe"
	!insertmacro MUI_STARTMENU_WRITE_END

	WriteRegStr HKLM "${SUBREGPATH}" "InstallPath" $INSTDIR
	WriteUninstaller "$INSTDIR\Uninstall.exe"
SectionEnd

Section "Uninstall"
	!insertmacro MUI_STARTMENU_GETFOLDER AppStartMenu $StartMenuFolder

	Delete "$SMPROGRAMS\$StartMenuFolder\${PRODUCTNAME}.lnk"
	Delete "$SMPROGRAMS\$StartMenuFolder\Uninstall.lnk"
	RMDir "$SMPROGRAMS\$StartMenuFolder"
	RMDir "$SMPROGRAMS\${COMPANY}\" #remove the "Exporim Software" folder if empty

	RMDir /r "$INSTDIR\"
	RMDir "${COMPANYPATH}\" #remove the "Exporim Software" folder if empty

	RMDir /r "$APPDATA\Exporim Software\Exporim File-Sync\"
	RMDir "$APPDATA\Exporim Software\" #remove the "Exporim Software" folder if empty

	DeleteRegKey HKLM "${SUBREGPATH}"
	DeleteRegKey /ifempty HKLM "${REGPATH}" #remove the "Exporim Software" key if empty
SectionEnd
