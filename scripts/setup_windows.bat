@echo off
setlocal enabledelayedexpansion

echo.
echo  ███████╗███████╗ ██████╗ ██████╗ ███╗   ██╗██████╗       ███╗   ███╗███████╗
echo  ██╔════╝██╔════╝██╔════╝██╔═══██╗████╗  ██║██╔══██╗      ████╗ ████║██╔════╝
echo  ███████╗█████╗  ██║     ██║   ██║██╔██╗ ██║██║  ██║█████╗██╔████╔██║█████╗  
echo  ╚════██║██╔══╝  ██║     ██║   ██║██║╚██╗██║██║  ██║╚════╝██║╚██╔╝██║██╔══╝  
echo  ███████║███████╗╚██████╗╚██████╔╝██║ ╚████║██████╔╝      ██║ ╚═╝ ██║███████╗
echo  ╚══════╝╚══════╝ ╚═════╝ ╚═════╝ ╚═╝  ╚═══╝╚═════╝       ╚═╝     ╚═╝╚══════╝
echo.
echo Second-Me Setup Script for Windows
echo %date% %time%
echo.
echo ====== Second-Me Complete Installation ======
echo.

echo [%date% %time%] [SECTION] Running pre-installation checks

REM Check Python version
echo [%date% %time%] [STEP] Checking for Python installation
python --version > temp_version.txt 2>&1
set /p PYTHON_VERSION=<temp_version.txt
del temp_version.txt

echo Found Python version: %PYTHON_VERSION%

REM Extract just the version number
for /f "tokens=2" %%a in ("%PYTHON_VERSION%") do set PYTHON_VERSION=%%a

REM Check if Python version is 3.12 or higher
for /f "tokens=1,2,3 delims=." %%a in ("%PYTHON_VERSION%") do (
    set MAJOR=%%a
    set MINOR=%%b
)

if %MAJOR% LSS 3 (
    echo [%date% %time%] [ERROR] Python version %PYTHON_VERSION% is not supported, please install Python 3.12 or higher
    exit /b 1
)

if %MAJOR% EQU 3 (
    if %MINOR% LSS 12 (
        echo [%date% %time%] [ERROR] Python version %PYTHON_VERSION% is not supported, please install Python 3.12 or higher
        exit /b 1
    )
)

echo [%date% %time%] [SUCCESS] Python check passed, using Python version %PYTHON_VERSION%

REM Check Poetry installation
echo [%date% %time%] [STEP] Checking for Poetry installation
where poetry > nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [%date% %time%] [ERROR] Poetry is not installed, please install Poetry manually
    echo To install Poetry, run: pip install poetry
    exit /b 1
)
echo [%date% %time%] [SUCCESS] Poetry check passed

REM Check Node.js installation
echo [%date% %time%] [STEP] Checking Node.js installation
where node > nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [%date% %time%] [ERROR] Node.js is not installed, please install Node.js manually
    echo Download Node.js from: https://nodejs.org/
    exit /b 1
)

node --version > temp_version.txt
set /p NODE_VERSION=<temp_version.txt
del temp_version.txt
echo [%date% %time%] [SUCCESS] Node.js check passed, using version %NODE_VERSION%

REM Check npm installation
echo [%date% %time%] [STEP] Checking npm installation
where npm > nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [%date% %time%] [ERROR] npm is not installed, please install npm manually
    echo npm should be installed with Node.js
    exit /b 1
)

npm --version > temp_version.txt
set /p NPM_VERSION=<temp_version.txt
del temp_version.txt
echo [%date% %time%] [SUCCESS] npm check passed, using version %NPM_VERSION%

REM Check SQLite installation
echo [%date% %time%] [STEP] Checking SQLite installation
where sqlite3 > nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [%date% %time%] [WARNING] SQLite3 is not installed or not in your PATH
    echo [%date% %time%] [ERROR] Please install SQLite before continuing, database operations require this dependency
    echo Download SQLite from: https://www.sqlite.org/download.html
    exit /b 1
)

sqlite3 --version > temp_version.txt
set /p SQLITE_VERSION=<temp_version.txt
del temp_version.txt
echo [%date% %time%] [SUCCESS] SQLite check passed, using version %SQLITE_VERSION%

REM Install Python dependencies
echo [%date% %time%] [SECTION] Starting installation
echo [%date% %time%] [STEP] Installing Python packages using Poetry

cd /d "%~dp0.."
echo Current directory: %CD%

echo [%date% %time%] [INFO] Running: poetry install
poetry install
if %ERRORLEVEL% NEQ 0 (
    echo [%date% %time%] [ERROR] Failed to install Python dependencies
    exit /b 1
)
echo [%date% %time%] [SUCCESS] Python dependencies installed successfully

REM Install GraphRAG
echo [%date% %time%] [STEP] Installing GraphRAG
echo [%date% %time%] [INFO] Running: poetry run pip install graphrag
poetry run pip install graphrag
if %ERRORLEVEL% NEQ 0 (
    echo [%date% %time%] [ERROR] Failed to install GraphRAG
    exit /b 1
)
echo [%date% %time%] [SUCCESS] GraphRAG installed successfully

REM Build frontend
echo [%date% %time%] [STEP] Building frontend
cd /d "%~dp0..\lpm_frontend"
echo Current directory: %CD%

echo [%date% %time%] [INFO] Running: npm install
npm install
if %ERRORLEVEL% NEQ 0 (
    echo [%date% %time%] [ERROR] Failed to install frontend dependencies
    exit /b 1
)

echo [%date% %time%] [INFO] Running: npm run build
npm run build
if %ERRORLEVEL% NEQ 0 (
    echo [%date% %time%] [ERROR] Failed to build frontend
    exit /b 1
)
echo [%date% %time%] [SUCCESS] Frontend built successfully

echo [%date% %time%] [SUCCESS] Installation complete!
echo.
echo You can now start Second-Me by running: make start
echo.

exit /b 0
