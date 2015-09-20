@echo off

set TAGDIR=C:\Progra~1\TreeTagger

set BIN=%TAGDIR%\bin
set CMD=%TAGDIR%\cmd
set LIB=%TAGDIR%\lib
set TAGOPT=%LIB%\french-utf8.par -token -lemma -sgml -no-unknown

if "%2"=="" goto label1
perl %CMD%\utf8-tokenize.perl -f -a %LIB%\french-abbreviations-utf8 %1 | %BIN%\tree-tagger %TAGOPT% > %2
goto end

:label1
if "%1"=="" goto label2
perl %CMD%\utf8-tokenize.perl -f -a %LIB%\french-abbreviations-utf8 %1 | %BIN%\tree-tagger %TAGOPT% 
goto end

:label2
echo.
echo Usage: tag-french-utf8 file {file}
echo.

:end
