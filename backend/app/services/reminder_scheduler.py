import threading
import time
from datetime import datetime, timezone
from firebase_admin import firestore
from .notification_service import send_push_notification
import logging

logger = logging.getLogger(__name__)

def check_due_reminders():
    """
    Checks the Firestore 'reminders' collection for any tasks/reminders that are past due 
    and haven't been notified yet, and sends a push notification.
    """
    try:
        db = firestore.client()
        now = datetime.now(timezone.utc)
        
        # Query for reminders that are due and not yet notified
        reminders_ref = db.collection("reminders")
        # In a real app, you might need a composite index in Firestore for this exact query
        query = reminders_ref.where("due_date", "<=", now).where("notified", "==", False)
        
        results = query.stream()
        
        for doc in results:
            reminder = doc.to_dict()
            uid = reminder.get("uid")
            title = reminder.get("title", "Reminder")
            body = reminder.get("description", "You have a pending reminder!")
            
            if uid:
                # Dispatch the notification!
                success = send_push_notification(uid, title, body)
                
                # Mark as notified so we don't spam the user, even if dispatch failed 
                # (You might want to retry later if it fails, depending on requirements)
                if success:
                     doc.reference.update({"notified": True})
                    
    except Exception as e:
        logger.error(f"Scheduler failed to check reminders: {str(e)}")

def run_scheduler_loop():
    while True:
        check_due_reminders()
        # Check every 60 seconds
        time.sleep(60)

def start_scheduler():
    logger.info("Starting background reminder scheduler...")
    # Run the scheduler in a daemon thread so it doesn't block FastAPI
    thread = threading.Thread(target=run_scheduler_loop, daemon=True)
    thread.start()
