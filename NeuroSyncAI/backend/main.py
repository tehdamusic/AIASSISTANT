
# FastAPI Application with OpenAPI Documentation
from fastapi import FastAPI
from fastapi.openapi.utils import get_openapi

app = FastAPI(
    title="NeuroSyncAI API",
    description="API for NeuroSyncAI with detailed documentation and examples.",
    version="1.0",
    docs_url="/docs",  # Enable Swagger UI
    redoc_url="/redoc"  # Enable ReDoc UI
)

# Custom OpenAPI Schema to add descriptions
def custom_openapi():
    if app.openapi_schema:
        return app.openapi_schema
    openapi_schema = get_openapi(
        title="NeuroSyncAI API",
        version="1.0",
        description="This API provides endpoints for authentication, task management, finance tracking, and more.",
        routes=app.routes,
    )
    app.openapi_schema = openapi_schema
    return app.openapi_schema

app.openapi = custom_openapi


from fastapi import FastAPI
from routes import auth, calendar, chat, finance, tasks
from fastapi.openapi.utils import get_openapi

app = FastAPI(
    title="NeuroSync API",
    description="API documentation for the NeuroSync AI backend",
    version="1.0.0",
    contact={
        "name": "Support Team",
        "email": "support@neurosync.ai"
    }
)

# Include routes
app.include_router(auth.router, prefix="/auth", tags=["Authentication"])
app.include_router(calendar.router, prefix="/calendar", tags=["Calendar"])
app.include_router(chat.router, prefix="/chat", tags=["Chat"])
app.include_router(finance.router, prefix="/finance", tags=["Finance"])
app.include_router(tasks.router, prefix="/tasks", tags=["Tasks"])

# Custom OpenAPI documentation with examples
def custom_openapi():
    if app.openapi_schema:
        return app.openapi_schema
    openapi_schema = get_openapi(
        title=app.title,
        version=app.version,
        description=app.description,
        routes=app.routes,
    )
    app.openapi_schema = openapi_schema
    return app.openapi_schema

app.openapi = custom_openapi

# Enable Swagger UI at /docs and ReDoc at /redoc
@app.get("/", include_in_schema=False)
def root():
    return {"message": "Welcome to NeuroSync API. Visit /docs for API documentation."}
