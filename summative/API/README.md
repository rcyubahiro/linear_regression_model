# Maternal Health Access — Regression API

## Folder structure
```
summative/API/
├── prediction.py         # FastAPI app: /predict, /retrain, CORS config
├── schemas.py              # Pydantic request/response models with type + range constraints
├── model_utils.py           # load/predict/retrain logic
├── requirements.txt           # fastapi, pydantic, uvicorn, scikit-learn, etc.
├── best_model.pkl               # <- COPY FROM the notebook's output (multivariate.ipynb)
├── scaler.pkl                     # <- COPY FROM the notebook's output
├── feature_cols.pkl                 # <- COPY FROM the notebook's output
└── best_model_name.pkl                # <- COPY FROM the notebook's output
```

**Before running or deploying**, run `summative/linear_regression/multivariate.ipynb` end to end, then
copy the 4 generated files (`best_model.pkl`, `scaler.pkl`, `feature_cols.pkl`, `best_model_name.pkl`)
into this `summative/API/` folder.

## Run locally
```bash
cd api
pip install -r requirements.txt
uvicorn prediction:app --reload
```
Then open http://127.0.0.1:8000/docs for the Swagger UI.

## Test with curl
```bash
curl -X POST http://127.0.0.1:8000/predict \
  -H "Content-Type: application/json" \
  -d '{
    "skilled_birth_attendance_pct": 55.0,
    "health_expenditure_per_capita": 40.0,
    "physicians_per_1000": 0.15,
    "female_literacy_rate_pct": 50.0,
    "access_to_electricity_pct": 35.0,
    "antenatal_care_4visits_pct": 45.0
  }'
```

For retraining, upload a CSV with the 6 feature columns plus
`maternal_mortality_ratio`:
```bash
curl -X POST http://127.0.0.1:8000/retrain \
  -F "file=@new_data.csv"
```

## Deploy to Render
1. Push this `api/` folder to a GitHub repo (make sure the 4 `.pkl` files are
   committed too — they're small, so that's fine).
2. Go to https://render.com and sign in (GitHub login is easiest).
3. Click **New +** → **Web Service** → connect your GitHub repo.
4. Settings:
   - **Root Directory**: `summative/API` (this repo's required folder structure)
   - **Environment**: Python 3
   - **Build Command**: `pip install -r requirements.txt`
   - **Start Command**: `uvicorn prediction:app --host 0.0.0.0 --port $PORT`
5. **Important for CORS grading**: once you know your Flutter app's actual
   origin (e.g. its Flutter web build URL, or just keep localhost for a
   mobile-only app), set the `ALLOWED_ORIGINS` environment variable in
   Render to that real value, comma-separated if more than one. The code
   defaults to localhost origins only — deliberately not a wildcard `*` —
   so update this before your final submission/recording.
6. Click **Create Web Service**. Render will build and deploy — takes a
   few minutes on the free tier.
7. Once live, your Swagger UI is at:
   `https://<your-service-name>.onrender.com/docs`
   This is the public URL to put in your submission — clicking it lands
   directly on the interactive Swagger UI (the `/` route redirects there).

**Free tier note**: Render's free web services spin down after ~15 minutes
of inactivity and take ~30-60 seconds to wake up on the next request — so
if a grader's first request seems to hang, that's why. Worth mentioning in
your video so it doesn't look broken.
