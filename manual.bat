@if "%1" == "/?" goto help

:start
@echo This file is part of Exporim File-Sync.
@echo Exporim File-Sync is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
@echo Exporim File-Sync is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
@echo You should have received a copy of the GNU General Public License along with Exporim File-Sync.  If not, see http://www.gnu.org/licenses/.
@echo Created by:   Clément Pit--Claudel.
@echo Web site:     http://synchronicity.sourceforge.net.

@set LOCALROOT=..\..\..\..\..\Sites Web\Sourceforge\Synchronicity
@set WEBPAGES=%LOCALROOT%\pages

Xhtml2Latex.exe "%WEBPAGES%\help.php" "%WEBPAGES%\help.tex" /webroot "http://synchronicity.sourceforge.net/" /localroot "%LOCALROOT%\\" /wrap

copy "%WEBPAGES%\help.tex" "build\Exporim File-Sync User Manual.tex"
copy "%WEBPAGES%\help.pdf" "build\Exporim File-Sync User Manual.pdf"
"C:\Program Files (x86)\PuTTY\pscp.exe" "build\Exporim File-Sync User Manual.pdf" "build\Exporim File-Sync User Manual.tex" "createsoftware,synchronicity@web.sourceforge.net:/home/groups/s/sy/synchronicity/htdocs/pages"

@goto end

:help
@echo This script will build the PDF Manual for Exporim File-Sync.
@echo Usage: manual.bat

:end