import os
from pydantic import BaseSettings
from dotenv import load_dotenv

# Load .env file
load_dotenv()

class Settings(BaseSettings):
    # App settings
    APP_NAME: str = "ADHD Assistant API"
    APP_VERSION: str = "1.0.0"
    APP_DESCRIPTION: str = "An API to help ADHD individuals manage tasks and reminders"
    
    # JWT settings
    SECRET_KEY: str = os.getenv("SECRET_KEY", "your-super-secret-key-for-development-only")
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    
    # Database settings
    DATABASE_URL: str = os.getenv("DATABASE_URL", "sqlite:///./adhd_assistant.db")
    
    # CORS settings
    CORS_ORIGINS: list = ["*"]
    
    # Notification settings
    EMAIL_ENABLED: bool = False
    EMAIL_HOST: str = os.getenv("EMAIL_HOST", "")
    EMAIL_PORT: int = int(os.getenv("EMAIL_PORT", "587"))
    EMAIL_USERNAME: str = os.getenv("EMAIL_USERNAME", "")
    EMAIL_PASSWORD: str = os.getenv("EMAIL_PASSWORD", "")
    EMAIL_FROM: str = os.getenv("EMAIL_FROM", "")

    class Config:
        env_file = ".env"

# Create global settings object
settings = Settings()
