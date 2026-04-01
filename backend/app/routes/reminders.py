from fastapi import APIRouter, Depends
from ..services.auth import get_current_user

router = APIRouter(
    prefix="/reminders",
    tags=["reminders"],
)

@router.get("/")
def get_reminders(user: dict = Depends(get_current_user)):
    # Placeholder for getting reminders
    return {
        "message": "List of reminders",
        "user_id": user.get("uid")
    }
