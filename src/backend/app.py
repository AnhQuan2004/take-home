import os
import firebase_admin
import google.generativeai as genai
from PIL import Image
from firebase_admin import credentials, firestore
from flask import Flask, request, jsonify
from flask_cors import CORS
from dotenv import load_dotenv

load_dotenv()

# Use an absolute path to the credentials file
cred_path = 'E:/Job/PV/Take test/src/backend/firebase_credentials.json'

# Initialize Firebase Admin SDK
cred = credentials.Certificate(cred_path)
firebase_admin.initialize_app(cred)

# Initialize Firestore
db = firestore.client()

# Configure Gemini API
genai.configure(api_key=os.getenv("GEMINI_API_KEY"))
model = genai.GenerativeModel('gemini-2.5-flash')

app = Flask(__name__)
CORS(app) # Enable CORS for all routes

@app.route('/upload', methods=['POST'])
def upload_file():
    if 'file' not in request.files:
        return jsonify({'error': 'No file part'}), 400
    file = request.files['file']
    if file.filename == '':
        return jsonify({'error': 'No selected file'}), 400
    if file:
        # Read the image file directly from the request
        img = Image.open(file.stream)

        try:
            # System prompt for the model
            system_prompt = """
            You are a math tutor. You will be given an image containing multiple-choice math questions.
            Your task is to:
            1. Read and transcribe each question exactly as it appears in the image.
            2. Solve each question step-by-step, explaining the reasoning.
            3. State the correct option number (1, 2, 3, or 4) for each question.
            4. Keep all mathematical notation (fractions, degrees, angles) in proper format.
            """
            
            # Send image and prompt to Gemini Pro Vision
            response = model.generate_content([system_prompt, img])
            solution = response.text
            
            # Store problem and solution in Firestore
            problem_ref = db.collection('homework_problems').document()
            problem_ref.set({
                'problem': 'Image-based problem',
                'solution': solution
            })
            
            return jsonify({'solution': solution}), 200
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