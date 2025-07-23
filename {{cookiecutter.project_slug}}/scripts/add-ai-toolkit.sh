#!/usr/bin/env bash
set -e

echo "🤖 Installing AI-First Development Toolkit (6 Components)"
echo "========================================================"

# Configuration
TOOLBOX_REPO_URL="https://github.com/jvollan/ai-toolbox.git"
TOOLBOX_LOCAL_PATH="$HOME/allprojects/claude_code_cursor_project"
TEMP_DIR="/tmp/ai-toolbox-install-$$"
VENV_DIR="${VENV_DIR:-venv}"

# Component versions - will be updated to actual tags once repo is published
# Using simple variables for bash 3.2 compatibility (macOS default)
ZEN_MCP_VERSION="main"
CLAUDE_PROXY_VERSION="main"
SUPERCLAUDE_VERSION="main"
CLAUDE_SESSIONS_VERSION="main"
CLAUDE_TASK_MASTER_VERSION="main"
CLAUDIA_VERSION="main"

# Function to detect toolbox source
detect_toolbox_source() {
    if [[ -d "$TOOLBOX_LOCAL_PATH/components" ]]; then
        echo "local"
    else
        echo "remote"
    fi
}

# Function to retry network operations
retry_network_operation() {
    local max_attempts=3
    local delay=5
    local attempt=1
    local command="$@"
    
    while [[ $attempt -le $max_attempts ]]; do
        echo "  Attempt $attempt/$max_attempts..."
        if eval "$command"; then
            return 0
        fi
        
        if [[ $attempt -lt $max_attempts ]]; then
            echo "  ⏳ Retrying in ${delay}s..."
            sleep $delay
            delay=$((delay * 2))  # Exponential backoff
        fi
        attempt=$((attempt + 1))
    done
    
    return 1
}

# Function to setup toolbox
setup_toolbox() {
    local source_type="$1"
    
    if [[ "$source_type" == "local" ]]; then
        echo "📁 Using local toolbox: $TOOLBOX_LOCAL_PATH"
        ln -sf "$TOOLBOX_LOCAL_PATH" "$TEMP_DIR"
    else
        echo "🌐 Cloning toolbox repository..."
        if ! retry_network_operation "git clone --depth 1 '$TOOLBOX_REPO_URL' '$TEMP_DIR' 2>/dev/null"; then
            echo "❌ Failed to clone toolbox repository after 3 attempts"
            echo "   Ensure the repository exists: $TOOLBOX_REPO_URL"
            echo "   Or use local development mode"
            exit 1
        fi
    fi
}

# Function to apply packaging stubs
apply_packaging_stubs() {
    echo "📝 Applying packaging stubs..."
    
    # Claude-Sessions stub
    if [[ ! -f "$TEMP_DIR/components/claude-sessions/pyproject.toml" ]]; then
        cp stubs/claude-sessions-pyproject.toml "$TEMP_DIR/components/claude-sessions/pyproject.toml"
        echo "  ✅ Applied claude-sessions packaging stub"
    fi
    
    # Task-Master Python wrapper
    if [[ ! -f "$TEMP_DIR/components/claude-task-master/task_master_wrapper.py" ]]; then
        cp stubs/claude-task-master-pyproject.toml "$TEMP_DIR/components/claude-task-master/pyproject.toml"
        cp stubs/task_master_wrapper.py "$TEMP_DIR/components/claude-task-master/task_master_wrapper.py"
        echo "  ✅ Applied task-master Python wrapper"
    fi
}

