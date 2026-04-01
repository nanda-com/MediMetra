from fastapi import APIRouter, Depends, HTTPException, UploadFile, File
import os
import uuid
import datetime
import logging
from firebase_admin import firestore
from ..services.auth import get_current_user
from ..services.ai_medical_parser import parse_medical_report_with_ai

logger = logging.getLogger(__name__)

router = APIRouter(
    prefix="/reports",
    tags=["reports"],
)

UPLOAD_DIR = "uploads"
# Automatically generate the folder if it doesn't already exist
os.makedirs(UPLOAD_DIR, exist_ok=True)

@router.post("/upload")
def upload_medical_report(file: UploadFile = File(...), user: dict = Depends(get_current_user)):
    """
    Accepts a multipart file upload from the Flutter app, 
    stores it locally as requested, parses the instructions using Google Gemini,
    and batches Reminders directly into Firestore!
    """
    try:
        uid = user.get("uid")
        if not uid:
            raise HTTPException(status_code=401, detail="User authentication not found.")

        # Construct secure local filename
        file_extension = file.filename.split(".")[-1] if "." in file.filename else "jpg"
        unique_id = str(uuid.uuid4())
        local_filename = f"{unique_id}.{file_extension}"
        local_path = os.path.join(UPLOAD_DIR, local_filename)
        
        # Write chunks to local disk securely
        with open(local_path, "wb") as buffer:
            buffer.write(file.file.read())
                
        logger.info(f"Report securely stored locally at {local_path}. Handing off to Gemini Parse...")
        
        # Pass path to Gemini AI
        ai_instructions = parse_medical_report_with_ai(local_path)
        
        if not ai_instructions:
            return {"message": "Report processed, but Gemini found no actionable prescriptions or schedules.", "reminders": 0}
            
        db = firestore.client()
        generated_reminders = []
        now = datetime.datetime.now(datetime.timezone.utc)
        
        # Turn the generalized AI schedule into absolute dates
        for item in ai_instructions:
            title = item.get("title", "Medical Action")
            duration_days = int(item.get("duration_days", 1))
            
            # Spin up X reminders corresponding to the duration prescribed
            for day_offset in range(1, duration_days + 1):
                # Set due date incrementally for the future (e.g., 24 hours apart)
                due_time = now + datetime.timedelta(days=day_offset)
                
                reminder_payload = {
                    "uid": uid,
                    "title": f"Dose: {title}",
                    "description": f"AI scheduled this reminder automatically from your medical report.",
                    "due_date": due_time,
                    "notified": False,
                    "source": "ai_report_parser",
                    "report_id": unique_id
                }
                
                # Push the absolute reminder to Firestore where the scheduler will pick it up
                _, doc_ref = db.collection("reminders").add(reminder_payload)
                generated_reminders.append(doc_ref.id)
                
        # Link this particular report artifact directly to the user's history
        db.collection("users").document(uid).collection("reports").document(unique_id).set({
            "local_path": local_path,
            "filename": file.filename,
            "reminders_count": len(generated_reminders),
            "uploaded_at": firestore.SERVER_TIMESTAMP
        })
        
        return {
            "message": "Report successfully extracted and auto-reminders created!",
            "parsed_diagnoses": len(ai_instructions),
            "total_reminders_generated": len(generated_reminders),
            "raw_ai_data": ai_instructions
        }
        
    except Exception as e:
        logger.error(f"Critical error processing Medical Upload endpoint: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))
