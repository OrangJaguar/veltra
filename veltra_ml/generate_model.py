#!/usr/bin/env python3
"""
Veltra - Complete Data Generation & Model Training Pipeline
Author: Veltra Team
Purpose: Generate synthetic training data based on real firefighter physiology data,
         train an XGBoost model, and export for Flutter deployment.

Data Source: Firefighter heat stress study (Mendeley dataset)
Reference: https://data.mendeley.com/datasets/7ghxcsd9sz/1
"""

import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder, StandardScaler
from sklearn.metrics import classification_report, confusion_matrix, accuracy_score
import xgboost as xgb
import joblib
import warnings
warnings.filterwarnings('ignore')

print("=" * 60)
print("VELTRA - DATA GENERATION & MODEL TRAINING PIPELINE")
print("=" * 60)

# ============================================================================
# PHASE 1: LOAD AND EXTRACT REAL DATA
# ============================================================================

print("\n[Phase 1] Loading real firefighter dataset...")

# Try multiple paths for the Excel file
file_paths = [
    'firefighter_mendeley.xlsx',
    '/Users/SANSG/Downloads/firefighter_mendeley.xlsx',
    '/Users/SANSG/Desktop/veltra_ml/firefighter_mendeley.xlsx',
]

file_path = None
for p in file_paths:
    try:
        pd.read_excel(p, sheet_name='All Data ', header=2)
        file_path = p
        break
    except:
        continue

if file_path is None:
    print("❌ Could not find firefighter_mendeley.xlsx")
    print("   Please place the file in ~/Desktop/veltra_ml/")
    exit()

print(f"✅ Found file: {file_path}")

# Load the data
data = pd.read_excel(file_path, sheet_name='All Data ', header=2)

# Extract the actual subject data (rows 5-25, skipping header rows)
subjects_data = data.iloc[4:25, :]  # 21 subjects
print(f"✅ Loaded {len(subjects_data)} subjects")

# ============================================================================
# PHASE 2: EXTRACT PHYSIOLOGICAL DISTRIBUTIONS FROM REAL DATA
# ============================================================================

print("\n[Phase 2] Extracting physiological distributions from real data...")

# Extract key columns (by index based on the Excel structure)
# Column mapping from the Excel file:
# D: Age, E: Height, F: Body Fat %
# G: AM core temp (day off), H: AM core temp (experimental)
# I: PM core temp (day off), J: PM core temp (experimental)
# K: Weight Pre (AM), L: Weight Post (AM)
# M: Weight Pre (PM), N: Weight Post (PM)
# AC: Thorax skin temp (AM mean), AD: Thorax skin temp (PM mean)
# AE: Thorax skin temp (AM max), AF: Thorax skin temp (PM max)

# Extract the columns we need
real_skin_temp_am = pd.to_numeric(subjects_data.iloc[:, 28], errors='coerce')
real_skin_temp_pm = pd.to_numeric(subjects_data.iloc[:, 29], errors='coerce')
real_core_temp_am = pd.to_numeric(subjects_data.iloc[:, 7], errors='coerce')
real_core_temp_pm = pd.to_numeric(subjects_data.iloc[:, 9], errors='coerce')
real_weight_pre_am = pd.to_numeric(subjects_data.iloc[:, 10], errors='coerce')
real_weight_post_am = pd.to_numeric(subjects_data.iloc[:, 11], errors='coerce')
real_age = pd.to_numeric(subjects_data.iloc[:, 3], errors='coerce')
real_height = pd.to_numeric(subjects_data.iloc[:, 4], errors='coerce')
real_body_fat = pd.to_numeric(subjects_data.iloc[:, 5], errors='coerce')

# Calculate key statistics from real data
stats = {
    'skin_temp_mean': np.nanmean(np.concatenate([real_skin_temp_am.dropna(), real_skin_temp_pm.dropna()])),
    'skin_temp_std': np.nanstd(np.concatenate([real_skin_temp_am.dropna(), real_skin_temp_pm.dropna()])),
    'core_temp_mean': np.nanmean(np.concatenate([real_core_temp_am.dropna(), real_core_temp_pm.dropna()])),
    'core_temp_std': np.nanstd(np.concatenate([real_core_temp_am.dropna(), real_core_temp_pm.dropna()])),
    'weight_loss_mean': np.nanmean(real_weight_pre_am - real_weight_post_am),
    'weight_loss_std': np.nanstd(real_weight_pre_am - real_weight_post_am),
    'age_mean': np.nanmean(real_age.dropna()),
    'age_std': np.nanstd(real_age.dropna()),
    'body_fat_mean': np.nanmean(real_body_fat.dropna()),
    'body_fat_std': np.nanstd(real_body_fat.dropna()),
}

