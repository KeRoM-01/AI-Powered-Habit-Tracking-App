import pandas as pd
import numpy as np

# Habit data from addhabit.dart
habits = [
    {'name': 'Swimming', 'category': 'Health & Fitness'},
    {'name': 'Running', 'category': 'Health & Fitness'},
    {'name': 'Gym', 'category': 'Health & Fitness'},
    {'name': 'Yoga', 'category': 'Health & Fitness'},
    {'name': 'Walking', 'category': 'Health & Fitness'},
    {'name': 'Reading', 'category': 'Personal Growth'},
    {'name': 'Meditation', 'category': 'Personal Growth'},
    {'name': 'Journaling', 'category': 'Personal Growth'},
    {'name': 'Drinking Water', 'category': 'Daily Routine'},
    {'name': 'Brushing Teeth', 'category': 'Daily Routine'},
    {'name': 'Sleeping Early', 'category': 'Daily Routine'},
    {'name': 'Healthy Eating', 'category': 'Daily Routine'},
    {'name': 'Smoking', 'category': 'Unhealthy Lifestyle'},
    {'name': 'Junk Food', 'category': 'Unhealthy Lifestyle'},
    {'name': 'Binge Watching', 'category': 'Unhealthy Lifestyle'},
    {'name': 'Nail Biting', 'category': 'Unhealthy Lifestyle'},
    {'name': 'Overspending', 'category': 'Financial'},
    {'name': 'Delaying Tasks', 'category': 'Procrastination'},
    {'name': 'Excessive Social Media', 'category': 'Digital Addiction'},
    {'name': 'Overthinking', 'category': 'Stress'},
    {'name': 'Late Sleeping', 'category': 'Sleep'},
]

# Categories
categories = list(set(h['category'] for h in habits))
print(f"Categories: {categories}")

# Simulate user data (replace with Firestore export if available)
users = [
    {'id': 'u1', 'selected_categories': ['Health & Fitness', 'Personal Growth']},
    {'id': 'u2', 'selected_categories': ['Daily Routine']},
    {'id': 'u3', 'selected_categories': ['Unhealthy Lifestyle', 'Stress']},
]

# Encode features
def encode_categories(selected, all_categories):
    return [1 if cat in selected else 0 for cat in all_categories]

data = []
for user in users:
    user_vec = encode_categories(user['selected_categories'], categories)
    for habit in habits:
        habit_vec = encode_categories([habit['category']], categories)
        input_vec = user_vec + habit_vec
        label = 1 if habit['category'] in user['selected_categories'] else 0
        data.append({
            'input': input_vec,
            'label': label,
            'habit_name': habit['name'],
            'user_id': user['id']
        })

# Save to CSV
df = pd.DataFrame(data)
df.to_csv('habit_training_data.csv', index=False)
print("Training data saved to habit_training_data.csv")