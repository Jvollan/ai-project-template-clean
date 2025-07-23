# {{cookiecutter.project_name}}

{{cookiecutter.project_description}}

**Author**: {{cookiecutter.author_name}}  
**License**: {{cookiecutter.license}}  
**Python**: {{cookiecutter.python_version}}{% if cookiecutter.use_database != "no" %} | **Database**: {{cookiecutter.use_database}}{% endif %}{% if cookiecutter.use_api == "yes" %} | **API**: FastAPI{% endif %}

## 🚀 Quick Start

```bash
# 1. Clone and setup
git clone <your-repo>
cd {{cookiecutter.project_slug}}
chmod +x scripts/bootstrap.sh && ./scripts/bootstrap.sh

# 2. Activate environment  
source venv/bin/activate

# 3. Run application
{% if cookiecutter.use_api == "yes" %}python -m uvicorn src.main:app --reload{% else %}python -m src.main{% endif %}
```

{% if cookiecutter.use_api == "yes" %}
## 📡 API Endpoints

- **Health Check**: `GET /health`
- **API Docs**: http://localhost:8000/docs  
- **API Base**: `GET /api/v1/`

{% endif %}
## 🧪 Development

```bash
# Run tests
pytest

# Code quality
pre-commit run --all-files

# Format code  
black src/ tests/
ruff check src/ tests/ --fix
```

{% if cookiecutter.use_database != "no" %}
## 🗄️ Database

```bash
{% if cookiecutter.use_database == "postgresql" %}
# Start PostgreSQL (example with Docker)
docker run --name postgres -e POSTGRES_PASSWORD=password -p 5432:5432 -d postgres

# Run migrations
python -m alembic upgrade head
{% elif cookiecutter.use_database == "sqlite" %}
# Database file: sqlite:///{{cookiecutter.project_slug}}.db
# Migrations managed with Alembic
python -m alembic upgrade head
{% endif %}
```

{% endif %}
## 📁 Project Structure

```
{{cookiecutter.project_slug}}/
├── src/                    # Application source
│   ├── main.py            # Entry point{% if cookiecutter.use_api == "yes" %}
│   ├── api/               # API routes{% endif %}{% if cookiecutter.use_database != "no" %}
│   ├── models/            # Data models
│   ├── database/          # DB utilities{% endif %}
│   ├── services/          # Business logic
│   └── utils/             # Helper functions
├── tests/                 # Test files
├── scripts/               # Utility scripts
├── .github/workflows/     # CI/CD
└── CLAUDE.md             # AI context
```

## 🤖 AI-First Development

This project includes:
- **Recursive CLAUDE.md files** for AI context in every directory
- **Cursor IDE rules** in `.cursor/rules/` for consistent AI behavior
- **Pre-commit hooks** for automated code quality
- **GitHub Actions** for CI/CD

### Working with Claude/Cursor

1. **Context-aware**: Every directory has a CLAUDE.md file explaining its purpose
2. **Quality-first**: Pre-commit hooks ensure consistent code style
3. **Test-driven**: Pytest runs automatically in CI
4. **MVP-focused**: Prioritizes working code over perfect architecture

## 🛠️ Configuration

Create `.env` file:
```bash
# Application settings
DEBUG=true
LOG_LEVEL=info

{% if cookiecutter.use_database != "no" %}
# Database
DATABASE_URL={{cookiecutter.use_database}}://user:pass@localhost/{{cookiecutter.project_slug}}
{% endif %}

{% if cookiecutter.ai_provider == "claude" or cookiecutter.ai_provider == "multiple" %}
# AI Integration  
ANTHROPIC_API_KEY=your_anthropic_key
{% endif %}{% if cookiecutter.ai_provider == "openai" or cookiecutter.ai_provider == "multiple" %}
OPENAI_API_KEY=your_openai_key
{% endif %}
```

## 📊 CI/CD Pipeline

- **On every push**: Lint, format, test
- **Weekly**: Template self-test to ensure scaffolding works
- **Simple**: Single job, fast feedback

## 🐛 Troubleshooting

```bash
# Reset environment
rm -rf venv && ./scripts/bootstrap.sh

# Fix pre-commit
pre-commit clean && pre-commit install

# Check dependencies
pip list | grep -E "(fastapi|pytest|ruff)"
```

## 📞 Support

- **Issues**: Create GitHub issue
- **Email**: {{cookiecutter.author_email}}
- **Docs**: See `docs/` directory

---

⚡ **MVP Philosophy**: Ship fast, learn faster, iterate constantly.