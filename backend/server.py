from flask import Flask, request, jsonify
import os
import wave
import json
import ffmpeg
from vosk import Model, KaldiRecognizer
from pydub import AudioSegment

app = Flask(__name__)

UPLOAD_FOLDER = './uploads'
TRANSCRIPTIONS_FOLDER = './transcriptions'
VOSK_MODEL_PATH = "./vosk-model-small-en-us-0.15"

# Ensure the uploads and transcriptions folders exist
os.makedirs(UPLOAD_FOLDER, exist_ok=True)
os.makedirs(TRANSCRIPTIONS_FOLDER, exist_ok=True)

# Load Vosk model
if not os.path.exists(VOSK_MODEL_PATH):
    print("Please download the model from https://alphacephei.com/vosk/models and unpack as 'model' in the current folder.")
    exit(1)

model = Model(VOSK_MODEL_PATH)

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

def transcribe_audio_vosk(wav_file_path):
    try:
        # Open the audio file
        wf = wave.open(wav_file_path, "rb")
        if wf.getnchannels() != 1 or wf.getsampwidth() != 2 or wf.getframerate() != 16000:
            return "Audio file must be WAV format Mono PCM at 16kHz."

        # Initialize recognizer with the model and the sample rate
        recognizer = KaldiRecognizer(model, wf.getframerate())
        recognizer.SetWords(True)

        # Transcribe the audio file
        transcript = ""
        while True:
            data = wf.readframes(4000)
            if len(data) == 0:
                break
            if recognizer.AcceptWaveform(data):
                result = json.loads(recognizer.Result())
                transcript += result.get('text', '')

        final_result = json.loads(recognizer.FinalResult())
        transcript += final_result.get('text', '')

        return transcript
    except Exception as e:
        print(f"Error transcribing file {wav_file_path} with Vosk: {e}")
        return f"Error: {str(e)}"

@app.route('/upload', methods=['POST'])
def upload_file():
    if 'file' not in request.files:
        return jsonify({"error": "No file part"}), 400

    file = request.files['file']
    if file.filename == '':
        return jsonify({"error": "No selected file"}), 400

    # Save the uploaded file
    file_path = os.path.join(UPLOAD_FOLDER, file.filename)
    file.save(file_path)
    print(f"File saved to {file_path}")  # Debug print

    return jsonify({"message": "File uploaded successfully"}), 200

@app.route('/transcribe_all', methods=['GET'])
def transcribe_all():
    cache_dir = UPLOAD_FOLDER  # Path to the uploads folder
    print(f"Cache directory received: {cache_dir}")  # Debug print

    if not os.path.exists(cache_dir):
        print("Directory does not exist!")  # Debug print
        return jsonify({"error": "Cache directory does not exist"}), 404

    transcripts = {}

    print(f"Checking directory contents at: {cache_dir}")  # Debug print
    for file_name in os.listdir(cache_dir):
        print(f"Processing file: {file_name}")  # Debug print
        if file_name.endswith(".mp3"):  # Assuming audio files are in mp3 format
            file_path = os.path.join(cache_dir, file_name)
            try:
                # Convert MP3 to WAV with resampling
                wav_file_path = convert_mp3_to_wav(file_path)
                if wav_file_path:
                    transcript = transcribe_audio_vosk(wav_file_path)
                    transcripts[file_name] = transcript
                    
                    # Save the transcription to a text file
                    transcript_file_name = f"{os.path.splitext(file_name)[0]}.txt"
                    transcript_file_path = os.path.join(TRANSCRIPTIONS_FOLDER, transcript_file_name)
                    with open(transcript_file_path, 'w') as f:
                        f.write(transcript)
                    print(f"Transcription saved to {transcript_file_path}")  # Debug print
                else:
                    transcripts[file_name] = "Error converting to WAV"
            except Exception as e:
                transcripts[file_name] = f"Error: {str(e)}"
                print(f"Error processing file {file_name}: {str(e)}")  # Debug print

    return jsonify(transcripts)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
