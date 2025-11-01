# Injury Tracker Backend

AI-powered wound severity classification system with Azure OpenAI integration for first aid recommendations.

## Features

- 🤖 ML-based wound severity classification (mild, moderate, severe)
- 🔐 Image encryption for privacy and security
- 🔥 Firebase Firestore & Storage integration
- 🏥 Azure OpenAI-powered first aid recommendations
- 📊 User injury history tracking
- 🔒 Secure API with authentication
- 📱 Flutter-ready REST API

## Architecture

```
┌─────────────────┐
│  Flutter App    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   FastAPI       │
│   Backend       │
└────────┬────────┘
         │
    ┌────┴──────┬──────────┬──────────────┐
    ▼           ▼          ▼              ▼
┌────────┐  ┌────────┐ ┌─────────┐  ┌──────────┐
│   ML   │  │Firebase│ │  Azure  │  │Encryption│
│ Model  │  │        │ │ OpenAI  │  │ Service  │
└────────┘  └────────┘ └─────────┘  └──────────┘
```

## Prerequisites

- Python 3.8+
- Firebase project with Firestore and Storage enabled
- Azure OpenAI API access
- TensorFlow 2.15+

## Installation

1. **Clone the repository**
   ```bash
   cd injury_tracker
   ```

2. **Create virtual environment**
   ```bash
   python -m venv venv
   
   # On Windows
   venv\Scripts\activate
   
   # On macOS/Linux
   source venv/bin/activate
   ```

3. **Install dependencies**
   ```bash
   pip install -r requirements.txt
   ```

4. **Set up environment variables**
   ```bash
   cp .env.example .env
   ```
   
   Edit `.env` and add your credentials:
   - Azure OpenAI API key, endpoint, and deployment name
   - Firebase credentials path
   - Encryption key (generate using `python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"`)

5. **Add Firebase credentials**
   - Download your Firebase Admin SDK credentials JSON file
   - Save it as `firebase-credentials.json` in the project root
   - Update the storage bucket in `firebase_service.py`

## Dataset Preparation

Organize your wound images in the following structure:

```
dataset/
├── mild/
│   ├── image1.jpg
│   ├── image2.jpg
│   └── ...
├── moderate/
│   ├── image1.jpg
│   ├── image2.jpg
│   └── ...
└── severe/
    ├── image1.jpg
    ├── image2.jpg
    └── ...
```

## Training the Model

Train the wound classifier on your dataset:

```bash
python train_model.py
```

This will:
- Load and preprocess images
- Train a MobileNetV2-based transfer learning model
- Save the trained model to `models/wound_classifier.h5`

## Running the API

Start the FastAPI server:

```bash
python main.py
```

Or using uvicorn directly:

```bash
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

API will be available at: `http://localhost:8000`

API documentation: `http://localhost:8000/docs`

## API Endpoints

### 1. Health Check
```http
GET /
```

### 2. Analyze Wound
```http
POST /api/v1/analyze-wound
Authorization: Bearer <user_id>
Content-Type: multipart/form-data

Body: file (image file)
```

Response:
```json
{
  "injury_id": "abc123",
  "severity": "moderate",
  "confidence": 0.92,
  "probabilities": {
    "mild": 0.05,
    "moderate": 0.92,
    "severe": 0.03
  },
  "description": "Moderate wound with noticeable tissue damage...",
  "recommendations": {
    "immediate_actions": "Apply pressure to stop bleeding...",
    "first_aid_steps": ["Step 1", "Step 2", ...],
    "things_to_avoid": ["Don't...", ...],
    "warning_signs": ["Sign 1", ...],
    "when_to_seek_help": "Seek medical attention if...",
    "healing_time": "1-3 weeks"
  },
  "emergency_info": {
    "urgency": "medium",
    "call_emergency": false,
    "message": "Consider visiting a doctor..."
  },
  "image_hash": "sha256_hash",
  "encrypted_image_path": "injuries/user123/image.jpg.enc"
}
```

### 3. Get User Injuries
```http
GET /api/v1/injuries?limit=50
Authorization: Bearer <user_id>
```

### 4. Get Injury Details
```http
GET /api/v1/injuries/{injury_id}
Authorization: Bearer <user_id>
```

### 5. Update Injury Status
```http
PUT /api/v1/injuries/{injury_id}/status
Authorization: Bearer <user_id>
Content-Type: application/json

{
  "status": "healing",
  "notes": "Wound is healing well"
}
```

### 6. Delete Injury
```http
DELETE /api/v1/injuries/{injury_id}
Authorization: Bearer <user_id>
```

### 7. Get Statistics
```http
GET /api/v1/statistics
Authorization: Bearer <user_id>
```

## Security Features

### Image Encryption
All wound images are encrypted before storage using Fernet (symmetric encryption):
- Images are encrypted with AES-128
- Each image has a unique SHA-256 hash for identification
- Original images are never stored

### Authentication
- Bearer token authentication (implement JWT in production)
- User isolation - users can only access their own records
- Firebase Security Rules should be configured

## Flutter Integration

### Add dependencies to `pubspec.yaml`:
```yaml
dependencies:
  http: ^1.1.0
  image_picker: ^1.0.4
  shared_preferences: ^2.2.2
```

### Example Flutter code:
```dart
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<Map<String, dynamic>> analyzeWound(File imageFile, String userId) async {
  final url = Uri.parse('http://your-api-url/api/v1/analyze-wound');
  
  var request = http.MultipartRequest('POST', url);
  request.headers['Authorization'] = 'Bearer $userId';
  request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));
  
  var response = await request.send();
  var responseData = await response.stream.bytesToString();
  
  return json.decode(responseData);
}
```

## Production Deployment

### Recommended Services:
- **API Hosting**: AWS EC2, Google Cloud Run, Azure App Service
- **Model Hosting**: Use TensorFlow Serving or convert to TFLite
- **SSL/TLS**: Use Let's Encrypt or cloud provider certificates
- **Monitoring**: Add logging, metrics, and error tracking

### Security Checklist:
- [ ] Implement proper JWT authentication
- [ ] Use HTTPS only
- [ ] Configure Firebase Security Rules
- [ ] Set up API rate limiting
- [ ] Enable CORS for specific domains only
- [ ] Add input validation and sanitization
- [ ] Implement proper error handling
- [ ] Use environment-specific configurations
- [ ] Regular security audits

## Model Performance

The model uses transfer learning with MobileNetV2:
- **Input Size**: 224x224 pixels
- **Classes**: 3 (mild, moderate, severe)
- **Architecture**: MobileNetV2 + Custom layers
- **Training**: Early stopping + Learning rate reduction

### Improving Accuracy:
1. Collect more diverse training data
2. Balance dataset across classes
3. Augment data (rotation, flip, zoom)
4. Fine-tune hyperparameters
5. Try different base models (ResNet, EfficientNet)

## Troubleshooting

### Common Issues:

1. **Firebase credentials error**
   - Ensure `firebase-credentials.json` exists
   - Check file path in `.env`
   - Verify Firebase project settings

2. **Azure OpenAI API errors**
   - Verify API key and endpoint
   - Check deployment name
   - Ensure quota is not exceeded

3. **Model not found**
   - Run `train_model.py` first
   - Check `MODEL_PATH` in `.env`

4. **Out of memory errors**
   - Reduce batch size in training
   - Use smaller images
   - Reduce model complexity

## License

MIT License - See LICENSE file for details

## Support

For issues and questions, please open an issue on GitHub.
