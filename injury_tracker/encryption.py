import os
from cryptography.fernet import Fernet
import hashlib
from typing import Tuple


class ImageEncryption:
    """Handle image encryption and hashing for privacy."""
    
    def __init__(self, encryption_key: str = None):
        """
        Initialize encryption handler.
        
        Args:
            encryption_key: Base64 encoded encryption key. If None, generates a new one.
        """
        if encryption_key:
            self.key = encryption_key.encode()
        else:
            self.key = Fernet.generate_key()
        
        self.cipher = Fernet(self.key)
    
    @staticmethod
    def generate_key() -> str:
        """Generate a new encryption key."""
        return Fernet.generate_key().decode()
    
    def encrypt_image(self, image_bytes: bytes) -> bytes:
        """
        Encrypt image bytes.
        
        Args:
            image_bytes: Raw image bytes
            
        Returns:
            Encrypted image bytes
        """
        return self.cipher.encrypt(image_bytes)
    
    def decrypt_image(self, encrypted_bytes: bytes) -> bytes:
        """
        Decrypt image bytes.
        
        Args:
            encrypted_bytes: Encrypted image bytes
            
        Returns:
            Decrypted image bytes
        """
        return self.cipher.decrypt(encrypted_bytes)
    
    @staticmethod
    def hash_image(image_bytes: bytes) -> str:
        """
        Create SHA-256 hash of image for identification.
        
        Args:
            image_bytes: Raw image bytes
            
        Returns:
            Hexadecimal hash string
        """
        return hashlib.sha256(image_bytes).hexdigest()
    
    @staticmethod
    def create_secure_filename(original_filename: str, image_hash: str) -> str:
        """
        Create a secure filename using hash.
        
        Args:
            original_filename: Original filename
            image_hash: Hash of the image
            
        Returns:
            Secure filename
        """
        extension = os.path.splitext(original_filename)[1]
        return f"{image_hash}{extension}"
    
    def encrypt_and_hash(self, image_bytes: bytes, filename: str) -> Tuple[bytes, str, str]:
        """
        Encrypt image and generate hash.
        
        Args:
            image_bytes: Raw image bytes
            filename: Original filename
            
        Returns:
            Tuple of (encrypted_bytes, image_hash, secure_filename)
        """
        # Generate hash
        image_hash = self.hash_image(image_bytes)
        
        # Create secure filename
        secure_filename = self.create_secure_filename(filename, image_hash)
        
        # Encrypt image
        encrypted_bytes = self.encrypt_image(image_bytes)
        
        return encrypted_bytes, image_hash, secure_filename
