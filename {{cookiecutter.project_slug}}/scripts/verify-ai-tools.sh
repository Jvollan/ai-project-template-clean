#!/usr/bin/env bash
set -e

echo "🧪 Verifying AI Components Installation"
echo "======================================"

ERRORS=0
WARNINGS=0

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    local status=$1
    local message=$2
    case $status in
        "OK")
            echo -e "${GREEN}✅ $message${NC}"
            ;;
        "WARN")
            echo -e "${YELLOW}⚠️  $message${NC}"
            ((WARNINGS++))
            ;;
        "ERROR")
            echo -e "${RED}❌ $message${NC}"
            ((ERRORS++))
            ;;
        "INFO")
            echo -e "${BLUE}ℹ️  $message${NC}"
            ;;
    esac
}

# Test 1: Python environment
echo -e "\n${BLUE}🐍 Testing Python Environment${NC}"
echo "================================"

if [[ -n "$VIRTUAL_ENV" ]]; then
    print_status "OK" "Virtual environment active: $(basename $VIRTUAL_ENV)"
else
    print_status "WARN" "No virtual environment detected"
fi

if command -v python &> /dev/null; then
    python_version=$(python --version 2>&1)
    print_status "OK" "Python available: $python_version"
else
    print_status "ERROR" "Python not found in PATH"
fi

# Test 2: Python component imports
echo -e "\n${BLUE}📦 Testing Python Component Imports${NC}"
echo "===================================="

# Python components to test (bash 3.2 compatible)
# Format: "import_name:display_name:fallback_imports"
python_components="zen_mcp_server:Zen MCP Server:zen_mcp,anthropic_proxy:Claude Code Proxy:,SuperClaude:SuperClaude Framework:,claude_sessions:Claude Sessions:"

# Test each component
IFS=',' read -ra COMPONENTS <<< "$python_components"
for component in "${COMPONENTS[@]}"; do
    IFS=':' read -r module display_name fallback_imports <<< "$component"
    
    # Try primary import
    if python -c "import $module" 2>/dev/null; then
        print_status "OK" "$display_name imports successfully"
    else
        # Try fallback imports if specified
        import_success=false
        if [[ -n "$fallback_imports" ]]; then
            IFS='|' read -ra FALLBACKS <<< "$fallback_imports"
            for fallback in "${FALLBACKS[@]}"; do
                if python -c "import $fallback" 2>/dev/null; then
                    print_status "OK" "$display_name imports successfully (as $fallback)"
                    import_success=true
                    break
                fi
            done
        fi
        
        if [[ "$import_success" == "false" ]]; then
            print_status "ERROR" "Failed to import $display_name ($module)"
        fi
    fi
done

# Test 3: Command availability
echo -e "\n${BLUE}🔧 Testing Command Availability${NC}"
echo "==============================="

# Commands to test (bash 3.2 compatible)
commands="zen-mcp-server:Zen MCP Server CLI,SuperClaude:SuperClaude Commands,claude-sessions:Claude Sessions CLI,task-master-py:Task Master Python Wrapper"

# Test each command
IFS=',' read -ra COMMANDS <<< "$commands"
for command_pair in "${COMMANDS[@]}"; do
    IFS=':' read -r cmd display_name <<< "$command_pair"
    if command -v "$cmd" &> /dev/null; then
        # Try to get version or help
        if timeout 3 "$cmd" --help >/dev/null 2>&1 || timeout 3 "$cmd" --version >/dev/null 2>&1; then
            print_status "OK" "$display_name command works"
        else
            print_status "WARN" "$display_name command found but may not work properly"
        fi
    else
        print_status "ERROR" "$display_name command not found"
    fi
done

# Test 4: Task Master availability (Node.js)
echo -e "\n${BLUE}📋 Testing Task Master (Node.js)${NC}"
echo "==============================="

if command -v task-master &> /dev/null; then
    if timeout 5 task-master --help >/dev/null 2>&1; then
        print_status "OK" "Task Master CLI available and working"
    else
        print_status "WARN" "Task Master found but help command failed"
    fi
elif command -v npx &> /dev/null; then
    if timeout 10 npx task-master-ai --help >/dev/null 2>&1; then
        print_status "OK" "Task Master available via npx"
    else
        print_status "WARN" "npx available but task-master-ai package not accessible"
    fi
else
    print_status "ERROR" "Task Master not available (no npm/npx found)"
    print_status "INFO" "Install Node.js and run: npm install -g task-master-ai"
fi

# Test 5: MCP Configuration
echo -e "\n${BLUE}🔌 Testing MCP Configuration${NC}"
echo "============================="

