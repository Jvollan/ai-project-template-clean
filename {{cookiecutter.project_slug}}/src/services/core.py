"""
Core business logic for {{cookiecutter.project_name}}

This module contains the main application logic and services.
Keep business logic separate from API/UI concerns.
"""

import logging
from typing import Dict, Any

logger = logging.getLogger(__name__)

def get_app_info() -> Dict[str, Any]:
    """
    Get basic application information
    
    Returns:
        Dict containing app metadata
    """
    logger.info("Retrieving application information")
    
    return {
        "name": "{{cookiecutter.project_name}}",
        "description": "{{cookiecutter.project_description}}",
        "version": "0.1.0",
        "author": "{{cookiecutter.author_name}}",
        "python_version": "{{cookiecutter.python_version}}",
        {% if cookiecutter.use_database != "no" %}"database": "{{cookiecutter.use_database}}",
        {% endif %}{% if cookiecutter.use_api == "yes" %}"api_enabled": True,
        {% endif %}"mvp_ready": True
    }

# Example service function - replace with your business logic
def process_data(data: Any) -> Dict[str, Any]:
    """
    Process incoming data (placeholder for your logic)
    
    Args:
        data: Input data to process
        
    Returns:
        Processed result
        
    Raises:
        ValueError: If data is invalid
    """
    logger.info(f"Processing data: {type(data)}")
    
    if data is None:
        raise ValueError("Data cannot be None")
    
    # Your business logic here
    result = {
        "input": data,
        "processed": True,
        "timestamp": "2024-01-01T00:00:00Z"  # Use datetime.now() in real code
    }
    
    logger.info("Data processing completed successfully")
    return result