@echo off
:: Verificar permisos de administrador
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Este script debe ejecutarse como administrador.
    pause
    exit /b
)

echo ========================================
echo Iniciando Mantenimiento Completo del Sistema
echo ========================================
echo.

echo --- Verificando integridad del sistema ---
sfc /scannow
if %errorLevel% neq 0 (
    echo Error al verificar la integridad del sistema.
    pause
)

echo --- Ejecutando DISM para reparar imagen del sistema ---
DISM /Online /Cleanup-Image /CheckHealth
DISM /Online /Cleanup-Image /ScanHealth
DISM /Online /Cleanup-Image /RestoreHealth
DISM /Online /Cleanup-Image /StartComponentCleanup

echo --- Limpiando archivos temporales ---
del /s /f /q %temp%\*.*
del /s /f /q %systemroot%\temp\*.*
del /s /f /q C:\Windows\Prefetch\*.*
rd /s /q %temp%
rd /s /q %systemroot%\temp

echo --- Optimizando almacenamiento segun tipo de disco ---
for %%d in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do (
    if exist %%d:\ (
        for /f "tokens=2 delims==" %%a in ('wmic diskdrive get mediatype /value') do (
            if "%%a"=="Fixed hard disk media" (
                echo Desfragmentando disco %%d
                defrag %%d: /A
            ) else (
                echo Ejecutando TRIM en disco %%d
                fsutil behavior set DisableDeleteNotify 0
                defrag %%d: /L
            )
        )
    )
)

echo --- Limpieza de disco ---
cleanmgr /sagerun:1

echo --- Verificando errores del disco ---
chkdsk C: /f
if %errorLevel% neq 0 (
    echo Se requiere reiniciar el sistema para completar la verificacion de disco.
)

echo --- Limpiando cache DNS ---
ipconfig /flushdns

echo --- Restableciendo Winsock ---
netsh winsock reset

echo --- Restableciendo stack TCP/IP ---
netsh int ip reset

echo --- Ejecutando analisis del sistema con antimalware ---
if exist "%ProgramFiles%\Windows Defender\MpCmdRun.exe" (
    "%ProgramFiles%\Windows Defender\MpCmdRun.exe" -Scan -ScanType 1
) else (
    echo Windows Defender no esta disponible.
)

echo --- Verificando y descargando actualizaciones de Windows ---
usoclient StartScan
usoclient StartDownload
usoclient StartInstall

echo --- Optimizando servicios de inicio ---
sc config wuauserv start= auto
sc config bits start= auto
net start wuauserv
net start bits

echo ========================================
echo Mantenimiento Completo Finalizado
echo Se recomienda reiniciar el sistema
echo ========================================
pause