@echo off
echo ======================================================
echo   INSTALADOR DE DEPENDENCIAS - AAP TOLATA CHICO
echo ======================================================
echo.
echo 1. Limpiando cache...
call flutter clean
echo.
echo 2. Obteniendo paquetes...
call flutter pub get
echo.
echo 3. Generando codigo (build_runner)...
call flutter pub run build_runner build --delete-conflicting-outputs
echo.
echo 4. Verificando Firebase...
call flutterfire configure
echo.
echo ======================================================
echo   PROCESO COMPLETADO
echo   Puedes iniciar la app con: flutter run
echo ======================================================
pause