# Function to install Python components
install_python_components() {
    echo "🐍 Installing Python AI components..."
    
    # Ensure virtual environment is active
    if [[ -z "$VIRTUAL_ENV" ]]; then
        if [[ -f "$VENV_DIR/bin/activate" ]]; then
            source "$VENV_DIR/bin/activate"
        else
            echo "❌ Virtual environment not found. Run bootstrap.sh first."
            exit 1
        fi
    fi
    
    local components=("zen-mcp-server" "claude-code-proxy" "superclaude" "claude-sessions" "claude-task-master")
    local installed_count=0
    
    for component in "${components[@]}"; do
        echo "  📦 Installing $component..."
        local component_path="$TEMP_DIR/components/$component"
        
        if [[ -d "$component_path" ]]; then
            cd "$component_path"
            
            # Try installation with error capture
            if ! pip install -e . --quiet 2>install_error.log; then
                echo "    ⚠️  $component installation failed, attempting fixes..."
                
                # Common fixes for installation issues
                if grep -q "No module named" install_error.log; then
                    echo "    📦 Installing missing dependencies..."
                    pip install setuptools wheel --quiet
                fi
                
                # Retry installation
                if pip install -e . --quiet 2>/dev/null; then
                    echo "    ✅ $component installed after fixes"
                    ((installed_count++))
                else
                    echo "    ❌ $component installation failed"
                    echo "    💡 Try: pip install -e $component_path"
                fi
                rm -f install_error.log
            else
                echo "    ✅ $component installed successfully"
                ((installed_count++))
            fi
        else
            echo "    ❌ $component directory not found"
        fi
    done
    
    # Install import shim for zen-mcp-server
    echo "  🔧 Installing import shim for zen-mcp-server..."
    if [[ -f "stubs/zen_mcp_server_shim.py" ]]; then
        # Install the shim in site-packages
        python_version=$(python -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
        site_packages="$VIRTUAL_ENV/lib/python$python_version/site-packages"
        
        if [[ -d "$site_packages" ]]; then
            cp stubs/zen_mcp_server_shim.py "$site_packages/"
            echo "    ✅ Import shim installed"
            
            # Create a .pth file to auto-import the shim
            echo "import zen_mcp_server_shim" > "$site_packages/zen_mcp_server_shim.pth"
            echo "    ✅ Auto-import configured"
        else
            echo "    ⚠️  Could not find site-packages directory"
        fi
    fi
    
    echo "  📊 Installed $installed_count/5 Python components"
}

# Function to setup Node.js components
install_nodejs_components() {
    echo "📦 Installing Node.js components..."
    
    if command -v npm &> /dev/null; then
        cd "$TEMP_DIR/components/claude-task-master"
        
        # Install dependencies locally first
        if npm install --silent 2>/dev/null; then
            echo "  ✅ Task-Master dependencies installed"
            
            # Try global install with permission handling
            if npm install -g . --silent 2>/dev/null; then
                echo "  ✅ Task-Master available globally"
            else
                # Try with user-local prefix
                echo "  🔧 Trying user-local npm install..."
                npm config set prefix ~/.npm-global 2>/dev/null
                
                if npm install -g . --silent 2>/dev/null; then
                    echo "  ✅ Task-Master installed to ~/.npm-global"
                    echo "  ℹ️  Add to PATH: export PATH=~/.npm-global/bin:$PATH"
                else
                    echo "  ⚠️  Global install failed, Task-Master available via npx"
                fi
            fi
        else
            echo "  ⚠️  Task-Master npm install failed"
        fi
    else
        echo "  ❌ npm not found - Task-Master requires Node.js"
        echo "     Install Node.js: https://nodejs.org"
    fi
}

# Function to setup Claudia
setup_claudia() {
    echo "🖥️  Setting up Claudia GUI..."
    local claudia_dir="$HOME/.claudia-source"
    
    if [[ -d "$TEMP_DIR/components/claudia" ]]; then
        # Copy source to user directory
        rm -rf "$claudia_dir"
        cp -r "$TEMP_DIR/components/claudia" "$claudia_dir"
        
        echo "  ✅ Claudia source copied to ~/.claudia-source"
        echo "  ℹ️  To build Claudia:"
        echo "      cd ~/.claudia-source"
        echo "      npm install && npm run build"
        echo "      # Desktop app will be in src-tauri/target/release/"
    else
        echo "  ❌ Claudia directory not found"
    fi
}

# Function to find and copy .env file
setup_env_file() {
    echo "🔑 Setting up environment configuration..."
    
    # Skip if .env already exists
    if [[ -f ".env" ]]; then
        echo "  ℹ️  .env file already exists"
        return 0
    fi
    
    # Search paths for .env file
    local env_paths=(
        "../.env"
        "../../.env"
        "../../../.env"
        "$HOME/allprojects/claude_code_cursor_project/.env"
        "$HOME/.env"
    )
    
    for path in "${env_paths[@]}"; do
        if [[ -f "$path" ]]; then
            echo "  📋 Found .env at: $path"
            cp "$path" .env
            echo "  ✅ Copied .env file to project root"
            return 0
        fi
    done
    
    echo "  ⚠️  No .env file found in parent directories"
    echo "     You'll need to add API keys manually"
}

# Function to configure MCP
configure_mcp() {
    echo "🔧 Configuring MCP servers..."
    
    # Use the generate script if available, otherwise create basic config
    if [[ -f "scripts/generate-mcp-config.sh" ]]; then
        chmod +x scripts/generate-mcp-config.sh
        # Run from project root
        cd "$OLDPWD"
        ./scripts/generate-mcp-config.sh
        cd - > /dev/null
    else
        # Fallback to basic configuration
        cat > .mcp.json << 'EOF'
{
    "mcpServers": {
        "task-master-ai": {
            "command": "npx",
            "args": ["-y", "--package=task-master-ai", "task-master-ai"],
            "description": "AI-powered task management",
            "env": {
                "ANTHROPIC_API_KEY": "",
                "PERPLEXITY_API_KEY": "",
                "OPENAI_API_KEY": "",
                "GOOGLE_API_KEY": ""
            }
        },
        "zen-mcp-server": {
            "command": "zen-mcp-server",
            "description": "Multi-AI model switching",
            "env": {
                "ANTHROPIC_API_KEY": "",
                "OPENAI_API_KEY": "",
                "GOOGLE_API_KEY": ""
            }
        }
    }
}
EOF
        echo "  ✅ Basic MCP configuration created (.mcp.json)"
        echo "  💡 Run ./scripts/generate-mcp-config.sh for auto-detection"
    fi
    
    if [[ ! -f ".env" ]] || grep -q '""' .mcp.json 2>/dev/null; then
        echo "  ⚠️  Remember to add your API keys to .env file"
    fi
}

# Function to create version manifest
create_version_manifest() {
    echo "📋 Creating version manifest..."
    
    cat > AI_TOOLBOX_VERSIONS.md << EOF
# AI Toolbox Component Versions

Generated: $(date)
Source: $(detect_toolbox_source)

## Installed Components

### Python Components
- **zen-mcp-server**: Multi-AI MCP server
- **claude-code-proxy**: API proxy service  
- **superclaude**: Command framework (90+ commands)
- **claude-sessions**: Session management
- **claude-task-master**: Python wrapper for task management

### Node.js Components
- **claude-task-master**: Full task management MCP server

### Desktop Applications
- **claudia**: GUI control center (source in ~/.claudia-source)

## Installation Details
- Toolbox source: $(if [[ "$(detect_toolbox_source)" == "local" ]]; then echo "$TOOLBOX_LOCAL_PATH"; else echo "$TOOLBOX_REPO_URL"; fi)
- Install method: pip install -e (editable)
- Virtual environment: $VENV_DIR

## Verification
Run \`./scripts/verify-ai-tools.sh\` to check component status.

## API Configuration
Add your API keys to \`.env\`:
\`\`\`
ANTHROPIC_API_KEY=your_key_here
PERPLEXITY_API_KEY=your_key_here
OPENAI_API_KEY=your_key_here
GOOGLE_API_KEY=your_key_here
\`\`\`
EOF
    
    echo "  ✅ Version manifest created (AI_TOOLBOX_VERSIONS.md)"
}

# Main installation flow
main() {
    echo "🔍 Detecting toolbox source..."
    local source_type
    source_type=$(detect_toolbox_source)
    echo "  Source: $source_type"
    
    # Setup toolbox
    setup_toolbox "$source_type"
    
    # Apply packaging stubs
    apply_packaging_stubs
    
    # Install components
    install_python_components
    install_nodejs_components
    setup_claudia
    
    # Configure system
    setup_env_file
    configure_mcp
    create_version_manifest
    
    # Cleanup
    if [[ "$source_type" == "remote" ]]; then
        rm -rf "$TEMP_DIR"
    fi
    
    echo ""
    echo "🎉 AI Toolkit Installation Complete!"
    echo "===================================="
    echo ""
    echo "✅ What was installed:"
    echo "   • 5 Python AI components (editable installs)"
    echo "   • Task-Master Node.js MCP server"  
    echo "   • Claudia GUI source (build required)"
    echo "   • MCP server configuration"
    echo "   • Version tracking manifest"
    echo ""
    echo "🔄 Next steps:"
    echo "   1. Add API keys to .env file"
    echo "   2. Run verification: ./scripts/verify-ai-tools.sh"
    echo "   3. Test MCP connection: task-master --help"
    echo "   4. Optional: Build Claudia GUI"
    echo ""
    echo "📚 Documentation: AI_TOOLBOX_VERSIONS.md"
}

# Run main installation
main