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

# ===== CLOUD STORAGE HANDLER =====
from google.cloud import storage
from flask import request, jsonify
import os

storage_client = storage.Client()

@app.route('/upload', methods=['POST'])
def upload_photo():
    if 'file' not in request.files:
        return jsonify({"error": "No file provided"}), 400
        
    file = request.files['file']
    if file.filename == '':
        return jsonify({"error": "Empty filename"}), 400

    try:
        # Create user-specific folder
        user_id = request.headers.get('X-User-ID') or 'anonymous'
        file_path = f"photos/{user_id}/{file.filename}"
        
        # Upload to Cloud Storage
        bucket = storage_client.bucket("p-group-18-uploads")
        blob = bucket.blob(file_path)
        blob.upload_from_string(
            file.read(),
            content_type=file.content_type
        )
        
        # Make publicly accessible (for demo)
        blob.make_public()
        
        return jsonify({
            "url": blob.public_url,
            "path": file_path
        })
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500
