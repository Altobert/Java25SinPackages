@echo off
setlocal EnableDelayedExpansion
cd /d "%~dp0"

set "JAVA25_HOME=D:\java25\jdk-25.0.2_windows-x64\jdk-25.0.2"
set "JAVAC_CMD=javac"
set "JAVA_CMD=java"
set "JAVAC_FLAGS="
set "JAVA_FLAGS="

if exist "%JAVA25_HOME%\bin\javac.exe" (
    set "JAVAC_CMD=%JAVA25_HOME%\bin\javac.exe"
    set "JAVA_CMD=%JAVA25_HOME%\bin\java.exe"
    set "JAVAC_FLAGS=--enable-preview --source 25"
    set "JAVA_FLAGS=--enable-preview"
    echo Usando JDK 25 local: "%JAVA25_HOME%"
) else (
    echo Aviso: no se encontro JDK 25 local en "%JAVA25_HOME%".
    echo Se usaran java/javac del PATH actual.
)

set "DEFAULT_CAP_DIR=cap03"
set "CAP_DIR=%DEFAULT_CAP_DIR%"
set "MAIN_CLASS="
set "ARG1=%~1"

if /I "%~1"=="" goto args_done

if /I "%ARG1:~0,3%"=="cap" (
    set "CAP_DIR=%ARG1%"
    set "MAIN_CLASS=%~2"
) else (
    set "MAIN_CLASS=%~1"
)

:args_done
set "BIN_ROOT=%CD%\bin"
set "OUT_DIR=%BIN_ROOT%\%CAP_DIR%"

if not exist "%CAP_DIR%\*.java" (
    echo No se encontraron archivos .java en "%CAP_DIR%".
    echo Uso: compile-run.bat [capXX] [NombreClaseConMain]
    exit /b 1
)

pushd "%CAP_DIR%"

if not exist "%OUT_DIR%" mkdir "%OUT_DIR%"

if exist "*.class" del /q "*.class"

popd

for /d %%D in (cap*) do (
    if /I not "%%D"=="%CAP_DIR%" (
        if exist "%%D\*.java" (
            if not exist "%BIN_ROOT%\%%D" mkdir "%BIN_ROOT%\%%D"
            pushd "%%D"
            "%JAVAC_CMD%" %JAVAC_FLAGS% -d "%BIN_ROOT%\%%D" *.java >nul 2>nul
            if exist "*.class" del /q "*.class"
            popd
        )
    )
)

set "BIN_CP="
for /d %%B in ("%BIN_ROOT%\cap*") do (
    if defined BIN_CP (
        set "BIN_CP=!BIN_CP!;%%~fB"
    ) else (
        set "BIN_CP=%%~fB"
    )
)

if not defined BIN_CP set "BIN_CP=%OUT_DIR%"

pushd "%CAP_DIR%"

echo Compilando archivos Java de "%CAP_DIR%"...
"%JAVAC_CMD%" %JAVAC_FLAGS% -cp "%BIN_CP%" -d "%OUT_DIR%" *.java
if errorlevel 1 (
    echo Error en la compilacion.
    popd
    exit /b 1
)

if exist "*.class" del /q "*.class"

echo Compilacion exitosa.
echo.

if "%MAIN_CLASS%"=="" (
    for %%F in (*.java) do (
        findstr /C:"public static void main" "%%F" >nul
        if not errorlevel 1 (
            if not defined MAIN_CLASS set "MAIN_CLASS=%%~nF"
        )
    )
)

if "%MAIN_CLASS%"=="" (
    echo No se encontro ninguna clase con metodo main en "%CAP_DIR%".
    echo Uso: compile-run.bat [capXX] [NombreClaseConMain]
    popd
    exit /b 0
)

set "RUN_CLASS=%MAIN_CLASS%"
if "%MAIN_CLASS:.=%"=="%MAIN_CLASS%" (
    if exist "%MAIN_CLASS%.java" (
        set "PKG_NAME="
        for /f "tokens=2" %%P in ('findstr /R /C:"^package " "%MAIN_CLASS%.java"') do set "PKG_NAME=%%P"
        if defined PKG_NAME (
            set "PKG_NAME=!PKG_NAME:;=!"
            set "RUN_CLASS=!PKG_NAME!.%MAIN_CLASS%"
        )
    )
)

echo Ejecutando %RUN_CLASS%...
"%JAVA_CMD%" %JAVA_FLAGS% -cp "%BIN_CP%" %RUN_CLASS%

popd
pause
