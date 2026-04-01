from firebase_admin import firestore, messaging
import logging

# Configure basic logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def send_push_notification(uid: str, title: str, body: str, data: dict[str, str] | None = None):
    """
    Looks up a user's FCM token in Firestore and sends them a push notification.
    """
    try:
        db = firestore.client()
        doc_ref = db.collection("users").document(uid)
        doc = doc_ref.get()
        
        if not doc.exists:
            logger.warning(f"User {uid} not found in Firestore. Cannot send notification.")
            return False
            
        user_data = doc.to_dict()
        fcm_token = user_data.get("fcm_token")
        
        if not fcm_token:
            logger.warning(f"User {uid} does not have a registered FCM token.")
            return False
            
        # Construct the Firebase Cloud Messaging payload
        message = messaging.Message(
            notification=messaging.Notification(
                title=title,
                body=body
            ),
            data=data if data else {},
            token=fcm_token
        )
        
        # Dispatch the notification
        response = messaging.send(message)
        logger.info(f"Successfully sent message to {uid}. Message ID: {response}")
        return True
        
    except Exception as e:
        logger.error(f"Error sending push notification to {uid}: {str(e)}")
        return False
