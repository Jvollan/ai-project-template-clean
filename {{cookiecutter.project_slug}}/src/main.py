"""
{{cookiecutter.project_name}} - Main Application Entry Point

A minimal MVP application with AI-first development practices.
"""

import logging
{% if cookiecutter.use_api == "yes" %}from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
{% endif %}

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

{% if cookiecutter.use_api == "yes" %}
# Create FastAPI app
app = FastAPI(
    title="{{cookiecutter.project_name}}",
    description="{{cookiecutter.project_description}}",
    version="0.1.0"
)

# Add CORS middleware for development
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure properly for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
async def root():
    """Root endpoint - health check"""
    return {"message": "{{cookiecutter.project_name}} is running!", "status": "healthy"}

@app.get("/health")
async def health_check():
    """Health check endpoint for monitoring"""
    return {"status": "healthy", "service": "{{cookiecutter.project_name}}"}

# Import routes
try:
    from src.api.routes import router
    app.include_router(router, prefix="/api/v1")
    logger.info("API routes loaded successfully")
except ImportError:
    logger.warning("API routes not found - create src/api/routes.py")

if __name__ == "__main__":
    import uvicorn
    logger.info("Starting {{cookiecutter.project_name}} server...")
    uvicorn.run(app, host="0.0.0.0", port=8000)

{% else %}
def main():
    """Main application function"""
    logger.info("Starting {{cookiecutter.project_name}}...")
    
    # Your application logic here
    print("🚀 {{cookiecutter.project_name}} is running!")
    print("📖 Description: {{cookiecutter.project_description}}")
    
    # Example: Load and process data
    from src.services.core import get_app_info
    info = get_app_info()
    print(f"📊 App info: {info}")
    
    logger.info("Application completed successfully")

if __name__ == "__main__":
    main()
{% endif %}