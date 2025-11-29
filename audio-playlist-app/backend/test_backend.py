"""
Simple test file to verify backend functionality
"""
import requests
import json

def test_extract_endpoint():
    """Test the extract endpoint with a sample URL"""
    url = "http://localhost:8000/extract"
    payload = {
        "url": "https://www.youtube.com/watch?v=9bZkp7q19f0"  # Sample video
    }
    
    try:
        response = requests.post(url, json=payload)
        print(f"Status Code: {response.status_code}")
        print(f"Response: {response.json()}")
    except Exception as e:
        print(f"Error: {e}")

def test_status_endpoint(task_id):
    """Test the status endpoint"""
    url = f"http://localhost:8000/status/{task_id}"
    
    try:
        response = requests.get(url)
        print(f"Status Code: {response.status_code}")
        print(f"Response: {response.json()}")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    print("Testing backend API...")
    test_extract_endpoint()