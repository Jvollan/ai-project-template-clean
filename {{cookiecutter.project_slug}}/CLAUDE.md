# {{cookiecutter.project_name}} - Claude Context

**Project**: {{cookiecutter.project_description}}  
**Developer**: {{cookiecutter.author_name}}  
**Stack**: Python {{cookiecutter.python_version}}{% if cookiecutter.use_database != "no" %}, {{cookiecutter.use_database}}{% endif %}{% if cookiecutter.use_api == "yes" %}, REST API{% endif %}

## 🎯 MVP Focus

This is an **MVP project** - prioritize working features over perfect architecture.

### Quick Commands
```bash
# Development workflow
source venv/bin/activate     # Activate environment
pytest                       # Run tests
pre-commit run --all-files   # Check code quality
python -m src.main          # Run application
```

{% if cookiecutter.use_database != "no" %}
### Database
- **Type**: {{cookiecutter.use_database}}
- **Migrations**: `python -m alembic upgrade head`
- **Reset**: `python scripts/reset_db.py`
{% endif %}

{% if cookiecutter.use_api == "yes" %}
### API Development
- **Run server**: `python -m uvicorn src.main:app --reload`
- **View docs**: http://localhost:8000/docs
- **Health check**: http://localhost:8000/health
{% endif %}

## 🚀 Development Workflow

### MVP Rule: Ship Fast, Iterate
1. **Build**: Get it working
2. **Test**: Make sure it works  
3. **Ship**: Deploy it
4. **Learn**: Get feedback
5. **Repeat**: Improve incrementally

### Auto-Accept Tasks (Safe for MVP)
- Code formatting and linting fixes
- Adding basic tests for new functions
- Documentation updates
- Dependency updates (minor versions)

### Manual Review Required  
- Database schema changes
- Authentication/security changes
- External API integrations
- Performance optimizations

## 📁 Project Structure
```
src/
├── __init__.py
├── main.py              # Application entry point
{% if cookiecutter.use_api == "yes" %}├── api/                 # API routes
│   ├── __init__.py
│   └── routes.py
{% endif %}{% if cookiecutter.use_database != "no" %}├── models/              # Data models
│   ├── __init__.py
│   └── base.py
├── database/            # Database utilities
│   ├── __init__.py
│   └── connection.py
{% endif %}├── services/            # Business logic
│   ├── __init__.py
│   └── core.py
└── utils/               # Helper functions
    ├── __init__.py
    └── helpers.py

tests/                   # Test files mirror src/
scripts/                 # Utility scripts
docs/                   # Documentation
```

## 🛡️ Quality Gates

### Essential Checks (Automated)
- ✅ **Ruff**: Fast linting
- ✅ **Black**: Code formatting  
- ✅ **Bandit**: Security scanning
- ✅ **Pytest**: Test execution

### MVP Testing Strategy
- **Unit tests**: Core business logic
- **Integration tests**: API endpoints{% if cookiecutter.use_database != "no" %} and database operations{% endif %}
- **Smoke tests**: Critical user journeys

## 🔧 Configuration

### Environment Variables (.env)
```bash
# Application settings
DEBUG=true
LOG_LEVEL=info

{% if cookiecutter.use_database != "no" %}# Database
DATABASE_URL={{cookiecutter.use_database}}://user:pass@localhost/{{cookiecutter.project_slug}}
{% endif %}

{% if cookiecutter.ai_provider == "claude" or cookiecutter.ai_provider == "multiple" %}# AI Integration
ANTHROPIC_API_KEY=your_key_here
{% endif %}{% if cookiecutter.ai_provider == "openai" or cookiecutter.ai_provider == "multiple" %}OPENAI_API_KEY=your_key_here
{% endif %}```

## 🚨 Common Issues & Solutions

### Setup Problems
```bash
# Environment issues
rm -rf venv && python{{cookiecutter.python_version}} -m venv venv
source venv/bin/activate && pip install -r requirements.txt

# Permission issues  
chmod +x scripts/bootstrap.sh

# Pre-commit issues
pre-commit clean && pre-commit install
```

{% if cookiecutter.use_database != "no" %}
### Database Issues
```bash
# Connection problems
python -c "from src.database.connection import test_connection; test_connection()"

# Migration issues
python -m alembic downgrade -1 && python -m alembic upgrade head
```
{% endif %}

## 📞 MVP Development Support

**Questions**: {{cookiecutter.author_email}}  
**Documentation**: See `docs/` directory  
**Architecture**: Keep it simple - this is an MVP!

---

*This project uses AI-first development practices. Every directory has a CLAUDE.md file for context.*