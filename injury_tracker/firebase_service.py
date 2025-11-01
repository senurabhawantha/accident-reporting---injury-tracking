import firebase_admin
from firebase_admin import credentials, firestore
from datetime import datetime
from typing import Dict, Optional, List
import os
from dotenv import load_dotenv

load_dotenv()


class FirebaseService:
    """Handle Firebase Firestore operations (storing only metadata and hash)."""
    
    def __init__(self):
        """Initialize Firebase Admin SDK."""
        if not firebase_admin._apps:
            cred_path = os.getenv('FIREBASE_CREDENTIALS_PATH')
            self.cred = credentials.Certificate(cred_path)
            firebase_admin.initialize_app(self.cred)
        
        self.db = firestore.client()
    
    def store_injury_record(
        self,
        user_id: str,
        image_hash: str,
        severity: str,
        confidence: float,
        probabilities: Dict,
        recommendations: Dict,
        emergency_info: Dict,
        status: str = 'active'
    ) -> str:
        """
        Store injury tracking record in Firestore (only metadata and hash, no image).
        
        Args:
            user_id: User ID
            image_hash: SHA-256 hash of the image (for identification)
            severity: Wound severity (mild, moderate, severe)
            confidence: Prediction confidence (0-1)
            probabilities: Class probabilities dict
            recommendations: First aid recommendations dict
            emergency_info: Emergency information dict
            status: Status of injury (active, healing, resolved)
            
        Returns:
            Document ID of the stored record
        """
        injury_ref = self.db.collection('injuries').document()
        
        record = {
            'userId': user_id,
            'imageHash': image_hash,  # Only store hash, not the image
            'severity': severity,
            'confidence': confidence,
            'probabilities': probabilities,
            'recommendations': recommendations,
            'emergencyInfo': emergency_info,
            'status': status,
            'timestamp': firestore.SERVER_TIMESTAMP,
            'createdAt': datetime.utcnow().isoformat(),
            'updatedAt': datetime.utcnow().isoformat()
        }
        
        injury_ref.set(record)
        return injury_ref.id
    
    def get_injury_records(
        self,
        user_id: str,
        limit: int = 50
    ) -> list:
        """
        Get injury records for a user.
        
        Args:
            user_id: User ID
            limit: Maximum number of records to retrieve
            
        Returns:
            List of injury records
        """
        records = []
        query = (self.db.collection('injuries')
                .where('userId', '==', user_id)
                .order_by('timestamp', direction=firestore.Query.DESCENDING)
                .limit(limit))
        
        docs = query.stream()
        
        for doc in docs:
            record = doc.to_dict()
            record['id'] = doc.id
            records.append(record)
        
        return records
    
    def get_injury_by_id(self, injury_id: str) -> Optional[Dict]:
        """
        Get a specific injury record by ID.
        
        Args:
            injury_id: Injury document ID
            
        Returns:
            Injury record or None
        """
        doc = self.db.collection('injuries').document(injury_id).get()
        
        if doc.exists:
            record = doc.to_dict()
            record['id'] = doc.id
            return record
        
        return None
    
    def update_injury_status(
        self,
        injury_id: str,
        status: str,
        notes: str = None
    ):
        """
        Update injury record status.
        
        Args:
            injury_id: Injury document ID
            status: New status (e.g., 'active', 'healing', 'resolved')
            notes: Additional notes
        """
        update_data = {
            'status': status,
            'updatedAt': datetime.utcnow().isoformat(),
            'lastUpdated': firestore.SERVER_TIMESTAMP
        }
        
        if notes:
            update_data['notes'] = notes
        
        self.db.collection('injuries').document(injury_id).update(update_data)
    
    def delete_injury_record(self, injury_id: str):
        """
        Delete injury record from Firestore.
        
        Args:
            injury_id: Injury document ID
        """
        self.db.collection('injuries').document(injury_id).delete()
