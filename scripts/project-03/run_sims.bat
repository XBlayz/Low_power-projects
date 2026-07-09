@echo off
setlocal enabledelayedexpansion

:: Controllo argomenti in ingresso
if "%~2"=="" (
    echo Utilizzo errato.
    echo Sintassi: %~nx0 "lista_clocks" "lista_varianti"
    echo Esempio:  %~nx0 "10.0 6.0" "baseline registering isolated_reordering"
    exit /b 1
)

set "CLOCKS=%~1"
set "VARIANTS=%~2"

:: Definizione dei path assoluti
set "ROOT_DIR=C:\Users\stefa\Workspace\01-UNICAL\Low_power-projects"
set "TCL_SCRIPT=%ROOT_DIR%\scripts\project-03\run_variant.tcl"
set "LOGS_DIR=%ROOT_DIR%\notebooks\output\project-03\sims\logs"

:: Spostamento nella directory relativa di lavoro
pushd .\notebooks\output\project-03\sims\
if %errorlevel% neq 0 (
    echo [ERRORE] Impossibile trovare la directory .\notebooks\output\project-03\sims\
    echo Assicurati di lanciare lo script dalla root del progetto.
    exit /b 1
)

:: Creazione della cartella logs se non esiste
if not exist "%LOGS_DIR%" (
    mkdir "%LOGS_DIR%"
)

:: Cicli annidati per varianti e clock
for %%V in (%VARIANTS%) do (
    for %%C in (%CLOCKS%) do (
        echo =========================================================
        echo Esecuzione: Variante = %%V ^| Clock = %%C ns
        echo =========================================================

        set "LOG_FILE=%LOGS_DIR%\%%V_%%Cns.log"

        vivado -mode batch -log "!LOG_FILE!" -source "%TCL_SCRIPT%" -tclargs %%V %%C
    )
)

:: Ritorno alla directory originale
popd
echo [INFO] Tutte le simulazioni sono state elaborate.
endlocal
