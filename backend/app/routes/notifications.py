from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from firebase_admin import firestore
from ..services.auth import get_current_user

router = APIRouter(
    prefix="/notifications",
    tags=["notifications"],
)

class TokenRequest(BaseModel):
    fcm_token: str

@router.post("/register-token")
def register_token(request: TokenRequest, user: dict = Depends(get_current_user)):
    try:
        # Initialize Firestore client
        db = firestore.client()
        uid = user.get("uid")
        
        if not uid:
            raise HTTPException(status_code=401, detail="User ID not found in authentication token")
            
        # Point to the user's document in the "users" collection
        doc_ref = db.collection("users").document(uid)
        
        # Use merge=True to update or create without overwriting other user data
        doc_ref.set({
            "fcm_token": request.fcm_token,
            "updated_at": firestore.SERVER_TIMESTAMP
        }, merge=True)
        
        return {"message": "FCM Token registered successfully in Firestore"}
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to register token: {str(e)}")
