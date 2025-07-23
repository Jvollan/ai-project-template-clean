#!/usr/bin/env bash
set -e

echo "🔧 Generating MCP configuration for editor discovery..."

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to check if command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Function to read API key from .env
read_api_key() {
    local key_name="$1"
    local default_value="${2:-}"
    
    if [[ -f ".env" ]]; then
        local value=$(grep "^${key_name}=" .env 2>/dev/null | cut -d'=' -f2- | tr -d '"' | tr -d "'")
        if [[ -n "$value" ]] && [[ "$value" != "your_"* ]] && [[ "$value" != "sk-"* ]]; then
            echo "$value"
        else
            echo "$default_value"
        fi
    else
        echo "$default_value"
    fi
}

# Function to detect MCP server command path
find_mcp_command() {
    local cmd_name="$1"
    local npm_package="${2:-$1}"
    
    # Check if available as global command
    if command_exists "$cmd_name"; then
        echo "$cmd_name"
        return 0
    fi
    
    # Check if available in virtual environment
    if [[ -n "$VIRTUAL_ENV" ]] && [[ -f "$VIRTUAL_ENV/bin/$cmd_name" ]]; then
        echo "$VIRTUAL_ENV/bin/$cmd_name"
        return 0
    fi
    
    # Check if available via npx
    if command_exists "npx" && npx --no-install "$npm_package" --help &>/dev/null 2>&1; then
        echo "npx"
        return 0
    fi
    
    return 1
}

# Start building the configuration
cat > .mcp.json << EOF
{
    "mcpServers": {
EOF

servers_added=0

# Task Master MCP Server
echo -e "${BLUE}Checking Task Master...${NC}"
if task_master_cmd=$(find_mcp_command "task-master" "task-master-ai"); then
    if [[ "$servers_added" -gt 0 ]]; then echo "," >> .mcp.json; fi
    
    if [[ "$task_master_cmd" == "npx" ]]; then
        cat >> .mcp.json << EOF
        "task-master": {
            "command": "npx",
            "args": ["-y", "--package=task-master-ai", "task-master-ai"],
            "description": "AI-powered task management and project coordination",
EOF
    else
        cat >> .mcp.json << EOF
        "task-master": {
            "command": "$task_master_cmd",
            "description": "AI-powered task management and project coordination",
EOF
    fi
    
    cat >> .mcp.json << EOF
            "env": {
                "ANTHROPIC_API_KEY": "$(read_api_key ANTHROPIC_API_KEY)",
                "PERPLEXITY_API_KEY": "$(read_api_key PERPLEXITY_API_KEY)",
                "OPENAI_API_KEY": "$(read_api_key OPENAI_API_KEY)",
                "GOOGLE_API_KEY": "$(read_api_key GOOGLE_API_KEY)",
                "XAI_API_KEY": "$(read_api_key XAI_API_KEY)",
                "OPENROUTER_API_KEY": "$(read_api_key OPENROUTER_API_KEY)"
            }
        }
EOF
    ((servers_added++))
    echo -e "${GREEN}✅ Task Master configured${NC}"
else
    echo -e "${YELLOW}⚠️  Task Master not found${NC}"
fi

# Zen MCP Server
echo -e "${BLUE}Checking Zen MCP Server...${NC}"
if zen_cmd=$(find_mcp_command "zen-mcp-server"); then
    if [[ "$servers_added" -gt 0 ]]; then echo "," >> .mcp.json; fi
    
    cat >> .mcp.json << EOF
        "zen-mcp": {
            "command": "$zen_cmd",
            "description": "Multi-AI model switching and management",
            "env": {
                "ANTHROPIC_API_KEY": "$(read_api_key ANTHROPIC_API_KEY)",
                "OPENAI_API_KEY": "$(read_api_key OPENAI_API_KEY)",
                "GOOGLE_API_KEY": "$(read_api_key GOOGLE_API_KEY)",
                "PERPLEXITY_API_KEY": "$(read_api_key PERPLEXITY_API_KEY)",
                "XAI_API_KEY": "$(read_api_key XAI_API_KEY)"
            }
        }
EOF
    ((servers_added++))
    echo -e "${GREEN}✅ Zen MCP Server configured${NC}"
else
    echo -e "${YELLOW}⚠️  Zen MCP Server not found${NC}"
fi

# Claude Sessions MCP Server
echo -e "${BLUE}Checking Claude Sessions...${NC}"
if sessions_cmd=$(find_mcp_command "claude-sessions"); then
    if [[ "$servers_added" -gt 0 ]]; then echo "," >> .mcp.json; fi
    
    cat >> .mcp.json << EOF
        "claude-sessions": {
            "command": "$sessions_cmd",
            "description": "Session management and continuity for Claude",
            "env": {
                "ANTHROPIC_API_KEY": "$(read_api_key ANTHROPIC_API_KEY)"
            }
        }
EOF
    ((servers_added++))
    echo -e "${GREEN}✅ Claude Sessions configured${NC}"
else
    echo -e "${YELLOW}⚠️  Claude Sessions not found${NC}"
fi

# SuperClaude Commands (if available as MCP server)
echo -e "${BLUE}Checking SuperClaude...${NC}"
if superclaude_cmd=$(find_mcp_command "SuperClaude" "superclaude"); then
    if [[ "$servers_added" -gt 0 ]]; then echo "," >> .mcp.json; fi
    
    cat >> .mcp.json << EOF
        "superclaude": {
            "command": "$superclaude_cmd",
            "args": ["--mcp-mode"],
            "description": "90+ development commands and AI-first workflows",
            "env": {
                "ANTHROPIC_API_KEY": "$(read_api_key ANTHROPIC_API_KEY)"
            }
        }
EOF
    ((servers_added++))
    echo -e "${GREEN}✅ SuperClaude configured${NC}"
else
    echo -e "${YELLOW}⚠️  SuperClaude not found or not MCP-enabled${NC}"
fi

# Close the JSON structure
echo "
    }
}" >> .mcp.json

# Validate the generated JSON
echo -e "\n${BLUE}Validating configuration...${NC}"
if python -m json.tool .mcp.json >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Valid MCP configuration generated${NC}"
    
    # Pretty-print the configuration
    python -m json.tool .mcp.json > .mcp.json.tmp && mv .mcp.json.tmp .mcp.json
    
    echo -e "\n${BLUE}Summary:${NC}"
    echo "- Configured $servers_added MCP servers"
    echo "- Configuration saved to .mcp.json"
    
    if grep -q '""' .mcp.json; then
        echo -e "\n${YELLOW}⚠️  Some API keys are missing${NC}"
        echo "Add your API keys to .env file:"
        grep -E 'ANTHROPIC_API_KEY|OPENAI_API_KEY|GOOGLE_API_KEY|PERPLEXITY_API_KEY' .mcp.json | grep '""' | sed 's/.*"\([^"]*_API_KEY\)".*/  - \1/' | sort -u
    fi
else
    echo -e "${RED}❌ Generated configuration is invalid${NC}"
    exit 1
fi

# Create a backup of the original if it exists
if [[ -f ".mcp.json.bak" ]]; then
    echo -e "\n${BLUE}Note:${NC} Previous configuration backed up to .mcp.json.bak"
fi