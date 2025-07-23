# Source Code - Claude Context

**Purpose**: Main application source code for {{cookiecutter.project_name}}

## Directory Structure
- `main.py` - Application entry point and setup
{% if cookiecutter.use_api == "yes" %}- `api/` - REST API routes and endpoints
{% endif %}{% if cookiecutter.use_database != "no" %}- `models/` - Data models and schemas
- `database/` - Database connection and utilities
{% endif %}- `services/` - Business logic and core functionality  
- `utils/` - Helper functions and utilities

## Development Guidelines

### MVP Principles
- **Keep it simple**: Avoid over-engineering
- **Working over perfect**: Ship functional code
- **Test critical paths**: Focus on user-facing functionality

### Code Organization
```python
# File naming: snake_case
# Class naming: PascalCase  
# Function naming: snake_case
# Constants: UPPER_CASE
```

### Common Patterns
```python
# Error handling
try:
    result = risky_operation()
    return {"success": True, "data": result}
except Exception as e:
    logger.error(f"Operation failed: {e}")
    return {"success": False, "error": str(e)}

# Logging
import logging
logger = logging.getLogger(__name__)
logger.info("Operation completed successfully")
```

## Quick Tasks
- **Add new feature**: Create in `services/`, add tests, update API
- **Fix bug**: Write test to reproduce, fix, verify test passes
- **Add endpoint**: Create in `api/routes.py`, add validation{% if cookiecutter.use_database != "no" %}, update models{% endif %}