# 🚑 ClaimMate App

ClaimMate is a mobile and AI-powered system that helps users report vehicle accidents, detect injury severity, and get instant first-aid advice.

---

## 🧭 Overview

- Users can **log in or register** using Firebase.
- **Add vehicle information** and report an accident easily.
- Upload an **injury photo** for AI-based wound classification.
- Get **first-aid recommendations** instantly using Azure OpenAI.
- All data is **stored securely** in Firebase with encryption and hashing.

---

## ⚙️ Technologies Used

**Frontend**
- Flutter (Dart)
- Firebase Auth, Firestore, Storage

**Backend**
- FastAPI (Python)
- TensorFlow + Keras (MobileNetV2)
- Azure OpenAI API
- Firebase Admin SDK

**Security**
- SHA-256 hashing
- Fernet encryption

---

## 🧩 Project Structure

```
ClaimMateApp/
├── cm/                   # Flutter mobile app
│   └── lib/              # UI pages, components, services
└── injury_tracker/       # Backend (FastAPI + ML)
    ├── main.py           # FastAPI app
    ├── ml_model.py       # ML model loader
    ├── encryption.py     # Image hashing & encryption
    ├── firebase_service.py # Firebase Admin SDK
    └── azure_openai_service.py # First aid generation
```

---

## 🚀 How to Run

### 1. Flutter App
```bash
cd ClaimMateApp/cm
flutter pub get
flutter run
```

### 2. Backend Server
```bash
cd ClaimMateApp/injury_tracker
pip install -r requirements.txt
uvicorn main:app --reload
```

Then open **http://127.0.0.1:8000/docs** to test the API.

---

## 👨‍💻 Developer
**R.L.A. Senura Bhawantha**  
National Institute of Business Management (NIBM)  
Coventry University Collaboration  
📧 senurabawantha@gmail.com

---

### 🪪 License
This project is for **educational purposes** only.
