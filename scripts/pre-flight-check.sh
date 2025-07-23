#!/usr/bin/env bash
# Pre-flight check script to validate environment before installation
set -e

echo "🛫 Running Pre-Flight Checks for AI Toolkit Installation"
echo "========================================================"

# Configuration
REQUIRED_PYTHON="3.12"
MIN_NODE_VERSION="16"
ENV_SEARCH_PATHS=(
    ".env"
    "../.env"
    "../../.env"
    "../../../.env"
    "$HOME/allprojects/claude_code_cursor_project/.env"
    "$HOME/.env"
)

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

ERRORS=0
WARNINGS=0

print_status() {
    local status=$1
    local message=$2
    case $status in
        "OK") echo -e "${GREEN}✅ $message${NC}" ;;
        "WARN") echo -e "${YELLOW}⚠️  $message${NC}"; ((WARNINGS++)) ;;
        "ERROR") echo -e "${RED}❌ $message${NC}"; ((ERRORS++)) ;;
        "INFO") echo -e "${BLUE}ℹ️  $message${NC}" ;;
    esac
}

# Function to find .env file
find_env_file() {
    for path in "${ENV_SEARCH_PATHS[@]}"; do
        if [[ -f "$path" ]]; then
            echo "$path"
            return 0
        fi
    done
    return 1
}

# Check 1: Operating System
echo -e "\n${BLUE}🖥️  System Information${NC}"
echo "======================"
OS_TYPE=$(uname -s)
OS_VERSION=$(uname -r)
print_status "INFO" "Operating System: $OS_TYPE $OS_VERSION"

if [[ "$OS_TYPE" == "Darwin" ]]; then
    MACOS_VERSION=$(sw_vers -productVersion)
    print_status "INFO" "macOS Version: $MACOS_VERSION"
    print_status "OK" "macOS detected - bash compatibility handled"
fi

# Check 2: Python Version
echo -e "\n${BLUE}🐍 Python Environment${NC}"
echo "===================="
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
    if [[ "$PYTHON_VERSION" == "$REQUIRED_PYTHON" ]]; then
        print_status "OK" "Python $PYTHON_VERSION found"
    else
        print_status "WARN" "Python $PYTHON_VERSION found (expected $REQUIRED_PYTHON)"
        print_status "INFO" "Install Python $REQUIRED_PYTHON: brew install python@$REQUIRED_PYTHON"
    fi
    
    # Check pip
    if python3 -m pip --version &> /dev/null; then
        print_status "OK" "pip is available"
    else
        print_status "ERROR" "pip not found"
    fi
else
    print_status "ERROR" "Python3 not found"
    if [[ "$OS_TYPE" == "Darwin" ]]; then
        print_status "INFO" "Install with: brew install python@$REQUIRED_PYTHON"
    fi
fi

# Check 3: Node.js
echo -e "\n${BLUE}📦 Node.js Environment${NC}"
echo "====================="
if command -v node &> /dev/null; then
    NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
    if [[ "$NODE_VERSION" -ge "$MIN_NODE_VERSION" ]]; then
        print_status "OK" "Node.js v$(node -v | cut -d'v' -f2) found"
    else
        print_status "WARN" "Node.js v$(node -v | cut -d'v' -f2) found (v$MIN_NODE_VERSION+ recommended)"
    fi
    
    # Check npm
    if command -v npm &> /dev/null; then
        print_status "OK" "npm $(npm -v) found"
        
        # Check global install permissions
        NPM_PREFIX=$(npm config get prefix 2>/dev/null || echo "/usr/local")
        if [[ -w "$NPM_PREFIX/lib/node_modules" ]]; then
            print_status "OK" "npm global install permissions OK"
        else
            print_status "WARN" "npm global installs may require sudo"
            print_status "INFO" "Fix with: npm config set prefix ~/.npm-global"
        fi
    else
        print_status "ERROR" "npm not found"
    fi
else
    print_status "ERROR" "Node.js not found"
    if [[ "$OS_TYPE" == "Darwin" ]]; then
        print_status "INFO" "Install with: brew install node"
    fi
fi

