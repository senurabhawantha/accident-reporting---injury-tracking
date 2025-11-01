"""
Test Firebase connection.
Run this to verify your Firebase credentials are working.
"""
from firebase_service import FirebaseService


def test_firebase():
    """Test Firebase connection."""
    try:
        print("=" * 60)
        print("🔍 Testing Firebase Connection")
        print("=" * 60)
        print()
        print("Initializing Firebase...")
        
        firebase = FirebaseService()
        
        print("✅ Firebase initialized successfully!")
        print()
        print("Project Information:")
        print(f"  - Project ID: {firebase.cred.project_id}")
        print(f"  - Service Account: {firebase.cred.service_account_email}")
        print()
        print("Services initialized:")
        print("  - ✅ Firestore")
        print("  - ✅ Storage")
        print()
        print("=" * 60)
        print("🎉 Firebase is ready to use!")
        print("=" * 60)
        
        return True
        
    except FileNotFoundError as e:
        print("❌ Firebase credentials file not found!")
        print()
        print("Error:", str(e))
        print()
        print("📋 What to do:")
        print("1. Download credentials from Firebase Console:")
        print("   https://console.firebase.google.com/")
        print("   → Project Settings → Service Accounts → Generate new private key")
        print()
        print("2. Save the file as: firebase-credentials.json")
        print("3. Place it in: injury_tracker/")
        print()
        print("For detailed instructions, see: FIREBASE_SETUP.md")
        print("=" * 60)
        return False
        
    except ValueError as e:
        print("❌ Invalid Firebase credentials!")
        print()
        print("Error:", str(e))
        print()
        print("📋 Common causes:")
        print("1. Wrong file format (not a valid service account JSON)")
        print("2. File is corrupted or edited manually")
        print("3. Downloaded wrong type of credentials")
        print()
        print("📋 Solution:")
        print("1. Delete current firebase-credentials.json")
        print("2. Download FRESH credentials from Firebase Console")
        print("3. Save directly without editing")
        print()
        print("For detailed instructions, see: FIREBASE_SETUP.md")
        print("=" * 60)
        return False
        
    except Exception as e:
        print("❌ Firebase connection failed!")
        print()
        print("Error:", str(e))
        print()
        print("For troubleshooting, see: FIREBASE_SETUP.md")
        print("=" * 60)
        return False


if __name__ == "__main__":
    test_firebase()