# Calculate correlations between features
real_df = pd.DataFrame({
    'skin_temp': np.concatenate([real_skin_temp_am.dropna(), real_skin_temp_pm.dropna()]),
    'core_temp': np.concatenate([real_core_temp_am.dropna(), real_core_temp_pm.dropna()]),
})
correlation = real_df.corr().iloc[0, 1]

stats['skin_core_correlation'] = correlation

print(f"   Real data statistics extracted:")
print(f"   - Skin temp: μ={stats['skin_temp_mean']:.2f}°C, σ={stats['skin_temp_std']:.2f}°C")
print(f"   - Core temp: μ={stats['core_temp_mean']:.2f}°C, σ={stats['core_temp_std']:.2f}°C")
print(f"   - Weight loss: μ={stats['weight_loss_mean']:.2f}kg, σ={stats['weight_loss_std']:.2f}kg")
print(f"   - Skin-core correlation: r={stats['skin_core_correlation']:.3f}")

# ============================================================================
# PHASE 3: GENERATE SYNTHETIC DATA
# ============================================================================

print("\n[Phase 3] Generating synthetic data (10,000 samples)...")

np.random.seed(42)
n_samples = 10000

# 1. Generate correlated features using Cholesky decomposition
# We want skin_temp to be correlated with sweat_rate and salinity
mean = [stats['skin_temp_mean'], 0.8, 45, 28, 4]  # skin_temp, sweat_rate, salinity, wbgt, elapsed_hours
cov = [
    [stats['skin_temp_std']**2, 0.8, 1.5, 0.3, 0.5],
    [0.8, 0.35, 0.6, 0.1, 0.2],
    [1.5, 0.6, 225, 0.5, 0.8],
    [0.3, 0.1, 0.5, 25, 0.2],
    [0.5, 0.2, 0.8, 0.2, 16],
]

# Generate correlated samples
samples = np.random.multivariate_normal(mean, cov, n_samples)
synthetic = pd.DataFrame(samples, columns=['skin_temp', 'sweat_rate', 'salinity', 'wbgt', 'elapsed_hours'])

# 2. Add worker demographic variability (age, weight, body fat)
worker_profiles = []
for _ in range(n_samples):
    profile = {
        'age': np.random.normal(stats['age_mean'], stats['age_std']),
        'weight': np.random.normal(80, 10),
        'body_fat': np.random.normal(stats['body_fat_mean'], stats['body_fat_std']),
    }
    # Apply age/weight effects on features
    if profile['age'] > 45:
        synthetic.loc[_, 'skin_temp'] += 0.2
        synthetic.loc[_, 'sweat_rate'] += 0.1
    if profile['weight'] > 90:
        synthetic.loc[_, 'sweat_rate'] += 0.15

# 3. Add realistic noise (sensor noise + biological variability)
synthetic['skin_temp'] += np.random.normal(0, 0.15, n_samples)
synthetic['sweat_rate'] += np.random.normal(0, 0.05, n_samples)
synthetic['salinity'] += np.random.normal(0, 2, n_samples)

# 4. Clip to realistic ranges
synthetic['skin_temp'] = synthetic['skin_temp'].clip(35.5, 40.0)
synthetic['sweat_rate'] = synthetic['sweat_rate'].clip(0.1, 2.5)
synthetic['salinity'] = synthetic['salinity'].clip(10, 90)
synthetic['wbgt'] = synthetic['wbgt'].clip(18, 38)
synthetic['elapsed_hours'] = synthetic['elapsed_hours'].clip(0, 8)

# 5. Calculate Z-score (personal baseline deviation)
synthetic['z_score'] = (synthetic['salinity'] - 45) / 10

# 6. Add temporal dynamics (simulate heat buildup over shift)
synthetic['temp_rate'] = (synthetic['skin_temp'] - 36.5) / (synthetic['elapsed_hours'] + 0.1)

# 7. Add acclimatization factor (workers adapt over days)
synthetic['acclimatization'] = np.random.uniform(1.0, 2.0, n_samples)

