from fastapi import APIRouter, Depends, HTTPException, status, Request, Response
from fastapi.responses import RedirectResponse
from pydantic import BaseModel
from typing import Optional
import logging

from services.google_calendar_service import google_calendar_service
from config import get_settings

# Configure logging
logger = logging.getLogger(__name__)

# Create the router
router = APIRouter(
    prefix="/calendar",
    tags=["calendar"],
    responses={404: {"description": "Not found"}},
)

# Request/Response models
class AuthRequest(BaseModel):
    """Model for authentication request"""
    user_id: str
    redirect_uri: Optional[str] = None


class CallbackRequest(BaseModel):
    """Model for callback request"""
    user_id: str
    code: str
    state: str


class CalendarEventRequest(BaseModel):
    """Model for event creation request"""
    user_id: str
    calendar_id: Optional[str] = "primary"
    summary: str
    description: Optional[str] = ""
    location: Optional[str] = ""
    start_time: str  # ISO format
    end_time: str    # ISO format
    attendees: Optional[list[str]] = None


@router.get("/authenticate")
async def authenticate(
    user_id: str,
    settings = Depends(get_settings)
):
    """
    Start Google OAuth2 authentication process.
    
    Args:
        user_id: ID of the user to authenticate
        
    Returns:
        Redirect to Google's OAuth2 consent screen
    """
    try:
        # Determine the redirect URI
        # In production, this should be a configurable URL
        base_url = settings.BASE_URL or "http://localhost:8000"
        redirect_uri = f"{base_url}/api/calendar/callback"
        
        # Get authentication URL from service
        auth_data = await google_calendar_service.authenticate_google(
            user_id=user_id,
            redirect_uri=redirect_uri
        )
        
        # Log authentication attempt (without sensitive info)
        logger.info(f"Starting Google Calendar authentication for user {user_id}")
        
        # Redirect to Google's OAuth2 consent screen
        return RedirectResponse(url=auth_data["authorization_url"])
        
    except Exception as e:
        logger.error(f"Error in Google Calendar authentication: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Authentication error: {str(e)}"
        )


@router.get("/callback")
async def callback(
    code: str,
    state: str,
    error: Optional[str] = None,
    settings = Depends(get_settings)
):
    """
    Handle the Google OAuth2 callback.
    
    Args:
        code: Authorization code from Google
        state: State parameter containing user ID
        error: Error message from Google (if any)
        
    Returns:
        Success or error message
    """
    try:
        # Check for errors from Google
        if error:
            logger.error(f"Google returned an error: {error}")
            return RedirectResponse(
                url=f"{settings.FRONTEND_URL}/calendar-error?error={error}"
            )
        
        # Extract user_id from state
        # The state parameter should contain the user ID that was passed in the authenticate endpoint
        user_id = state
        
        # Determine the redirect URI (must match the one used in authenticate)
        base_url = settings.BASE_URL or "http://localhost:8000"
        redirect_uri = f"{base_url}/api/calendar/callback"
        
        # Store the tokens
        result = await google_calendar_service.store_google_tokens(
            user_id=user_id,
            auth_code=code,
            redirect_uri=redirect_uri,
            state=state
        )
        
        # Log successful authentication
        logger.info(f"Google Calendar authentication successful for user {user_id}")
        
        # Redirect to frontend with success message
        return RedirectResponse(
            url=f"{settings.FRONTEND_URL}/calendar-success"
        )
        
    except Exception as e:
        logger.error(f"Error in Google Calendar callback: {str(e)}")
        
        # Redirect to frontend with error message
        return RedirectResponse(
            url=f"{settings.FRONTEND_URL}/calendar-error?error={str(e)}"
        )


@router.get("/events/{user_id}")
async def get_events(
    user_id: str,
    calendar_id: Optional[str] = "primary",
    max_results: Optional[int] = 10
):
    """
    Get events from a user's calendar.
    
    Args:
        user_id: ID of the user
        calendar_id: ID of the calendar to fetch events from (default: primary)
        max_results: Maximum number of events to return
        
    Returns:
        List of calendar events
    """
    try:
        # Get events from service
        events = await google_calendar_service.get_events(
            user_id=user_id,
            calendar_id=calendar_id,
            max_results=max_results
        )
        
        return {"events": events}
        
    except ValueError as e:
        # Handle case where user is not authenticated
        if "not authenticated" in str(e).lower():
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Google Calendar not authenticated. Please authenticate first."
            )
        
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except Exception as e:
        logger.error(f"Error fetching calendar events: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error fetching calendar events: {str(e)}"
        )


@router.get("/calendars/{user_id}")
async def list_calendars(user_id: str):
    """
    List all calendars for a user.
    
    Args:
        user_id: ID of the user
        
    Returns:
        List of calendars
    """
    try:
        # Get calendars from service
        calendars = await google_calendar_service.list_calendars(user_id)
        
        return {"calendars": calendars}
        
    except ValueError as e:
        # Handle case where user is not authenticated
        if "not authenticated" in str(e).lower():
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Google Calendar not authenticated. Please authenticate first."
            )
        
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except Exception as e:
        logger.error(f"Error listing calendars: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error listing calendars: {str(e)}"
        )


@router.post("/events", status_code=status.HTTP_201_CREATED)
async def create_event(event_request: CalendarEventRequest):
    """
    Create a new event in a user's calendar.
    
    Args:
        event_request: Event details
        
    Returns:
        Created event details
    """
    try:
        # Create event using service
        from datetime import datetime
        
        # Parse ISO format dates
        start_time = datetime.fromisoformat(event_request.start_time.replace('Z', '+00:00'))
        end_time = datetime.fromisoformat(event_request.end_time.replace('Z', '+00:00'))
        
        event = await google_calendar_service.create_event(
            user_id=event_request.user_id,
            calendar_id=event_request.calendar_id,
            summary=event_request.summary,
            description=event_request.description,
            location=event_request.location,
            start_time=start_time,
            end_time=end_time,
            attendees=event_request.attendees
        )
        
        return event
        
    except ValueError as e:
        # Handle case where user is not authenticated
        if "not authenticated" in str(e).lower():
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Google Calendar not authenticated. Please authenticate first."
            )
        
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except Exception as e:
        logger.error(f"Error creating calendar event: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error creating calendar event: {str(e)}"
        )


@router.get("/check-auth/{user_id}")
async def check_auth_status(user_id: str):
    """
    Check if a user is authenticated with Google Calendar.
    
    Args:
        user_id: ID of the user
        
    Returns:
        Authentication status
    """
    try:
        # Try to get credentials
        credentials = await google_calendar_service.get_credentials(user_id)
        
        # Return authentication status
        return {
            "authenticated": credentials is not None,
            "valid": credentials.valid if credentials else False,
            "scopes": credentials.scopes if credentials else []
        }
        
    except Exception as e:
        logger.error(f"Error checking authentication status: {str(e)}")
        return {
            "authenticated": False,
            "error": str(e)
        }
