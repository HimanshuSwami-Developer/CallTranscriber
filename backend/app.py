from flask import Flask, request, jsonify
import os
import requests
from pydub import AudioSegment

import requests
import time
import ffmpeg

app = Flask(__name__)

UPLOAD_FOLDER = './uploads'
TRANSCRIPTIONS_FOLDER = './transcriptions'

# Ensure the uploads and transcriptions folders exist
os.makedirs(UPLOAD_FOLDER, exist_ok=True)
os.makedirs(TRANSCRIPTIONS_FOLDER, exist_ok=True)

API_URL = "https://api-inference.huggingface.co/models/facebook/wav2vec2-base-960h"
HEADERS = {"Authorization": "Bearer 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"}  # Replace with your API key

def convert_mp3_to_wav(mp3_file_path):
    try:
        wav_file_path = mp3_file_path.replace('.mp3', '.wav')
        print(f"Converting {mp3_file_path} to {wav_file_path} with resampling to 16kHz")  # Debug print
        
        # Using ffmpeg-python to convert MP3 to WAV with resampling
        (
            ffmpeg
            .input(mp3_file_path)
            .output(wav_file_path, ar=16000, ac=1)
            .run()
        )
        
        return wav_file_path
    except ffmpeg.Error as e:
        print(f"Error converting file {mp3_file_path} to WAV: {e}")
        return None

def transcribe_audio_huggingface(wav_file_path, retries=5, delay=20):
    for attempt in range(retries):
        try:
            with open(wav_file_path, "rb") as audio_file:
                audio_data = audio_file.read()

            response = requests.post(API_URL, headers=HEADERS, data=audio_data)
            
            if response.status_code == 200:
                result = response.json()
                transcript = result.get('text', '')
                return transcript
            elif response.status_code == 503:
                print(f"Model is loading, retrying in {delay} seconds...")
                time.sleep(delay)  # Wait before retrying
            else:
                print(f"Error: {response.status_code} - {response.text}")
                return f"Error: {response.text}"
        
        except Exception as e:
            print(f"Error transcribing file {wav_file_path} with Hugging Face API: {e}")
            return f"Error: {str(e)}"

    return "Failed to transcribe after several retries."

@app.route('/upload', methods=['POST'])
def upload_file():
    if 'file' not in request.files:
        return jsonify({"error": "No file part"}), 400

    file = request.files['file']
    if file.filename == '':
        return jsonify({"error": "No selected file"}), 400

    file_path = os.path.join(UPLOAD_FOLDER, file.filename)
    file.save(file_path)
    print(f"File uploaded to: {file_path}")  # Debug print

    return jsonify({"message": "File uploaded successfully"}), 200

@app.route('/transcribe_all', methods=['GET'])
def transcribe_all():
    if not os.path.exists(UPLOAD_FOLDER):
        return jsonify({"error": "Uploads directory does not exist"}), 404

    transcripts = {}
    
    for file_name in os.listdir(UPLOAD_FOLDER):
        if file_name.endswith(".mp3"):
            file_path = os.path.join(UPLOAD_FOLDER, file_name)
            print(f"Processing file: {file_path}")  # Debug print
            
            # Convert MP3 to WAV
            wav_file_path = convert_mp3_to_wav(file_path)
            if wav_file_path:
                transcript = transcribe_audio_huggingface(wav_file_path)
                transcripts[file_name] = transcript
                
                # Save the transcription to a text file
                transcript_file_name = f"{os.path.splitext(file_name)[0]}.txt"
                transcript_file_path = os.path.join(TRANSCRIPTIONS_FOLDER, transcript_file_name)
                print(f"Saving transcript to: {transcript_file_path}")  # Debug print
                with open(transcript_file_path, 'w') as f:
                    f.write(transcript)
                    print(f"Transcript saved: {transcript_file_path}")  # Debug print
            else:
                transcripts[file_name] = "Error converting MP3 to WAV"

    return jsonify(transcripts)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
