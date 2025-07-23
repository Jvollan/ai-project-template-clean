"""
Tests for core business logic

MVP testing strategy: Focus on critical user journeys and business logic.
Keep tests simple and fast.
"""

import pytest
from src.services.core import get_app_info, process_data

def test_get_app_info():
    """Test application info retrieval"""
    info = get_app_info()
    
    # Basic structure validation
    assert isinstance(info, dict)
    assert "name" in info
    assert "version" in info
    assert info["name"] == "{{cookiecutter.project_name}}"
    assert info["mvp_ready"] is True

def test_process_data_success():
    """Test successful data processing"""
    test_data = {"key": "value", "number": 42}
    result = process_data(test_data)
    
    assert isinstance(result, dict)
    assert result["processed"] is True
    assert result["input"] == test_data

def test_process_data_with_none():
    """Test data processing with None input"""
    with pytest.raises(ValueError, match="Data cannot be None"):
        process_data(None)

def test_process_data_with_string():
    """Test data processing with string input"""
    result = process_data("test string")
    
    assert result["processed"] is True
    assert result["input"] == "test string"

def test_process_data_with_list():
    """Test data processing with list input"""
    test_list = [1, 2, 3, "test"]
    result = process_data(test_list)
    
    assert result["processed"] is True
    assert result["input"] == test_list

# Example of parameterized test for multiple inputs
@pytest.mark.parametrize("input_data,expected_processed", [
    ("string", True),
    (123, True),
    ([1, 2, 3], True),
    ({"key": "value"}, True),
])
def test_process_data_various_inputs(input_data, expected_processed):
    """Test data processing with various input types"""
    result = process_data(input_data)
    assert result["processed"] == expected_processed