#!/bin/bash

# Enable required services
gcloud services enable \
    run.googleapis.com \
    cloudfunctions.googleapis.com \
    firestore.googleapis.com \
    --project=p-group-18

# Create Firestore database if not exists
gcloud firestore databases create --region=us-east1 --project=p-group-18

# Deploy Backend (Cloud Function)
gcloud functions deploy social-backend \
    --runtime python310 \
    --trigger-http \
    --allow-unauthenticated \
    --region=us-east1 \
    --project=p-group-18 \
    --source=../backend \
    --entry-point=social_api \
    --timeout=30s

# Get Function URL
FUNCTION_URL=$(gcloud functions describe social-backend \
  --format='value(httpsTrigger.url)' \
  --region=us-east1 \
  --project=p-group-18)

# Deploy Frontend (Cloud Run)
gcloud run deploy social-frontend \
    --source=../frontend \
    --port=80 \
    --allow-unauthenticated \
    --region=us-east1 \
    --project=p-group-18 \
    --set-env-vars="API_URL=$FUNCTION_URL" \
    --platform=managed

# Get Frontend URL
FRONTEND_URL=$(gcloud run services describe social-frontend \
  --format='value(status.url)' \
  --region=us-east1 \
  --project=p-group-18)

# Add sample data
gcloud firestore documents create --collection=posts \
  --data='{text:"Welcome to p-group-18 social network!", likes:0, timestamp:1742926931}' \
  --database=default \
  --project=p-group-18

echo "======================================"
echo "✅ Deployment Complete!"
echo "🔗 Frontend URL: $FRONTEND_URL"
echo "Open this URL to test:"
echo $FRONTEND_URL
echo "======================================"

# Open in default browser
if which xdg-open > /dev/null; then
    xdg-open "$FRONTEND_URL"
elif which open > /dev/null; then
    open "$FRONTEND_URL"
fi