if [[ -f ".mcp.json" ]]; then
    print_status "OK" "MCP configuration file exists"
    
    # Check if it's valid JSON
    if python -m json.tool .mcp.json >/dev/null 2>&1; then
        print_status "OK" "MCP configuration is valid JSON"
        
        # Check for required servers
        if grep -q "task-master-ai" .mcp.json; then
            print_status "OK" "Task Master MCP server configured"
        else
            print_status "WARN" "Task Master MCP server not found in configuration"
        fi
        
        if grep -q "zen-mcp-server" .mcp.json; then
            print_status "OK" "Zen MCP server configured"
        else
            print_status "WARN" "Zen MCP server not found in configuration"
        fi
    else
        print_status "ERROR" "MCP configuration contains invalid JSON"
    fi
else
    print_status "ERROR" "MCP configuration file missing (.mcp.json)"
fi

# Test 6: API Keys setup
echo -e "\n${BLUE}🔑 Testing API Keys Setup${NC}"
echo "========================="

if [[ -f ".env" ]]; then
    print_status "OK" ".env file exists"
    
    # Check for common API keys (without revealing values)
    # API keys to check (bash 3.2 compatible)
    api_keys="ANTHROPIC_API_KEY:Claude API,OPENAI_API_KEY:OpenAI API,PERPLEXITY_API_KEY:Perplexity API"
    
    # Check each API key
    IFS=',' read -ra KEYS <<< "$api_keys"
    for key_pair in "${KEYS[@]}"; do
        IFS=':' read -r key display_name <<< "$key_pair"
        if grep -q "^${key}=" .env && [[ $(grep "^${key}=" .env | cut -d'=' -f2) != "" ]]; then
            print_status "OK" "$display_name configured"
        else
            print_status "WARN" "$display_name not configured in .env"
        fi
    done
else
    print_status "WARN" ".env file not found"
    print_status "INFO" "Create .env file with your API keys for full functionality"
fi

# Test 7: Claudia GUI
echo -e "\n${BLUE}🖥️  Testing Claudia GUI Setup${NC}"
echo "============================="

if [[ -d "$HOME/.claudia-source" ]]; then
    print_status "OK" "Claudia source directory exists (~/.claudia-source)"
    
    if [[ -f "$HOME/.claudia-source/package.json" ]]; then
        print_status "OK" "Claudia package.json found"
    else
        print_status "WARN" "Claudia package.json missing"
    fi
    
    # Check if built
    if [[ -d "$HOME/.claudia-source/src-tauri/target" ]]; then
        print_status "OK" "Claudia appears to be built"
    else
        print_status "INFO" "Claudia not built yet - run 'cd ~/.claudia-source && npm run build'"
    fi
else
    print_status "WARN" "Claudia source not found at ~/.claudia-source"
fi

# Test 8: Version manifest
echo -e "\n${BLUE}📋 Testing Version Manifest${NC}"
echo "==========================="

if [[ -f "AI_TOOLBOX_VERSIONS.md" ]]; then
    print_status "OK" "Version manifest exists (AI_TOOLBOX_VERSIONS.md)"
else
    print_status "WARN" "Version manifest missing"
fi

# Summary
echo -e "\n${BLUE}📊 Verification Summary${NC}"
echo "======================"

# Count components for summary (bash 3.2 compatible)
python_component_count=$(echo "$python_components" | tr ',' '\n' | wc -l | tr -d ' ')
command_count=$(echo "$commands" | tr ',' '\n' | wc -l | tr -d ' ')
total_tests=$((python_component_count + command_count + 10)) # Approximate
passed_tests=$((total_tests - ERRORS - WARNINGS))

echo -e "Total components tested: $total_tests"
echo -e "${GREEN}✅ Passed: $passed_tests${NC}"
echo -e "${YELLOW}⚠️  Warnings: $WARNINGS${NC}"
echo -e "${RED}❌ Errors: $ERRORS${NC}"

if [[ $ERRORS -eq 0 ]] && [[ $WARNINGS -eq 0 ]]; then
    echo -e "\n${GREEN}🎉 Perfect! All AI components verified successfully!${NC}"
    echo "Your project is ready for AI-first development."
    exit 0
elif [[ $ERRORS -eq 0 ]]; then
    echo -e "\n${YELLOW}✅ Good! Core components work with minor warnings.${NC}"
    echo "Address warnings for optimal experience."
    exit 0
else
    echo -e "\n${RED}⚠️  Issues detected. $ERRORS component(s) need attention.${NC}"
    echo ""
    echo "🔧 Common fixes:"
    echo "   • Ensure virtual environment is activated"
    echo "   • Run: pip install -r requirements.txt"
    echo "   • Install Node.js for Task Master"
    echo "   • Add API keys to .env file"
    echo "   • Re-run: ./scripts/add-ai-toolkit.sh"
    exit 1
fi