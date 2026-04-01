from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.config.settings import settings
from app.services.reminder_scheduler import start_scheduler
from app.routes import reminders, notifications, reports
from app.services.firebase_admin import init_firebase

app = FastAPI(title=settings.APP_NAME)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(reminders.router)
app.include_router(notifications.router)
app.include_router(reports.router)

@app.on_event("startup")
def startup_event():
    # Initialize connection to Firebase Admin SDK using centralized settings
    init_firebase(settings)
    # Start the background task scheduler
    start_scheduler()