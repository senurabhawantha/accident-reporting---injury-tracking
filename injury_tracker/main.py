from fastapi import FastAPI, File, UploadFile, HTTPException, Depends, Header
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from typing import Optional, List
import io
import os
from dotenv import load_dotenv

from ml_model import WoundClassifier
from azure_openai_service import FirstAidRecommendation
from encryption import ImageEncryption
from firebase_service import FirebaseService

load_dotenv()

# Initialize FastAPI app
app = FastAPI(
    title="Injury Tracker API",
    description="AI-powered wound severity classification and first aid recommendations",
    version="1.0.0"
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Update with your Flutter app domain in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize services
model_path = os.getenv('MODEL_PATH', './models/wound_classifier.h5')
classifier = WoundClassifier(model_path if os.path.exists(model_path) else None)
first_aid_service = FirstAidRecommendation()
encryption_service = ImageEncryption(os.getenv('ENCRYPTION_KEY'))
firebase_service = FirebaseService()


# Pydantic models
class PredictionResponse(BaseModel):
    """Response model for wound prediction."""
    injury_id: str
    severity: str
    confidence: float
    probabilities: dict
    description: str
    recommendations: dict
    emergency_info: dict
    image_hash: str  # SHA-256 hash for identification


class InjuryRecord(BaseModel):
    """Model for injury record."""
    id: str
    userId: str
    severity: str
    confidence: float
    imageHash: str
    timestamp: str
    status: Optional[str] = "active"


class StatusUpdate(BaseModel):
    """Model for status update."""
    status: str
    notes: Optional[str] = None


# Helper function to verify user
async def get_current_user(authorization: str = Header(None)) -> str:
    """
    Extract user ID from authorization header.
    In production, implement proper JWT verification.
    """
    if not authorization:
        raise HTTPException(status_code=401, detail="Authorization header missing")
    
    # Simple token extraction - implement proper JWT verification in production
    try:
        # Assuming format: "Bearer <user_id>" or "Bearer <jwt_token>"
        user_id = authorization.replace("Bearer ", "")
        if not user_id:
            raise HTTPException(status_code=401, detail="Invalid authorization token")
        return user_id
    except Exception as e:
        raise HTTPException(status_code=401, detail="Invalid authorization token")


# API Endpoints
@app.get("/")
async def root():
    """Health check endpoint."""
    return {
        "status": "healthy",
        "service": "Injury Tracker API",
        "version": "1.0.0"
    }


@app.post("/api/v1/analyze-wound", response_model=PredictionResponse)
async def analyze_wound(
    file: UploadFile = File(...),
    user_id: str = Depends(get_current_user)
):
    """
    Analyze wound image and provide severity classification and first aid recommendations.
    
    Args:
        file: Uploaded wound image
        user_id: User ID from authorization header
        
    Returns:
        Prediction results with recommendations
    """
    try:
        # Validate file type
        if not file.content_type.startswith('image/'):
            raise HTTPException(status_code=400, detail="File must be an image")
        
        # Read image bytes
        image_bytes = await file.read()
        
        if len(image_bytes) == 0:
            raise HTTPException(status_code=400, detail="Empty file")
        
        # Generate hash of image (for identification, not storage)
        image_hash = encryption_service.hash_image(image_bytes)
        
        # Classify wound severity
        image_stream = io.BytesIO(image_bytes)
        prediction = classifier.predict(image_stream)
        
        severity = prediction['severity']
        confidence = prediction['confidence']
        probabilities = prediction['probabilities']
        
        # Get severity description
        description = classifier.get_severity_description(severity)
        
        # Get first aid recommendations from Azure OpenAI
        recommendations = first_aid_service.get_recommendations(
            severity=severity,
            confidence=confidence,
            wound_type="wound"
        )
        
        # Store record in Firestore (only metadata and hash, no image)
        injury_id = firebase_service.store_injury_record(
            user_id=user_id,
            image_hash=image_hash,
            severity=severity,
            confidence=confidence,
            probabilities=probabilities,
            recommendations=recommendations['recommendations'],
            emergency_info=recommendations['emergency_info']
        )
        
        return PredictionResponse(
            injury_id=injury_id,
            severity=severity,
            confidence=confidence,
            probabilities=probabilities,
            description=description,
            recommendations=recommendations['recommendations'],
            emergency_info=recommendations['emergency_info'],
            image_hash=image_hash
        )
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error processing image: {str(e)}")


@app.get("/api/v1/injuries", response_model=List[InjuryRecord])
async def get_user_injuries(
    user_id: str = Depends(get_current_user),
    limit: int = 50
):
    """
    Get all injury records for the current user.
    
    Args:
        user_id: User ID from authorization header
        limit: Maximum number of records to retrieve
        
    Returns:
        List of injury records
    """
    try:
        records = firebase_service.get_injury_records(user_id, limit)
        return records
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error retrieving records: {str(e)}")


@app.get("/api/v1/injuries/{injury_id}")
async def get_injury_details(
    injury_id: str,
    user_id: str = Depends(get_current_user)
):
    """
    Get details of a specific injury record.
    
    Args:
        injury_id: Injury record ID
        user_id: User ID from authorization header
        
    Returns:
        Injury record details
    """
    try:
        record = firebase_service.get_injury_by_id(injury_id)
        
        if not record:
            raise HTTPException(status_code=404, detail="Injury record not found")
        
        # Verify ownership
        if record.get('userId') != user_id:
            raise HTTPException(status_code=403, detail="Access denied")
        
        return record
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error retrieving record: {str(e)}")


@app.put("/api/v1/injuries/{injury_id}/status")
async def update_injury_status(
    injury_id: str,
    status_update: StatusUpdate,
    user_id: str = Depends(get_current_user)
):
    """
    Update the status of an injury record.
    
    Args:
        injury_id: Injury record ID
        status_update: New status and optional notes
        user_id: User ID from authorization header
        
    Returns:
        Success message
    """
    try:
        # Verify ownership
        record = firebase_service.get_injury_by_id(injury_id)
        if not record:
            raise HTTPException(status_code=404, detail="Injury record not found")
        
        if record.get('userId') != user_id:
            raise HTTPException(status_code=403, detail="Access denied")
        
        # Update status
        firebase_service.update_injury_status(
            injury_id,
            status_update.status,
            status_update.notes
        )
        
        return {"message": "Status updated successfully", "injury_id": injury_id}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error updating status: {str(e)}")


@app.delete("/api/v1/injuries/{injury_id}")
async def delete_injury(
    injury_id: str,
    user_id: str = Depends(get_current_user)
):
    """
    Delete an injury record and its associated encrypted image.
    
    Args:
        injury_id: Injury record ID
        user_id: User ID from authorization header
        
    Returns:
        Success message
    """
    try:
        # Verify ownership
        record = firebase_service.get_injury_by_id(injury_id)
        if not record:
            raise HTTPException(status_code=404, detail="Injury record not found")
        
        if record.get('userId') != user_id:
            raise HTTPException(status_code=403, detail="Access denied")
        
        # Delete record and image
        firebase_service.delete_injury_record(
            injury_id,
            record.get('encryptedImagePath')
        )
        
        return {"message": "Injury record deleted successfully", "injury_id": injury_id}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error deleting record: {str(e)}")


@app.get("/api/v1/statistics")
async def get_user_statistics(user_id: str = Depends(get_current_user)):
    """
    Get statistics about user's injury records.
    
    Args:
        user_id: User ID from authorization header
        
    Returns:
        Statistics summary
    """
    try:
        records = firebase_service.get_injury_records(user_id, limit=1000)
        
        total_injuries = len(records)
        severity_counts = {'mild': 0, 'moderate': 0, 'severe': 0}
        
        for record in records:
            severity = record.get('severity', 'unknown')
            if severity in severity_counts:
                severity_counts[severity] += 1
        
        return {
            'total_injuries': total_injuries,
            'severity_breakdown': severity_counts,
            'user_id': user_id
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error retrieving statistics: {str(e)}")


# Run the app
if __name__ == "__main__":
    import uvicorn
    
    host = os.getenv("HOST", "0.0.0.0")
    port = int(os.getenv("PORT", 8000))
    
    uvicorn.run(app, host=host, port=port)
