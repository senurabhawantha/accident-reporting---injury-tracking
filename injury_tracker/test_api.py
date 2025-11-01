"""
Simple test script to verify the API is working.
"""
import requests
import os

# Configuration
API_URL = "http://localhost:8000"
TEST_IMAGE_PATH = "./test_wound.jpg"  # Replace with actual test image
USER_ID = "test_user_123"


def test_health_check():
    """Test health check endpoint."""
    print("Testing health check...")
    response = requests.get(f"{API_URL}/")
    print(f"Status: {response.status_code}")
    print(f"Response: {response.json()}")
    print("-" * 50)


def test_analyze_wound():
    """Test wound analysis endpoint."""
    if not os.path.exists(TEST_IMAGE_PATH):
        print(f"Test image not found: {TEST_IMAGE_PATH}")
        print("Please add a test image and update TEST_IMAGE_PATH")
        return
    
    print("Testing wound analysis...")
    
    with open(TEST_IMAGE_PATH, 'rb') as f:
        files = {'file': f}
        headers = {'Authorization': f'Bearer {USER_ID}'}
        
        response = requests.post(
            f"{API_URL}/api/v1/analyze-wound",
            files=files,
            headers=headers
        )
    
    print(f"Status: {response.status_code}")
    
    if response.status_code == 200:
        result = response.json()
        print(f"Injury ID: {result['injury_id']}")
        print(f"Severity: {result['severity']}")
        print(f"Confidence: {result['confidence']:.2%}")
        print(f"Description: {result['description']}")
        print("\nFirst Aid Steps:")
        for i, step in enumerate(result['recommendations']['first_aid_steps'][:5], 1):
            print(f"  {i}. {step}")
    else:
        print(f"Error: {response.text}")
    
    print("-" * 50)


def test_get_injuries():
    """Test getting user injuries."""
    print("Testing get injuries...")
    
    headers = {'Authorization': f'Bearer {USER_ID}'}
    response = requests.get(
        f"{API_URL}/api/v1/injuries",
        headers=headers
    )
    
    print(f"Status: {response.status_code}")
    
    if response.status_code == 200:
        injuries = response.json()
        print(f"Found {len(injuries)} injury records")
        for injury in injuries[:3]:  # Show first 3
            print(f"  - {injury.get('id')}: {injury.get('severity')} (confidence: {injury.get('confidence'):.2%})")
    else:
        print(f"Error: {response.text}")
    
    print("-" * 50)


def test_statistics():
    """Test statistics endpoint."""
    print("Testing statistics...")
    
    headers = {'Authorization': f'Bearer {USER_ID}'}
    response = requests.get(
        f"{API_URL}/api/v1/statistics",
        headers=headers
    )
    
    print(f"Status: {response.status_code}")
    
    if response.status_code == 200:
        stats = response.json()
        print(f"Total injuries: {stats['total_injuries']}")
        print("Severity breakdown:")
        for severity, count in stats['severity_breakdown'].items():
            print(f"  {severity}: {count}")
    else:
        print(f"Error: {response.text}")
    
    print("-" * 50)


if __name__ == "__main__":
    print("=" * 50)
    print("Injury Tracker API - Test Suite")
    print("=" * 50)
    print()
    
    try:
        test_health_check()
        # test_analyze_wound()  # Uncomment when you have a test image
        # test_get_injuries()
        # test_statistics()
    except requests.exceptions.ConnectionError:
        print("Error: Could not connect to API")
        print("Make sure the API is running: python main.py")
    except Exception as e:
        print(f"Error: {str(e)}")