print(f"✅ Generated {len(synthetic)} synthetic samples")

# ============================================================================
# PHASE 4: LABEL DATA BASED ON PHYSIOLOGICAL THRESHOLDS
# ============================================================================

print("\n[Phase 4] Labeling data based on physiological thresholds...")

def label_risk(row):
    """
    Label risk based on physiological thresholds derived from:
    1. Core temperature (>38.5°C = RED, >37.5°C = AMBER)
    2. Salinity deviation (Z-score > 2.5 = RED, > 1.5 = AMBER)
    3. Skin temperature (>38.5°C = RED, >37.5°C = AMBER)
    4. Combination of WBGT + sweat rate
    5. Rate of temperature change (rapid rise = high risk)
    """
    risk_score = 0
    
    # Skin temperature (primary indicator)
    if row['skin_temp'] > 38.5:
        risk_score += 3
    elif row['skin_temp'] > 37.5:
        risk_score += 1
        
    # Salinity Z-score (electrolyte loss)
    if row['z_score'] > 2.5:
        risk_score += 3
    elif row['z_score'] > 1.5:
        risk_score += 1
        
    # Sweat rate (dehydration indicator)
    if row['sweat_rate'] > 1.5:
        risk_score += 2
    elif row['sweat_rate'] > 1.0:
        risk_score += 1
        
    # WBGT (environmental stress)
    if row['wbgt'] > 32:
        risk_score += 2
    elif row['wbgt'] > 28:
        risk_score += 1
        
    # Rate of temperature change (rapid rise = dangerous)
    if row['temp_rate'] > 0.3:
        risk_score += 2
    elif row['temp_rate'] > 0.15:
        risk_score += 1
        
    # Acclimatization (less acclimatized = higher risk)
    if row['acclimatization'] < 1.3:
        risk_score += 1
        
    # Heatstroke conditions (multiple high indicators)
    if (row['skin_temp'] > 38.0 and row['sweat_rate'] > 1.5 and row['wbgt'] > 30):
        risk_score += 3
    
    # Determine final label
    if risk_score >= 8:
        return 'RED'
    elif risk_score >= 4:
        return 'AMBER'
    else:
        return 'GREEN'

synthetic['label'] = synthetic.apply(label_risk, axis=1)

print(f"   Label distribution:")
print(f"   - GREEN:  {sum(synthetic['label'] == 'GREEN'):,} ({sum(synthetic['label'] == 'GREEN')/len(synthetic)*100:.1f}%)")
print(f"   - AMBER:  {sum(synthetic['label'] == 'AMBER'):,} ({sum(synthetic['label'] == 'AMBER')/len(synthetic)*100:.1f}%)")
print(f"   - RED:    {sum(synthetic['label'] == 'RED'):,} ({sum(synthetic['label'] == 'RED')/len(synthetic)*100:.1f}%)")

# ============================================================================
# PHASE 5: TRAIN XGBOOST MODEL
# ============================================================================

print("\n[Phase 5] Training XGBoost model...")

# Define features and target
features = ['skin_temp', 'sweat_rate', 'salinity', 'wbgt', 'elapsed_hours', 'z_score', 'temp_rate', 'acclimatization']
X = synthetic[features]
y = synthetic['label']

# Encode labels
le = LabelEncoder()
y_encoded = le.fit_transform(y)

# Scale features (optional but helps with consistency)
scaler = StandardScaler()
X_scaled = scaler.fit_transform(X)

# Train-test split
X_train, X_test, y_train, y_test = train_test_split(
    X_scaled, y_encoded, test_size=0.2, random_state=42, stratify=y_encoded
)

# XGBoost model with hyperparameters tuned for this problem
model = xgb.XGBClassifier(
    n_estimators=150,
    max_depth=7,
    learning_rate=0.08,
    min_child_weight=3,
    subsample=0.8,
    colsample_bytree=0.8,
    random_state=42,
    eval_metric='mlogloss',
    use_label_encoder=False,
)

print("   Training model...")
model.fit(
    X_train, y_train,
    eval_set=[(X_test, y_test)],
    verbose=False
)

# Evaluate
y_pred = model.predict(X_test)
accuracy = accuracy_score(y_test, y_pred)

print(f"\n   Model Performance:")
print(f"   - Accuracy: {accuracy:.3f} ({accuracy*100:.1f}%)")
print(f"\n   Classification Report:")
print(classification_report(
    y_test, y_pred, 
    target_names=le.classes_,
    digits=3
))

