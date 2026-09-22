@echo OFF
@if "%1" == "/?" goto help
@if "%1" == "" goto help

:start
@echo This file is part of Exporim File-Sync.
@echo Exporim File-Sync is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
@echo Exporim File-Sync is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
@echo You should have received a copy of the GNU General Public License along with Exporim File-Sync.  If not, see http://www.gnu.org/licenses/.
@echo Created by:   Cl?ment Pit--Claudel.
@echo Web site:     https://github.com/gmedina-exporim/Exporim-File-Sync.

set VER=%1
if exist build rmdir /s /q build
mkdir build
set LOG=build\buildlog-v%VER%.txt

(echo Release log for v%VER% & date /t & time /t & echo.) > %LOG%

echo (*) Building (Release)
dotnet build "Exporim File-Sync.sln" -c Release >> %LOG% 2>&1
if errorlevel 1 goto builderror

echo (*) Publishing self-contained win-x64
if exist publish rmdir /s /q publish
dotnet publish "Exporim File-Sync\Exporim File-Sync.vbproj" -c Release -r win-x64 --self-contained true -p:PublishSingleFile=false -o publish >> %LOG% 2>&1
if errorlevel 1 goto builderror

echo (*) Building installer (v%VER%)
where makensis >nul 2>&1
if errorlevel 1 (
	echo (!) makensis.exe not found on PATH -- install NSIS first.
	goto builderror
)
makensis /DVERSION=%VER% "Exporim File-Sync\setup_script.nsi" >> %LOG% 2>&1
if errorlevel 1 goto builderror
move Exporim_File-Sync_Setup.exe "build\Exporim-File-Sync-v%VER%-Setup.exe" >nul

echo (*) Zipping the self-contained publish output
where 7z >nul 2>&1
if errorlevel 1 (
	powershell -NoProfile -Command "Compress-Archive -Path 'publish\*' -DestinationPath 'build\Exporim-File-Sync-v%VER%-win-x64.zip' -Force" >> %LOG% 2>&1
) else (
	7z a "build\Exporim-File-Sync-v%VER%-win-x64.zip" ".\publish\*" >> %LOG% 2>&1
)

echo (*) Tagging v%VER% and pushing to GitHub
git tag "v%VER%" >> %LOG% 2>&1
git push origin "v%VER%" >> %LOG% 2>&1

echo (*) Creating GitHub release and uploading artifacts
where gh >nul 2>&1
if errorlevel 1 (
	echo (!) GitHub CLI ^(gh^) not found on PATH -- skipping release upload.
	echo     Run manually: gh release create v%VER% "build\Exporim-File-Sync-v%VER%-Setup.exe" "build\Exporim-File-Sync-v%VER%-win-x64.zip"
	goto end
)
gh release create "v%VER%" "build\Exporim-File-Sync-v%VER%-Setup.exe" "build\Exporim-File-Sync-v%VER%-win-x64.zip" --title "v%VER%" --generate-notes >> %LOG% 2>&1
if errorlevel 1 goto builderror

echo (*) Done. See %LOG% for details.
goto end

:builderror
echo (!) Release build failed -- see %LOG%
exit /b 1

:help
@echo Usage: release.bat vernum
@echo Builds Release, publishes a self-contained win-x64 build, builds the
@echo NSIS installer stamped with the given version, zips the publish output,
@echo tags v^<vernum^> in git, and creates a GitHub release
@echo ^(gmedina-exporim/Exporim-File-Sync^) uploading both artifacts.
@echo Requires: NSIS (makensis), GitHub CLI (gh, already authenticated).

:end
