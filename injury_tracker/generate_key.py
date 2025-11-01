"""
Generate a valid Fernet encryption key.
Run this once to generate your encryption key.
"""
from cryptography.fernet import Fernet


def generate_encryption_key():
    """Generate a valid Fernet encryption key."""
    key = Fernet.generate_key()
    key_string = key.decode()
    
    print("=" * 60)
    print("🔐 Encryption Key Generated")
    print("=" * 60)
    print()
    print("Your encryption key:")
    print("-" * 60)
    print(key_string)
    print("-" * 60)
    print()
    print("⚠️  IMPORTANT:")
    print("1. Copy this key to your .env file")
    print("2. Replace the ENCRYPTION_KEY value")
    print("3. Keep this key SECRET and SECURE")
    print("4. If you lose this key, encrypted images cannot be decrypted!")
    print()
    print("Example .env entry:")
    print(f"ENCRYPTION_KEY={key_string}")
    print()
    print("=" * 60)
    
    return key_string


if __name__ == "__main__":
    generate_encryption_key()
