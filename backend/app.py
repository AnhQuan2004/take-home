import os
import firebase_admin
import pytesseract
from PIL import Image
from firebase_admin import credentials, firestore
from flask import Flask, request, jsonify
from werkzeug.utils import secure_filename

# Initialize Firebase Admin SDK
cred = credentials.Certificate('firebase_credentials.json')
firebase_admin.initialize_app(cred)

# Initialize Firestore
db = firestore.client()

app = Flask(__name__)
app.config['UPLOAD_FOLDER'] = 'uploads'

@app.route('/upload', methods=['POST'])
def upload_file():
    if 'file' not in request.files:
        return jsonify({'error': 'No file part'}), 400
    file = request.files['file']
    if file.filename == '':
        return jsonify({'error': 'No selected file'}), 400
    if file:
        filename = secure_filename(file.filename)
        filepath = os.path.join(app.config['UPLOAD_FOLDER'], filename)
        file.save(filepath)

        # Perform OCR on the uploaded image
        try:
            text = pytesseract.image_to_string(Image.open(filepath))
            return jsonify({'extracted_text': text}), 200
        except Exception as e:
            return jsonify({'error': str(e)}), 500

@app.route('/')
def hello_world():
    # Example: Add data to Firestore
    doc_ref = db.collection('test_collection').document('test_doc')
    doc_ref.set({
        'message': 'Hello from Flask!'
    })
    return 'Hello, World! Data added to Firestore.'

if __name__ == '__main__':
    app.run(debug=True)