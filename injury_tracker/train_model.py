"""
Training script for wound severity classifier.
Run this to train the model on your dataset.

Usage:
    python train_model.py                    # Use default 30 epochs
    python train_model.py --epochs 50        # Train for 50 epochs
    python train_model.py --epochs 25 --batch-size 16
"""
import os
import argparse
from ml_model import WoundClassifier


def train_model(epochs: int = 30, batch_size: int = 32):
    """
    Train the wound classifier model.
    
    Args:
        epochs: Number of training epochs
        batch_size: Batch size for training
    """
    
    # Path to training data
    # Expected structure:
    # dataset/
    #   ├── mild/
    #   ├── moderate/
    #   └── severe/
    train_dir = './dataset'
    
    if not os.path.exists(train_dir):
        print(f"Error: Training directory {train_dir} not found!")
        print("Please create the following structure:")
        print("dataset/")
        print("  ├── mild/       (images of mild wounds)")
        print("  ├── moderate/   (images of moderate wounds)")
        print("  └── severe/     (images of severe wounds)")
        return
    
    # Check if subdirectories exist
    required_dirs = ['mild', 'moderate', 'severe']
    for dir_name in required_dirs:
        dir_path = os.path.join(train_dir, dir_name)
        if not os.path.exists(dir_path):
            print(f"Error: {dir_path} directory not found!")
            return
        
        # Count images
        image_count = len([f for f in os.listdir(dir_path) 
                          if f.lower().endswith(('.png', '.jpg', '.jpeg'))])
        print(f"Found {image_count} images in {dir_name} directory")
    
    print("\nInitializing model...")
    classifier = WoundClassifier()
    
    print(f"Starting training with {epochs} epochs and batch size {batch_size}...")
    print("This may take a while depending on your dataset size and hardware.")
    print("Note: Training will stop early if validation loss doesn't improve for 10 epochs.")
    print("-" * 50)
    
    try:
        history = classifier.train(
            train_dir=train_dir,
            epochs=epochs,
            batch_size=batch_size
        )
        
        print("\nTraining completed!")
        print("-" * 50)
        
        # Save the model
        models_dir = './models'
        os.makedirs(models_dir, exist_ok=True)
        model_path = os.path.join(models_dir, 'wound_classifier.h5')
        
        classifier.save_model(model_path)
        
        # Print training summary
        final_accuracy = history.history['accuracy'][-1]
        final_val_accuracy = history.history['val_accuracy'][-1]
        
        print(f"\nFinal Training Accuracy: {final_accuracy:.4f}")
        print(f"Final Validation Accuracy: {final_val_accuracy:.4f}")
        print(f"\nModel saved to: {model_path}")
        
    except Exception as e:
        print(f"Error during training: {str(e)}")
        raise


if __name__ == "__main__":
    # Parse command line arguments
    parser = argparse.ArgumentParser(description='Train wound severity classifier')
    parser.add_argument('--epochs', type=int, default=30,
                       help='Number of training epochs (default: 30)')
    parser.add_argument('--batch-size', type=int, default=32,
                       help='Batch size for training (default: 32)')
    args = parser.parse_args()
    
    print("=" * 50)
    print("Wound Severity Classifier - Training Script")
    print("=" * 50)
    print(f"Configuration:")
    print(f"  - Epochs: {args.epochs}")
    print(f"  - Batch size: {args.batch_size}")
    print(f"  - Early stopping patience: 10 epochs")
    print()
    
    train_model(epochs=args.epochs, batch_size=args.batch_size)
