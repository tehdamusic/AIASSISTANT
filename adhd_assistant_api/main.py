from fastapi import FastAPI, Depends
from fastapi.middleware.cors import CORSMiddleware

from config import settings
from routes import auth, tasks, reminders, users
from services.auth_service import get_current_user
from utils.db import Base, engine

# Create database tables
Base.metadata.create_all(bind=engine)

# Initialize FastAPI app
app = FastAPI(
    title=settings.APP_NAME,
    description=settings.APP_DESCRIPTION,
    version=settings.APP_VERSION
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(auth.router)
app.include_router(
    tasks.router,
    dependencies=[Depends(get_current_user)]  # Protect all task routes
)
app.include_router(
    reminders.router,
    dependencies=[Depends(get_current_user)]  # Protect all reminder routes
)
app.include_router(
    users.router,
    dependencies=[Depends(get_current_user)]  # Protect all user routes
)

@app.get("/", tags=["root"])
async def root():
    """
    Root endpoint - health check
    """
    return {
        "app_name": settings.APP_NAME,
        "version": settings.APP_VERSION,
        "status": "healthy"
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
