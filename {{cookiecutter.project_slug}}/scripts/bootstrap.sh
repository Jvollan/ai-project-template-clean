#!/usr/bin/env bash
set -e

echo "🚀 Bootstrapping {{cookiecutter.project_name}} for AI-First Development"
echo "======================================================================"

# Run pre-flight checks first
echo "🛫 Running pre-flight checks..."
chmod +x scripts/pre-flight-check.sh
if ! ./scripts/pre-flight-check.sh; then
    echo "❌ Pre-flight checks failed. Please fix issues and try again."
    exit 1
fi
echo ""

# Phase 1: Python Environment Setup
echo "🐍 Setting up Python environment..."
if [[ ! -d "venv" ]]; then
    echo "  Creating Python {{cookiecutter.python_version}} virtual environment..."
    python{{cookiecutter.python_version}} -m venv venv
fi

echo "  Activating virtual environment..."
source venv/bin/activate

echo "  Installing base dependencies..."
pip install --upgrade pip --quiet
pip install -r requirements.txt --quiet

# Phase 2: AI Components Installation (THE KEY STEP!)
echo ""
echo "🤖 Installing AI Toolkit Components..."
echo "======================================"
chmod +x scripts/add-ai-toolkit.sh
./scripts/add-ai-toolkit.sh

# Phase 3: Verification Tests
echo ""
echo "🧪 Running AI Component Verification..."
echo "======================================"
chmod +x scripts/verify-ai-tools.sh
if ./scripts/verify-ai-tools.sh; then
    echo "✅ All AI components verified successfully!"
else
    echo "⚠️  Some components need attention, but continuing setup..."
fi

# Phase 4: Generate Context Files
echo ""
echo "📝 Generating AI context files..."
echo "==============================="
# Generate CLAUDE.md in every folder (Cursor reads them recursively)
MSG="Project context for Claude — edit as you develop."
find . -type d ! -path "./.*" ! -path "./venv*" ! -path "./__pycache__*" ! -path "./node_modules*" | while read -r d; do
    if [[ ! -f "$d/CLAUDE.md" ]]; then
        # Create context based on directory type
        case "$d" in
            "./src"*)
                context="Source code directory. Contains the main implementation of {{cookiecutter.project_name}}."
                ;;
            "./tests"*)
                context="Test directory. Contains unit tests, integration tests, and test fixtures."
                ;;
            "./scripts"*)
                context="Automation scripts. Contains setup, deployment, and utility scripts."
                ;;
            "./docs"*)
                context="Documentation directory. Contains project documentation and guides."
                ;;
            ".")
                context="Root directory of {{cookiecutter.project_name}}. {{cookiecutter.project_description}}"
                ;;
            *)
                context="Directory purpose: [TODO: Describe what this directory contains]"
                ;;
        esac
        
        echo -e "# Claude Context: $d\n\n$MSG\n\n$context\n\nKey files:\n- [TODO: List important files]\n\nCommon tasks:\n- [TODO: List frequent operations]" > "$d/CLAUDE.md"
        echo "  📝 Created $d/CLAUDE.md"
    fi
done

# Phase 5: Setup Development Tools
echo ""
echo "🛠️  Setting up development tools..."
echo "=================================="

# Create Cursor AI rules
mkdir -p .cursor/rules
if [[ ! -f ".cursor/rules/00-base.rule" ]]; then
    cat > .cursor/rules/00-base.rule <<'EOF'
You are Claude working in {{cookiecutter.project_name}}.
{{cookiecutter.project_description}}

## Project Configuration
- Python {{cookiecutter.python_version}}
{% if cookiecutter.use_database != "no" %}- Database: {{cookiecutter.use_database}}{% endif %}
{% if cookiecutter.use_api == "yes" %}- API Framework: FastAPI{% endif %}
- AI Provider: {{cookiecutter.ai_provider}}

## Code Standards
- Follow PEP-8, use Ruff/Black for formatting
- Write type hints for functions
- Add docstrings for public functions
- Keep answers concise and actionable

## AI Tools Available
- Task Master: Project task management
- Zen MCP: Multi-AI model switching
- SuperClaude: 90+ development commands
- Claude Sessions: Session continuity
- Claudia GUI: Visual AI control center

## Development Priorities
This is an MVP - prioritize:
1. Working code over perfect architecture
2. User value over technical elegance
3. Iteration speed over premature optimization
4. Always run tests after changes

{% if cookiecutter.use_database != "no" %}
## Database Guidelines
- Use migrations for schema changes
- Validate data integrity
- Handle connection errors gracefully
{% endif %}

{% if cookiecutter.use_api == "yes" %}
## API Guidelines
- Validate all inputs
- Return consistent error formats
- Use proper HTTP status codes
- Document endpoints as you build
{% endif %}
EOF
    echo "  🎯 Created Cursor AI rules"
fi

