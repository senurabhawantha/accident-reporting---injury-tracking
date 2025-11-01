import tensorflow as tf
from tensorflow import keras
from tensorflow.keras import layers, models
from tensorflow.keras.preprocessing.image import ImageDataGenerator
from tensorflow.keras.applications import MobileNetV2
import numpy as np
from PIL import Image
import cv2
from typing import Dict, Tuple
import os


class WoundClassifier:
    """ML Model for wound severity classification."""
    
    def __init__(self, model_path: str = None):
        """
        Initialize the wound classifier.
        
        Args:
            model_path: Path to saved model. If None, creates a new model.
        """
        self.img_height = 224
        self.img_width = 224
        self.num_classes = 3  # mild, moderate, severe
        self.class_names = ['mild', 'moderate', 'severe']
        
        if model_path and os.path.exists(model_path):
            self.model = keras.models.load_model(model_path)
        else:
            self.model = self._build_model()
    
    def _build_model(self) -> keras.Model:
        """Build a transfer learning model using MobileNetV2."""
        # Load pre-trained MobileNetV2
        base_model = MobileNetV2(
            input_shape=(self.img_height, self.img_width, 3),
            include_top=False,
            weights='imagenet'
        )
        
        # Freeze the base model
        base_model.trainable = False
        
        # Create new model on top
        model = models.Sequential([
            base_model,
            layers.GlobalAveragePooling2D(),
            layers.Dense(128, activation='relu'),
            layers.Dropout(0.5),
            layers.Dense(64, activation='relu'),
            layers.Dropout(0.3),
            layers.Dense(self.num_classes, activation='softmax')
        ])
        
        model.compile(
            optimizer='adam',
            loss='categorical_crossentropy',
            metrics=['accuracy']
        )
        
        return model
    
    def preprocess_image(self, image_bytes: bytes) -> np.ndarray:
        """
        Preprocess image for prediction.
        
        Args:
            image_bytes: Raw image bytes
            
        Returns:
            Preprocessed image array
        """
        # Convert bytes to PIL Image
        image = Image.open(image_bytes).convert('RGB')
        
        # Resize
        image = image.resize((self.img_width, self.img_height))
        
        # Convert to array
        img_array = np.array(image)
        
        # Normalize
        img_array = img_array / 255.0
        
        # Add batch dimension
        img_array = np.expand_dims(img_array, axis=0)
        
        return img_array
    
    def predict(self, image_bytes: bytes) -> Dict[str, any]:
        """
        Predict wound severity.
        
        Args:
            image_bytes: Raw image bytes
            
        Returns:
            Dictionary with prediction results
        """
        # Preprocess image
        processed_image = self.preprocess_image(image_bytes)
        
        # Make prediction
        predictions = self.model.predict(processed_image, verbose=0)
        
        # Get class probabilities
        class_probabilities = {
            self.class_names[i]: float(predictions[0][i])
            for i in range(self.num_classes)
        }
        
        # Get predicted class
        predicted_class_idx = np.argmax(predictions[0])
        predicted_class = self.class_names[predicted_class_idx]
        confidence = float(predictions[0][predicted_class_idx])
        
        return {
            'severity': predicted_class,
            'confidence': confidence,
            'probabilities': class_probabilities
        }
    
    def train(self, train_dir: str, epochs: int = 30, batch_size: int = 32):
        """
        Train the model on wound images.
        
        Args:
            train_dir: Directory containing training data (mild/, moderate/, severe/)
            epochs: Number of training epochs (default: 30)
            batch_size: Batch size for training
        """
        # Data augmentation
        train_datagen = ImageDataGenerator(
            rescale=1./255,
            rotation_range=20,
            width_shift_range=0.2,
            height_shift_range=0.2,
            horizontal_flip=True,
            zoom_range=0.2,
            validation_split=0.2
        )
        
        # Training data
        train_generator = train_datagen.flow_from_directory(
            train_dir,
            target_size=(self.img_height, self.img_width),
            batch_size=batch_size,
            class_mode='categorical',
            subset='training'
        )
        
        # Validation data
        validation_generator = train_datagen.flow_from_directory(
            train_dir,
            target_size=(self.img_height, self.img_width),
            batch_size=batch_size,
            class_mode='categorical',
            subset='validation'
        )
        
        # Callbacks - increased patience for longer training
        callbacks = [
            keras.callbacks.EarlyStopping(
                monitor='val_loss',
                patience=10,  # Increased from 5 to 10 - allows more epochs
                restore_best_weights=True,
                verbose=1
            ),
            keras.callbacks.ReduceLROnPlateau(
                monitor='val_loss',
                factor=0.2,
                patience=5,  # Increased from 3 to 5
                min_lr=1e-7,
                verbose=1
            ),
            keras.callbacks.ModelCheckpoint(
                filepath='./models/checkpoint_epoch_{epoch:02d}_val_acc_{val_accuracy:.2f}.h5',
                monitor='val_accuracy',
                save_best_only=True,
                verbose=1
            )
        ]
        
        # Train
        history = self.model.fit(
            train_generator,
            validation_data=validation_generator,
            epochs=epochs,
            callbacks=callbacks,
            verbose=1
        )
        
        return history
    
    def save_model(self, path: str):
        """Save the model to disk."""
        self.model.save(path)
        print(f"Model saved to {path}")
    
    def get_severity_description(self, severity: str) -> str:
        """Get description for severity level."""
        descriptions = {
            'mild': 'Minor wound with minimal tissue damage. Usually heals quickly with basic first aid.',
            'moderate': 'Moderate wound with noticeable tissue damage. May require medical attention.',
            'severe': 'Severe wound with significant tissue damage. Requires immediate medical attention.'
        }
        return descriptions.get(severity, 'Unknown severity level')