# Check 4: Git
echo -e "\n${BLUE}🔧 Git Configuration${NC}"
echo "==================="
if command -v git &> /dev/null; then
    GIT_VERSION=$(git --version | cut -d' ' -f3)
    print_status "OK" "Git $GIT_VERSION found"
    
    # Check GitHub auth
    if git config --get user.email &> /dev/null; then
        print_status "OK" "Git user configured: $(git config --get user.email)"
    else
        print_status "WARN" "Git user not configured"
    fi
    
    # Test GitHub access
    if timeout 5 git ls-remote https://github.com/jvollan/ai-toolbox.git &> /dev/null; then
        print_status "OK" "GitHub access verified"
    else
        print_status "WARN" "Cannot access GitHub (may be private repo or network issue)"
    fi
else
    print_status "ERROR" "Git not found"
fi

# Check 5: Network Connectivity
echo -e "\n${BLUE}🌐 Network Connectivity${NC}"
echo "======================"
# Test various endpoints
declare -a endpoints=(
    "github.com:443"
    "pypi.org:443"
    "registry.npmjs.org:443"
)

for endpoint in "${endpoints[@]}"; do
    host="${endpoint%:*}"
    port="${endpoint##*:}"
    if timeout 5 bash -c "echo >/dev/tcp/$host/$port" 2>/dev/null; then
        print_status "OK" "Can reach $host"
    else
        print_status "WARN" "Cannot reach $host (port $port)"
    fi
done

# Check 6: Environment Variables
echo -e "\n${BLUE}🔑 API Keys & Environment${NC}"
echo "========================"
ENV_FILE=$(find_env_file)
if [[ -n "$ENV_FILE" ]]; then
    print_status "OK" "Found .env file: $ENV_FILE"
    
    # Create symlink for easy access
    if [[ "$ENV_FILE" != ".env" ]] && [[ ! -e ".env" ]]; then
        ln -s "$ENV_FILE" .env
        print_status "OK" "Created .env symlink to $ENV_FILE"
    fi
    
    # Check for required keys (without revealing values)
    required_keys=("ANTHROPIC_API_KEY")
    optional_keys=("OPENAI_API_KEY" "PERPLEXITY_API_KEY" "GOOGLE_API_KEY")
    
    for key in "${required_keys[@]}"; do
        if grep -q "^${key}=" "$ENV_FILE" && [[ -n "$(grep "^${key}=" "$ENV_FILE" | cut -d'=' -f2-)" ]]; then
            print_status "OK" "$key configured"
        else
            print_status "ERROR" "$key missing or empty"
        fi
    done
    
    for key in "${optional_keys[@]}"; do
        if grep -q "^${key}=" "$ENV_FILE" && [[ -n "$(grep "^${key}=" "$ENV_FILE" | cut -d'=' -f2-)" ]]; then
            print_status "OK" "$key configured (optional)"
        else
            print_status "INFO" "$key not configured (optional)"
        fi
    done
else
    print_status "ERROR" "No .env file found in search paths"
fi

# Check 7: Directory Permissions
echo -e "\n${BLUE}📁 Directory Permissions${NC}"
echo "======================="
CURRENT_DIR=$(pwd)
if [[ -w "$CURRENT_DIR" ]]; then
    print_status "OK" "Current directory is writable"
else
    print_status "ERROR" "Cannot write to current directory"
fi

# Check for potential permission issues
if [[ "$OS_TYPE" == "Darwin" ]]; then
    # Check for common macOS issues
    if [[ -d "/usr/local/bin" ]] && [[ -w "/usr/local/bin" ]]; then
        print_status "OK" "/usr/local/bin is writable"
    else
        print_status "WARN" "/usr/local/bin may need sudo for global installs"
    fi
fi

# Check 8: System Dependencies
echo -e "\n${BLUE}🔧 System Dependencies${NC}"
echo "====================="
# Check for common build tools
if [[ "$OS_TYPE" == "Darwin" ]]; then
    if command -v clang &> /dev/null; then
        print_status "OK" "Xcode Command Line Tools installed"
    else
        print_status "WARN" "Xcode Command Line Tools may be needed"
        print_status "INFO" "Install with: xcode-select --install"
    fi
fi

# Check disk space
AVAILABLE_SPACE=$(df -BG . | tail -1 | awk '{print $4}' | sed 's/G//')
if [[ "$AVAILABLE_SPACE" -gt 5 ]]; then
    print_status "OK" "Disk space available: ${AVAILABLE_SPACE}GB"
else
    print_status "WARN" "Low disk space: ${AVAILABLE_SPACE}GB (5GB+ recommended)"
fi