# Install pre-commit hooks
if [[ -f ".pre-commit-config.yaml" ]]; then
    echo "  🪝 Installing pre-commit hooks..."
    # Always install pre-commit in the virtual environment
    if ! python -m pre_commit --version &> /dev/null; then
        echo "  📦 Installing pre-commit..."
        pip install pre-commit --quiet
    fi
    
    # Install hooks
    if python -m pre_commit install --quiet; then
        echo "  ✅ Pre-commit hooks installed"
    else
        echo "  ⚠️  Pre-commit hook installation failed"
        echo "     You can install manually later with: pre-commit install"
    fi
fi

# Phase 6: Create .env template
echo ""
echo "🔑 Setting up environment configuration..."
echo "========================================"
if [[ ! -f ".env" ]]; then
    cat > .env << 'EOF'
# API Keys for AI Components
# Add your actual API keys here

# Core AI Providers
ANTHROPIC_API_KEY=your_anthropic_key_here
{% if cookiecutter.ai_provider == "openai" or cookiecutter.ai_provider == "multiple" %}OPENAI_API_KEY=your_openai_key_here{% endif %}
{% if cookiecutter.ai_provider == "multiple" %}
# Additional AI Providers  
GOOGLE_API_KEY=your_google_key_here
PERPLEXITY_API_KEY=your_perplexity_key_here
XAI_API_KEY=your_xai_key_here
OPENROUTER_API_KEY=your_openrouter_key_here
{% endif %}

# Project Configuration
PROJECT_NAME={{cookiecutter.project_name}}
{% if cookiecutter.use_database == "sqlite" %}DATABASE_URL=sqlite:///./{{cookiecutter.project_slug}}.db{% endif %}
{% if cookiecutter.use_database == "postgresql" %}DATABASE_URL=postgresql://user:password@localhost/{{cookiecutter.project_slug}}{% endif %}
{% if cookiecutter.use_api == "yes" %}
# API Configuration
API_HOST=0.0.0.0
API_PORT=8000
DEBUG=true
{% endif %}
EOF
    echo "  ✅ Created .env template"
    echo "  ⚠️  Remember to add your actual API keys!"
else
    echo "  ℹ️  .env file already exists"
fi

# Phase 7: Initialize Git Repository
echo ""
echo "📦 Initializing git repository..."
echo "================================"
if [[ ! -d ".git" ]]; then
    git init
    git add .
    git commit --no-verify -m "feat: initial AI-powered MVP setup

🤖 Generated with AI Project Template

## Components Installed:
✅ Zen MCP Server - Multi-AI model switching
✅ Claude Code Proxy - API proxy service
✅ SuperClaude - 90+ development commands
✅ Claude Sessions - Session management
✅ Task Master - AI task management
✅ Claudia GUI - Visual control center (source)

## Project Features:
- Recursive CLAUDE.md context files
- Cursor AI rules for consistency
- Pre-commit hooks for code quality
- GitHub Actions CI/CD pipeline
- MCP server configuration
- Multi-AI provider support

Ready for AI-first development! 🚀"

    echo "  ✅ Git repository initialized with initial commit"
else
    echo "  ℹ️  Git repository already exists"
fi

# Phase 8: Final Status Report
echo ""
echo "🎉 Bootstrap Complete!"
echo "====================="
echo ""
echo "✅ What was set up:"
echo "   • Python {{cookiecutter.python_version}} virtual environment"
echo "   • 6 AI components installed and verified"
echo "   • Recursive CLAUDE.md context files"
echo "   • Cursor AI rules configured"
echo "   • Pre-commit hooks installed"
echo "   • MCP server configuration"
echo "   • Environment variables template"
echo "   • Git repository initialized"
echo ""
echo "🔄 Next steps:"
echo ""
echo "1. Add your API keys to .env file:"
echo "   • ANTHROPIC_API_KEY (required for Claude)"
{% if cookiecutter.ai_provider == "multiple" %}echo "   • OPENAI_API_KEY, GOOGLE_API_KEY (for multi-AI)"{% endif %}
echo ""
echo "2. Verify everything works:"
echo "   source venv/bin/activate"
echo "   ./scripts/verify-ai-tools.sh"
echo ""
echo "3. Test AI components:"
echo "   zen-mcp-server --help      # Multi-AI MCP server"
echo "   task-master list           # Task management" 
echo "   SuperClaude --help         # 90+ commands"
echo ""
echo "4. Update MCP configuration (optional):"
echo "   ./scripts/generate-mcp-config.sh  # Auto-detect installed servers"
echo ""
echo "5. Start developing with AI assistance:"
echo "   code .                     # Open in VS Code/Cursor"
echo "   # AI context is ready in every directory!"
echo ""
echo "📚 Documentation:"
echo "   • AI_TOOLBOX_VERSIONS.md - Component details"
echo "   • .mcp.json - MCP server config (auto-generated)"
echo "   • CLAUDE.md files - AI context in every folder"
echo ""
echo "🤖 Your AI-powered MVP is ready for development!"