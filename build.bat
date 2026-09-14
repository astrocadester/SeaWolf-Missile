@echo off
setlocal
cd /d "%~dp0"

echo Seawolf / Missile ROM build
echo Input: src\Seawolf.asm
echo System ROM: roms\original\astro.bin

if not exist roms\original\astro.bin (
    echo.
    echo ERROR: Missing required Astrocade system ROM: roms\original\astro.bin
    exit /b 1
)

echo.
echo [1/3] Assemble the 2 KB cartridge image
if not exist src\zout mkdir src\zout
if not exist roms mkdir roms
echo ^> tools\zmac.exe -i -m -o zout\seawolf.bin -x zout\seawolf.lst Seawolf.asm
pushd src
..\tools\zmac.exe -i -m -o zout\seawolf.bin -x zout\seawolf.lst Seawolf.asm
if errorlevel 1 (
    popd
    exit /b 1
)
popd
echo Created: src\zout\seawolf.bin
echo Created: src\zout\seawolf.lst

echo.
echo [2/3] Verify cartridge and system ROM SHA-1
set "hash_failed=0"
call :verify_sha1 "src\zout\seawolf.bin" "4c2ca46ab5a00dc2eb252ee900b2760b758a2162"
call :verify_sha1 "roms\original\astro.bin" "b902c941997c9d150a560435bf517c6a28137ecc"

if "%hash_failed%"=="1" (
    echo.
    echo Build failed ROM verification.
    exit /b 1
)

echo PASS: Cartridge and Astrocade system ROMs match the required SHA-1 values.

echo.
echo [3/3] Package the standalone MAME test set
if exist roms\astrocde.zip del /Q roms\astrocde.zip
echo ^> powershell package astro.bin and seawolf\seawolf.bin as roms\astrocde.zip
powershell -NoProfile -Command "$stage=Join-Path ([IO.Path]::GetTempPath()) ([guid]::NewGuid().ToString()); try { New-Item -ItemType Directory -Path (Join-Path $stage 'seawolf') -Force | Out-Null; Copy-Item -LiteralPath 'roms\original\astro.bin' -Destination (Join-Path $stage 'astro.bin'); Copy-Item -LiteralPath 'src\zout\seawolf.bin' -Destination (Join-Path $stage 'seawolf\seawolf.bin'); Compress-Archive -Force -Path (Join-Path $stage '*') -DestinationPath 'roms\astrocde.zip' } finally { if (Test-Path -LiteralPath $stage) { Remove-Item -LiteralPath $stage -Recurse -Force } }"
if errorlevel 1 exit /b 1
echo Created: roms\astrocde.zip

echo.
echo Build complete: roms\astrocde.zip
exit /b 0

:verify_sha1
set "rom_file=%~1"
set "expected_sha1=%~2"
set "actual_sha1="
for /f "usebackq delims=" %%H in (`powershell -NoProfile -Command "(Get-FileHash -LiteralPath '%rom_file%' -Algorithm SHA1).Hash.ToLower()"`) do set "actual_sha1=%%H"
echo %actual_sha1%  %rom_file%
if /I not "%actual_sha1%"=="%expected_sha1%" (
    echo WARNING: SHA-1 mismatch for %rom_file%
    echo   Expected: %expected_sha1%
    echo   Actual:   %actual_sha1%
    set "hash_failed=1"
)
exit /b 0
