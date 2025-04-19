#!/bin/bash

# Display header
echo ""
echo ' ███████╗███████╗ ██████╗ ██████╗ ███╗   ██╗██████╗       ███╗   ███╗███████╗'
echo ' ██╔════╝██╔════╝██╔════╝██╔═══██╗████╗  ██║██╔══██╗      ████╗ ████║██╔════╝'
echo ' ███████╗█████╗  ██║     ██║   ██║██╔██╗ ██║██║  ██║█████╗██╔████╔██║█████╗  '
echo ' ╚════██║██╔══╝  ██║     ██║   ██║██║╚██╗██║██║  ██║╚════╝██║╚██╔╝██║██╔══╝  '
echo ' ███████║███████╗╚██████╗╚██████╔╝██║ ╚████║██████╔╝      ██║ ╚═╝ ██║███████╗'
echo ' ╚══════╝╚══════╝ ╚═════╝ ╚═════╝ ╚═╝  ╚═══╝╚═════╝       ╚═╝     ╚═╝╚══════╝'
echo ""
echo "Second-Me Setup Script for Git Bash (MinGW)"
echo "$(date)"
echo ""
echo "====== Second-Me Complete Installation ======"
echo ""

# Function to log messages
log_info() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] $1"
}

log_step() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [STEP] $1"
}

log_success() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [SUCCESS] $1"
}

log_error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] $1"
}

log_warning() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [WARNING] $1"
}

log_section() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [SECTION] $1"
}

# Check Python version
log_section "Running pre-installation checks"
log_step "Checking for Python installation"

if ! command -v python &> /dev/null; then
    log_error "Python is not installed or not in your PATH"
    exit 1
fi

PYTHON_VERSION=$(python --version 2>&1)
echo "Found Python version: $PYTHON_VERSION"

# Extract just the version number
PYTHON_VERSION=$(echo $PYTHON_VERSION | cut -d ' ' -f 2)
MAJOR_VERSION=$(echo $PYTHON_VERSION | cut -d '.' -f 1)
MINOR_VERSION=$(echo $PYTHON_VERSION | cut -d '.' -f 2)

if [ "$MAJOR_VERSION" -lt 3 ] || ([ "$MAJOR_VERSION" -eq 3 ] && [ "$MINOR_VERSION" -lt 12 ]); then
    log_error "Python version $PYTHON_VERSION is not supported, please install Python 3.12 or higher"
    exit 1
fi

log_success "Python check passed, using Python version $PYTHON_VERSION"

# Check Poetry installation - using Python module instead of command
log_step "Checking for Poetry installation"

# Use python to check if poetry is installed as a module
POETRY_CHECK=$(python -m pip show poetry 2>/dev/null)
if [ -z "$POETRY_CHECK" ]; then
    log_error "Poetry is not installed, please install Poetry manually"
    log_info "To install Poetry, run: pip install poetry"
    exit 1
fi

log_success "Poetry check passed, using Python module"
# Define poetry command using python -m
POETRY_CMD="python -m poetry"

# Check Node.js installation
log_step "Checking Node.js installation"
if ! command -v node &> /dev/null; then
    log_error "Node.js is not installed, please install Node.js manually"
    log_info "Download Node.js from: https://nodejs.org/"
    exit 1
fi

NODE_VERSION=$(node --version)
log_success "Node.js check passed, using version $NODE_VERSION"

# Check npm installation
log_step "Checking npm installation"
if ! command -v npm &> /dev/null; then
    log_error "npm is not installed, please install npm manually"
    log_info "npm should be installed with Node.js"
    exit 1
fi

NPM_VERSION=$(npm --version)
log_success "npm check passed, using version $NPM_VERSION"

# Check SQLite installation
log_step "Checking SQLite installation"
if ! command -v sqlite3 &> /dev/null; then
    log_warning "SQLite3 is not installed or not in your PATH"
    log_error "Please install SQLite before continuing, database operations require this dependency"
    log_info "Download SQLite from: https://www.sqlite.org/download.html"
    exit 1
fi

SQLITE_VERSION=$(sqlite3 --version | awk '{print $1}')
log_success "SQLite check passed, using version $SQLITE_VERSION"

# Install Python dependencies
log_section "Starting installation"
log_step "Installing Python packages using Poetry"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."
log_info "Current directory: $(pwd)"

# Configure Poetry to use Tsinghua mirror for PyPI
log_info "Configuring Poetry to use Tsinghua mirror"
$POETRY_CMD config repositories.tsinghua https://pypi.tuna.tsinghua.edu.cn/simple
$POETRY_CMD config http-basic.tsinghua "" ""

# Use Poetry source command to add Tsinghua mirror
log_info "Adding Tsinghua mirror to Poetry sources"
$POETRY_CMD source add --priority=default tsinghua https://pypi.tuna.tsinghua.edu.cn/simple/

# Update lockfile before installing
log_info "Updating Poetry lockfile"
$POETRY_CMD lock --no-update

# Install only core dependencies (no dev dependencies)
log_info "Running: $POETRY_CMD install without dev dependencies"
$POETRY_CMD install --without dev --no-interaction
if [ $? -ne 0 ]; then
    log_error "Failed to install core Python dependencies"
    exit 1
fi
log_success "Core Python dependencies installed successfully"

# Install GraphRAG
log_step "Installing GraphRAG"
log_info "Running: $POETRY_CMD run pip install graphrag -i https://pypi.tuna.tsinghua.edu.cn/simple"
$POETRY_CMD run pip install graphrag -i https://pypi.tuna.tsinghua.edu.cn/simple
if [ $? -ne 0 ]; then
    log_error "Failed to install GraphRAG"
    exit 1
fi
log_success "GraphRAG installed successfully"

# Build frontend
log_step "Building frontend"
cd "$SCRIPT_DIR/../lpm_frontend"
log_info "Current directory: $(pwd)"

log_info "Running: npm install"
npm install
if [ $? -ne 0 ]; then
    log_error "Failed to install frontend dependencies"
    exit 1
fi

log_info "Running: npm run build"
npm run build
if [ $? -ne 0 ]; then
    log_error "Failed to build frontend"
    exit 1
fi
log_success "Frontend built successfully"

log_success "Installation complete!"
echo ""
echo "You can now start Second-Me by running: make start"
echo ""

exit 0
