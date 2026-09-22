@echo OFF
@if "%1" == "/?" goto help

:start
@echo This file is part of Exporim File-Sync.
@echo Exporim File-Sync is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
@echo Exporim File-Sync is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
@echo You should have received a copy of the GNU General Public License along with Exporim File-Sync.  If not, see http://www.gnu.org/licenses/.
@echo Created by:   Cl?ment Pit--Claudel.
@echo Web site:     https://github.com/gmedina-exporim/Exporim-File-Sync.
@echo.
@echo This is a local build + installer script (no upload). Use release.bat to
@echo cut a tagged GitHub release.

if exist build rmdir /s /q build
mkdir build
set LOG=build\buildlog.txt

(echo Build log & date /t & time /t & echo.) > %LOG%

echo (*) Building (Debug + Release)
dotnet build "Exporim File-Sync.sln" -c Debug  >> %LOG% 2>&1
if errorlevel 1 goto builderror
dotnet build "Exporim File-Sync.sln" -c Release >> %LOG% 2>&1
if errorlevel 1 goto builderror

echo (*) Publishing self-contained win-x64 (Release)
if exist publish rmdir /s /q publish
dotnet publish "Exporim File-Sync\Exporim File-Sync.vbproj" -c Release -r win-x64 --self-contained true -p:PublishSingleFile=false -o publish >> %LOG% 2>&1
if errorlevel 1 goto builderror

echo (*) Building installer
where makensis >nul 2>&1
if errorlevel 1 (
	echo (!) makensis.exe not found on PATH -- skipping installer. Install NSIS to build it.
) else (
	makensis "Exporim File-Sync\setup_script.nsi" >> %LOG% 2>&1
	if errorlevel 1 goto builderror
	move Exporim_File-Sync_Setup.exe build\Exporim_File-Sync_Setup.exe >nul
)

echo (*) Done. See %LOG% for details.
goto end

:builderror
echo (!) Build failed -- see %LOG%
exit /b 1

:help
@echo Local build: compiles Debug+Release, publishes a self-contained win-x64
@echo build to .\publish, and (if NSIS's makensis is on PATH) builds the
@echo installer into .\build\Exporim_File-Sync_Setup.exe. Does not upload
@echo anywhere -- use release.bat to cut a GitHub release.

:end
