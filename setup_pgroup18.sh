#!/bin/bash
# ==================================================
# Social Media App Auto-Deployer for GCP
# Project: p-group-18
# Region: us-east1
# ==================================================

# Configuration
PROJECT_ID="p-group-18"
REGION="us-east1"
APP_NAME="social-app"
FRONTEND_SERVICE="social-frontend"
BACKEND_SERVICE="social-backend"

# Initialize project
gcloud config set project $PROJECT_ID
gcloud config set compute/region $REGION
mkdir -p $APP_NAME/{frontend,backend,scripts}
cd $APP_NAME

# --------------------------
# 1. Create all project files
# --------------------------

# Frontend: index.html
cat > frontend/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Social Media App - p-group-18</title>
    <script src="app.js"></script>
    <style>
        body { font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; }
        #posts { margin: 20px 0; }
        .post { padding: 10px; border: 1px solid #ddd; margin-bottom: 10px; border-radius: 5px; }
        button { background: #4285F4; color: white; border: none; padding: 5px 10px; cursor: pointer; border-radius: 3px; }
        input { padding: 8px; width: 70%; margin-right: 5px; }
        form { margin-bottom: 20px; }
    </style>
</head>
<body>
    <h1>Social Media Demo (p-group-18)</h1>
    <form id="post-form">
        <input type="text" id="post-content" placeholder="Write a post..." required>
        <button type="submit">Post</button>
    </form>
    <div id="posts"></div>
</body>
</html>
EOF

# Frontend: app.js
cat > frontend/app.js << 'EOF'
const API_URL = process.env.API_URL;

async function loadPosts() {
    try {
        const res = await fetch(`${API_URL}/posts`);
        const posts = await res.json();
        document.getElementById('posts').innerHTML = posts
            .map(post => `
                <div class="post">
                    <p>${post.text}</p>
                    <button onclick="likePost('${post.id}')">
                        ❤️ Likes: ${post.likes}
                    </button>
                </div>
            `).join('');
    } catch (err) {
        console.error("Error loading posts:", err);
    }
}

async function likePost(id) {
    try {
        await fetch(`${API_URL}/like`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ id })
        });
    } catch (err) {
        console.error("Error liking post:", err);
    }
    loadPosts();
}

document.getElementById('post-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    const content = document.getElementById('post-content').value;
    try {
        await fetch(`${API_URL}/post`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ text: content })
        });
    } catch (err) {
        console.error("Error creating post:", err);
    }
    loadPosts();
    e.target.reset();
});

// Initial load and auto-refresh
loadPosts();
setInterval(loadPosts, 5000);
EOF

# Backend: main.py (Cloud Function)
cat > backend/main.py << 'EOF'
from google.cloud import firestore
from flask import jsonify, request
import os
import datetime

db = firestore.Client()

def social_api(request):
    if request.path == '/posts' and request.method == 'GET':
        docs = db.collection('posts').order_by('timestamp', direction='DESCENDING').stream()
        return jsonify([{'id': doc.id, **doc.to_dict()} for doc in docs])
    
    if request.path == '/like' and request.method == 'POST':
        data = request.get_json()
        db.collection('posts').document(data['id']).update({
            'likes': firestore.Increment(1)
        })
        return jsonify({'status': 'success'})
    
    if request.path == '/post' and request.method == 'POST':
        data = request.get_json()
        doc_ref = db.collection('posts').document()
        doc_ref.set({
            'text': data['text'],
            'likes': 0,
            'timestamp': firestore.SERVER_TIMESTAMP
        })
        return jsonify({'id': doc_ref.id})
    
    return jsonify({'error': 'Not found'}), 404
EOF

# Dockerfile for Frontend
cat > frontend/Dockerfile << 'EOF'
FROM nginx:alpine
COPY index.html app.js /usr/share/nginx/html/
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
EOF

# --------------------------
# 2. Create Deployment Script
# --------------------------
cat > scripts/deploy.sh << EOF
#!/bin/bash

# Enable required services
gcloud services enable \\
    run.googleapis.com \\
    cloudfunctions.googleapis.com \\
    firestore.googleapis.com \\
    --project=$PROJECT_ID

# Create Firestore database if not exists
gcloud firestore databases create --region=$REGION --project=$PROJECT_ID

# Deploy Backend (Cloud Function)
gcloud functions deploy $BACKEND_SERVICE \\
    --runtime python310 \\
    --trigger-http \\
    --allow-unauthenticated \\
    --region=$REGION \\
    --project=$PROJECT_ID \\
    --source=../backend \\
    --entry-point=social_api \\
    --timeout=30s

# Get Function URL
FUNCTION_URL=\$(gcloud functions describe $BACKEND_SERVICE \\
  --format='value(httpsTrigger.url)' \\
  --region=$REGION \\
  --project=$PROJECT_ID)

# Deploy Frontend (Cloud Run)
gcloud run deploy $FRONTEND_SERVICE \\
    --source=../frontend \\
    --port=80 \\
    --allow-unauthenticated \\
    --region=$REGION \\
    --project=$PROJECT_ID \\
    --set-env-vars="API_URL=\$FUNCTION_URL" \\
    --platform=managed

# Get Frontend URL
FRONTEND_URL=\$(gcloud run services describe $FRONTEND_SERVICE \\
  --format='value(status.url)' \\
  --region=$REGION \\
  --project=$PROJECT_ID)

# Add sample data
gcloud firestore documents create --collection=posts \\
  --data='{text:"Welcome to p-group-18 social network!", likes:0, timestamp:$(date +%s)}' \\
  --database=default \\
  --project=$PROJECT_ID

echo "======================================"
echo "✅ Deployment Complete!"
echo "🔗 Frontend URL: \$FRONTEND_URL"
echo "Open this URL to test:"
echo \$FRONTEND_URL
echo "======================================"

# Open in default browser
if which xdg-open > /dev/null; then
    xdg-open "\$FRONTEND_URL"
elif which open > /dev/null; then
    open "\$FRONTEND_URL"
fi
EOF

chmod +x scripts/deploy.sh

echo "======================================"
echo "✅ All files created for project p-group-18!"
echo "To deploy:"
echo "1. cd $APP_NAME"
echo "2. ./scripts/deploy.sh"
echo "======================================"