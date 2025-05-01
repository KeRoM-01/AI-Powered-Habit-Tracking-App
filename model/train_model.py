import tensorflow as tf
import pandas as pd
import numpy as np

# Load data
data = pd.read_csv('habit_training_data.csv')
X = np.array([eval(x) for x in data['input']])
y = data['label'].values

# Define model with explicit input shape
model = tf.keras.Sequential([
    tf.keras.layers.Input(shape=(18,)),  # 9 user categories + 9 habit categories
    tf.keras.layers.Dense(16, activation='relu'),
    tf.keras.layers.Dense(8, activation='relu'),
    tf.keras.layers.Dense(1, activation='sigmoid')
])

# Compile model
model.compile(optimizer='adam', loss='binary_crossentropy', metrics=['accuracy'])

# Train model
model.fit(X, y, epochs=50, batch_size=8, validation_split=0.2)

# Export to SavedModel format
model.export('habit_recommender')

# Convert to TensorFlow Lite
converter = tf.lite.TFLiteConverter.from_saved_model('habit_recommender')
converter.optimizations = [tf.lite.Optimize.DEFAULT]  # Optional: Enable optimizations
tflite_model = converter.convert()

# Save the .tflite model
with open('habit_recommender.tflite', 'wb') as f:
    f.write(tflite_model)
print("Model saved as habit_recommender.tflite")