import os
import json
import firebase_admin
from firebase_admin import credentials
from app.config.settings import Settings

def init_firebase(settings: Settings):
    """
    Initialize Firebase Admin SDK using centralized settings.
    Supports either a JSON string in environment variable or a local JSON file.
    """
    if not firebase_admin._apps:
        # 1. Try loading from a JSON string in environment (for cloud deployment)
        if settings.FIREBASE_SERVICE_ACCOUNT_JSON:
            try:
                service_account_info = json.loads(settings.FIREBASE_SERVICE_ACCOUNT_JSON)
                cred = credentials.Certificate(service_account_info)
                firebase_admin.initialize_app(cred)
                print("Firebase Admin initialized from JSON string.")
                return
            except Exception as e:
                print(f"Error loading FIREBASE_SERVICE_ACCOUNT_JSON: {e}")

        # 2. Try loading from a local JSON file (for local development)
        cred_path = settings.FIREBASE_CREDENTIALS_PATH
        if os.path.exists(cred_path):
            cred = credentials.Certificate(cred_path)
            firebase_admin.initialize_app(cred)
            print(f"Firebase Admin initialized from local file: {cred_path}")
        else:
            # 3. Fallback to default application credentials
            try:
                firebase_admin.initialize_app()
                print("Firebase Admin initialized with default credentials.")
            except Exception as e:
                print(f"Warning: Failed to initialize Firebase Admin: {str(e)}")
                print("Please set 'FIREBASE_SERVICE_ACCOUNT_JSON' or provide 'serviceAccountKey.json' locally.")
