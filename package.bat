@echo OFF
@if "%1" == "/?" goto help

:start
@echo This file is part of Exporim File-Sync.
@echo Exporim File-Sync is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
@echo Exporim File-Sync is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
@echo You should have received a copy of the GNU General Public License along with Exporim File-Sync.  If not, see http://www.gnu.org/licenses/.
@echo Created by:   Clément Pit--Claudel.
@echo Web site:     http://synchronicity.sourceforge.net.
@echo.

@set REV=%1
@set LOG="build\buildlog-r%REV%.txt"
mkdir build

(echo Packaging log for r%REV% & date /t & time /t & echo.) > %LOG%

echo (*) Updating revision number
(
echo.
echo -----
cd "Exporim File-Sync"
subwcrev.exe .. Revision.template.vb Revision.vb
cd ..
) >> %LOG%

echo (*) Building program (release)
"C:\Program Files (x86)\Microsoft Visual Studio 10.0\Common7\IDE\devenv.exe" "Exporim File-Sync.sln" /Rebuild Release /Out %LOG%

echo (*) Building program (debug)
"C:\Program Files (x86)\Microsoft Visual Studio 10.0\Common7\IDE\devenv.exe" "Exporim File-Sync.sln" /Rebuild Debug /Out %LOG%

echo (*) Building installer
(
echo.
echo -----
"C:\Program Files (x86)\NSIS\makensis.exe" "Exporim File-Sync\setup_script.nsi"
echo.
echo -----
move Create_Synchronicity_Setup.exe "build\Create_Synchronicity_Setup-r%REV%.exe"
) >> %LOG%

echo (*) Building zip files
(
echo.
echo -----
cd "Exporim File-Sync\bin\Release"
"C:\Program Files\7-Zip\7z.exe" a "..\..\..\build\Create_Synchronicity-r%REV%.zip" "Exporim File-Sync.exe" "Release notes.txt" "COPYING" "languages\*"
cd ..\..\..

cd "Exporim File-Sync\bin\Debug"
"C:\Program Files\7-Zip\7z.exe" a "..\..\..\build\Create_Synchronicity-r%REV%-DEBUG.zip" "Exporim File-Sync.exe" "Release notes.txt" "COPYING" "languages\*"
"C:\Program Files\7-Zip\7z.exe" a "..\..\..\build\Create_Synchronicity-r%REV%-Extensions.zip" "compress.dll" "ICSharpCode.SharpZipLib.dll"
cd ..\..\..

cd "Exporim File-Sync\bin\Linux"
"C:\Program Files\7-Zip\7z.exe" a "..\..\..\build\Create_Synchronicity-r%REV%-Linux.zip" "Exporim File-Sync.exe" "Release notes.txt" "run-create-synchronicity.sh" "COPYING" "languages\*"
cd ..\..\..
) >> %LOG%

echo (*) Creating current-build.txt
(
echo.
echo -----
) >> %LOG%

(
echo Current build: r%REV% & date /t & time /t
echo.
echo "https://sourceforge.net/projects/synchronicity/files/Exporim File-Sync/Unreleased (SVN Builds)/Create_Synchronicity-r%REV%.zip/download"
echo "https://sourceforge.net/projects/synchronicity/files/Exporim File-Sync/Unreleased (SVN Builds)/Create_Synchronicity_Setup-r%REV%.exe/download"
echo "https://sourceforge.net/projects/synchronicity/files/Exporim File-Sync/Unreleased (SVN Builds)/Create_Synchronicity-r%REV%-DEBUG.zip/download"
echo "https://sourceforge.net/projects/synchronicity/files/Exporim File-Sync/Unreleased (SVN Builds)/Create_Synchronicity-r%REV%-Linux.zip/download"
echo "https://sourceforge.net/projects/synchronicity/files/Exporim File-Sync/Unreleased (SVN Builds)/Create_Synchronicity-r%REV%-Extensions.zip/download"
) > build\current-build.txt

echo (*) Uploading builds to frs.sourceforge.net and rev info to web.sourceforge.net
(
echo.
echo -----
echo Uploading files via SCP.
"C:\Program Files (x86)\PuTTY\pscp.exe" "build\current-build.txt" "createsoftware,synchronicity@web.sourceforge.net:/home/groups/s/sy/synchronicity/htdocs/code"
"C:\Program Files (x86)\PuTTY\pscp.exe" "build\Create_Synchronicity-r%REV%.zip" "build\Create_Synchronicity-r%REV%-DEBUG.zip" "build\Create_Synchronicity_Setup-r%REV%.exe" "build\Create_Synchronicity-r%REV%-Linux.zip" "build\Create_Synchronicity-r%REV%-Extensions.zip" "createsoftware,synchronicity@frs.sourceforge.net:/home/pfs/project/s/sy/synchronicity/Exporim File-Sync/Unreleased (SVN Builds)"
) >> %LOG%

echo (*) Building manual and uploading it to web.sourceforge.net.
(
echo.
echo -----
call manual.bat
) >> %LOG%

@goto end

:help
@echo This script is designed to be called by a SVN hook script.
@echo If used from the command line, it should be passed the revision number as its first parameter.
@echo Requires 7-zip installed in "C:\Program Files\7-Zip\7z.exe" and Putty installed in "C:\Program Files (x86)\PuTTY\pscp.exe".
@echo Pageant (putty key handler) should be told about the private key to connect to the scp server.
:end