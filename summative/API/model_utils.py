"""
model_utils.py — loads the Task 1 model artifacts and provides predict/retrain logic.

Expects these files (produced in Task 1) to sit alongside this module:
  best_model.pkl, scaler.pkl, feature_cols.pkl
"""

import os
import joblib
import pandas as pd
import numpy as np
from sklearn.linear_model import Ridge
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
from sklearn.metrics import mean_squared_error, r2_score

ARTIFACT_DIR = os.path.dirname(os.path.abspath(__file__))
MODEL_PATH = os.path.join(ARTIFACT_DIR, "best_model.pkl")
SCALER_PATH = os.path.join(ARTIFACT_DIR, "scaler.pkl")
FEATURES_PATH = os.path.join(ARTIFACT_DIR, "feature_cols.pkl")
MODEL_NAME_PATH = os.path.join(ARTIFACT_DIR, "best_model_name.pkl")

TARGET_COL = "maternal_mortality_ratio"


def load_artifacts():
    model = joblib.load(MODEL_PATH)
    scaler = joblib.load(SCALER_PATH)
    feature_cols = joblib.load(FEATURES_PATH)
    model_name = joblib.load(MODEL_NAME_PATH) if os.path.exists(MODEL_NAME_PATH) else "Ridge Regression"
    return model, scaler, feature_cols, model_name


def predict_one(input_dict: dict):
    model, scaler, feature_cols, model_name = load_artifacts()
    x_raw = pd.DataFrame([[input_dict[col] for col in feature_cols]], columns=feature_cols)
    x_scaled = scaler.transform(x_raw)
    prediction = float(model.predict(x_scaled)[0])
    return prediction, model_name


def retrain_from_csv(csv_path: str):
    """
    Retrain the model using a CSV that contains the same feature columns
    plus the target column (maternal_mortality_ratio). This is intentionally
    a full retrain (not incremental) so the saved scaler and model stay
    consistent with each other.
    """
    _, _, feature_cols, _ = load_artifacts()

    df = pd.read_csv(csv_path)
    missing_cols = [c for c in feature_cols + [TARGET_COL] if c not in df.columns]
    if missing_cols:
        raise ValueError(f"Uploaded CSV is missing required columns: {missing_cols}")

    df = df.dropna(subset=[TARGET_COL])
    X = df[feature_cols].copy()
    # simple median imputation for any missing predictor values, consistent
    # with the approach used in Task 1's feature engineering step
    X = X.fillna(X.median(numeric_only=True))
    y = df[TARGET_COL].values

    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42
    )

    new_scaler = StandardScaler()
    X_train_scaled = new_scaler.fit_transform(X_train)
    X_test_scaled = new_scaler.transform(X_test)

    new_model = Ridge(alpha=1.0)
    new_model.fit(X_train_scaled, y_train)

    train_mse = mean_squared_error(y_train, new_model.predict(X_train_scaled))
    test_pred = new_model.predict(X_test_scaled)
    test_mse = mean_squared_error(y_test, test_pred)
    test_r2 = r2_score(y_test, test_pred)

    # Overwrite the saved artifacts so /predict immediately uses the new model
    joblib.dump(new_model, MODEL_PATH)
    joblib.dump(new_scaler, SCALER_PATH)
    joblib.dump("Ridge Regression (retrained)", MODEL_NAME_PATH)

    return {
        "rows_used_for_training": len(df),
        "train_mse": float(train_mse),
        "test_mse": float(test_mse),
        "test_r2": float(test_r2),
    }