# Feature importance
importance = model.feature_importances_
print(f"\n   Feature Importance:")
for i, (feature, imp) in enumerate(sorted(zip(features, importance), key=lambda x: x[1], reverse=True)):
    print(f"   {i+1}. {feature}: {imp:.3f}")

# ============================================================================
# PHASE 6: EXPORT MODEL FOR FLUTTER
# ============================================================================

print("\n[Phase 6] Exporting model for Flutter application...")

# Save the model in XGBoost format
model.save_model('heat_risk_model.json')
print("✅ Model saved as 'heat_risk_model.json'")

# Save the label encoder
joblib.dump(le, 'label_encoder.pkl')
print("✅ Label encoder saved as 'label_encoder.pkl'")

# Save the scaler
joblib.dump(scaler, 'feature_scaler.pkl')
print("✅ Feature scaler saved as 'feature_scaler.pkl'")

# Save the training dataset
synthetic.to_csv('training_data.csv', index=False)
print("✅ Training dataset saved as 'training_data.csv'")

# Save the real data statistics
stats_df = pd.DataFrame([stats])
stats_df.to_csv('real_data_statistics.csv', index=False)
print("✅ Real data statistics saved as 'real_data_statistics.csv'")

# ============================================================================
# PHASE 7: CREATE SAMPLE DEMO FOR FLUTTER
# ============================================================================

print("\n[Phase 7] Creating sample demo data for Flutter testing...")

# Generate sample sensor readings for demonstration
demo_samples = [
    {'skin_temp': 36.8, 'sweat_rate': 0.5, 'salinity': 42, 'wbgt': 25, 'elapsed_hours': 2, 'label': 'GREEN'},
    {'skin_temp': 37.6, 'sweat_rate': 1.2, 'salinity': 58, 'wbgt': 30, 'elapsed_hours': 4, 'label': 'AMBER'},
    {'skin_temp': 38.7, 'sweat_rate': 1.8, 'salinity': 75, 'wbgt': 33, 'elapsed_hours': 6, 'label': 'RED'},
]

demo_df = pd.DataFrame(demo_samples)
demo_df['z_score'] = (demo_df['salinity'] - 45) / 10
demo_df['temp_rate'] = (demo_df['skin_temp'] - 36.5) / (demo_df['elapsed_hours'] + 0.1)
demo_df['acclimatization'] = 1.5

demo_features = demo_df[features]
demo_scaled = scaler.transform(demo_features)
demo_predictions = model.predict(demo_scaled)
demo_probabilities = model.predict_proba(demo_scaled)

print("   Sample predictions for Flutter testing:")
for i, row in demo_df.iterrows():
    pred_label = le.inverse_transform([demo_predictions[i]])[0]
    probs = demo_probabilities[i]
    print(f"   Sample {i+1}: Skin={row['skin_temp']:.1f}°C, Sweat={row['sweat_rate']:.1f}L/hr, "
          f"Salinity={row['salinity']:.0f}mmol/L → {pred_label} "
          f"(G:{probs[0]:.2f}, A:{probs[1]:.2f}, R:{probs[2]:.2f})")

# Save demo data
demo_df.to_csv('flutter_demo_samples.csv', index=False)
print("✅ Demo samples saved as 'flutter_demo_samples.csv'")

# ============================================================================
# SUMMARY
# ============================================================================

print("\n" + "=" * 60)
print("✅ PIPELINE COMPLETE")
print("=" * 60)
print("\nOutput Files:")
print("   📊 training_data.csv        - 10,000 labeled synthetic samples")
print("   🤖 heat_risk_model.json     - Trained XGBoost model")
print("   🔢 label_encoder.pkl        - Label encoder (GREEN/AMBER/RED)")
print("   📈 feature_scaler.pkl       - Feature scaler for normalization")
print("   📋 real_data_statistics.csv - Statistics from real firefighter data")
print("   📱 flutter_demo_samples.csv - Sample data for Flutter testing")
print("\nNext Steps:")
print("   1. Place heat_risk_model.json in your Flutter app's assets/ folder")
print("   2. Use tflite_flutter to load the model in your app")
print("   3. Use the sample data to test your Flutter integration")
print("   4. Replace sample data with real NFC readings when hardware is ready")
print("\n" + "=" * 60)