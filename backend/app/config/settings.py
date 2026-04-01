import os
from pydantic_settings import BaseSettings, SettingsConfigDict
from typing import Optional

class Settings(BaseSettings):
    """
    Centralized application configuration.
    Loads values from environment variables or a .env file.
    """
    
    # App Config
    APP_NAME: str = "MediMetra"
    DEBUG: bool = True
    
    # Firebase Config
    # This can be the path to the JSON file or the raw JSON string itself
    FIREBASE_SERVICE_ACCOUNT_JSON: Optional[str] = None
    FIREBASE_CREDENTIALS_PATH: str = "serviceAccountKey.json"
    
    # AI / LLM Config
    GEMINI_API_KEY: Optional[str] = None
    
    # Other Config
    REDIS_URL: Optional[str] = None
    
    # Pydantic Settings configuration
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore"
    )

# Create a global settings object
settings = Settings()