# Check 9: Virtual Environment
echo -e "\n${BLUE}🐍 Virtual Environment Status${NC}"
echo "============================"
if [[ -n "$VIRTUAL_ENV" ]]; then
    print_status "OK" "Virtual environment active: $(basename $VIRTUAL_ENV)"
elif [[ -d "venv" ]]; then
    print_status "INFO" "Virtual environment exists but not activated"
    print_status "INFO" "Activate with: source venv/bin/activate"
else
    print_status "INFO" "No virtual environment found (will be created)"
fi

# Check 10: MCP Configuration
echo -e "\n${BLUE}🔌 MCP Configuration${NC}"
echo "===================="
if [[ -f ".mcp.json" ]]; then
    print_status "OK" "MCP configuration file exists"
    
    # Validate JSON syntax
    if python3 -m json.tool .mcp.json >/dev/null 2>&1; then
        print_status "OK" "MCP configuration has valid JSON syntax"
        
        # Check for required servers
        if grep -q '"task-master"' .mcp.json || grep -q '"task-master-ai"' .mcp.json; then
            print_status "OK" "Task Master MCP server configured"
        else
            print_status "WARN" "Task Master MCP server not found in configuration"
        fi
        
        if grep -q '"zen-mcp"' .mcp.json || grep -q '"zen-mcp-server"' .mcp.json; then
            print_status "OK" "Zen MCP server configured"
        else
            print_status "WARN" "Zen MCP server not found in configuration"
        fi
        
        # Check for empty API keys
        if grep -q '""' .mcp.json; then
            print_status "WARN" "MCP configuration has empty API key fields"
            print_status "INFO" "Run: ./scripts/generate-mcp-config.sh to auto-populate from .env"
        fi
        
        # Check if commands exist (basic validation)
        if command -v jq &> /dev/null; then
            # Use jq if available for better parsing
            commands=$(jq -r '.mcpServers[].command' .mcp.json 2>/dev/null | sort -u)
            for cmd in $commands; do
                if [[ "$cmd" == "npx" ]]; then
                    print_status "INFO" "MCP server will use npx for command execution"
                elif command -v "$cmd" &> /dev/null 2>&1; then
                    print_status "OK" "Command '$cmd' is available"
                elif [[ "$cmd" == *"/"* ]] && [[ -x "$cmd" ]]; then
                    print_status "OK" "Command '$cmd' exists (absolute path)"
                else
                    print_status "WARN" "Command '$cmd' not found in PATH"
                fi
            done
        else
            # Fallback without jq
            print_status "INFO" "Install jq for detailed MCP command validation"
        fi
    else
        print_status "ERROR" "MCP configuration contains invalid JSON"
        print_status "INFO" "Validate with: python3 -m json.tool .mcp.json"
    fi
else
    print_status "INFO" "No MCP configuration file found"
    print_status "INFO" "Will be created during installation"
fi

# Check if generate script exists
if [[ -f "scripts/generate-mcp-config.sh" ]]; then
    print_status "OK" "MCP configuration generator available"
else
    print_status "INFO" "MCP generator will be created during installation"
fi

# Summary
echo -e "\n${BLUE}📊 Pre-Flight Check Summary${NC}"
echo "=========================="
echo "Total Errors: $ERRORS"
echo "Total Warnings: $WARNINGS"

if [[ $ERRORS -eq 0 ]]; then
    echo -e "\n${GREEN}✅ All critical checks passed! Ready for installation.${NC}"
    
    if [[ $WARNINGS -gt 0 ]]; then
        echo -e "${YELLOW}⚠️  Some warnings detected but installation can proceed.${NC}"
    fi
    
    echo -e "\n🚀 Next step: Run ${GREEN}bash scripts/bootstrap.sh${NC}"
    exit 0
else
    echo -e "\n${RED}❌ Critical issues found. Please fix errors before proceeding.${NC}"
    echo -e "\n📋 Quick fixes:"
    
    if ! command -v python3 &> /dev/null; then
        echo "   • Install Python: brew install python@$REQUIRED_PYTHON"
    fi
    
    if ! command -v node &> /dev/null; then
        echo "   • Install Node.js: brew install node"
    fi
    
    if ! command -v git &> /dev/null; then
        echo "   • Install Git: brew install git"
    fi
    
    if [[ -z "$ENV_FILE" ]]; then
        echo "   • Create .env file with API keys"
    fi
    
    if [[ ! -f ".mcp.json" ]]; then
        echo "   • MCP config will be generated during installation"
    fi
    
    exit 1
fi