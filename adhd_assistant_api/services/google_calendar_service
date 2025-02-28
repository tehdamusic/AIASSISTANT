import os
import json
import logging
import time
from typing import Dict, List, Optional, Any
from datetime import datetime, timedelta

from google.oauth2.credentials import Credentials
from google.auth.transport.requests import Request
from google.auth.exceptions import RefreshError
from google_auth_oauthlib.flow import Flow
from googleapiclient.discovery import build
from googleapiclient.errors import HttpError
from bson.objectid import ObjectId

from config import get_settings
from db.database import get_collection

# Configure logging
logger = logging.getLogger(__name__)

# Scopes required for Google Calendar
SCOPES = [
    'https://www.googleapis.com/auth/calendar.readonly',
    'https://www.googleapis.com/auth/calendar.events'
]


class GoogleCalendarService:
    """Service for interacting with Google Calendar API"""
    
    def __init__(self):
        self.settings = get_settings()
        self.client_secret_file = os.path.join(os.getcwd(), 'client_secret.json')
        
        # Verify that client_secret.json exists
        if not os.path.exists(self.client_secret_file):
            logger.warning(f"Google client secret file not found at {self.client_secret_file}")
    
    def get_flow(self, redirect_uri: str) -> Flow:
        """
        Create an OAuth2 flow instance to manage the OAuth 2.0 Authorization Grant Flow.
        
        Args:
            redirect_uri: The URI to redirect to after the authorization is complete
            
        Returns:
            Flow instance configured with the client secrets file
        """
        try:
            flow = Flow.from_client_secrets_file(
                self.client_secret_file,
                scopes=SCOPES,
                redirect_uri=redirect_uri
            )
            return flow
        except Exception as e:
            logger.error(f"Error creating OAuth2 flow: {str(e)}")
            raise
    
    async def authenticate_google(self, user_id: str, redirect_uri: str) -> Dict[str, str]:
        """
        Start the Google OAuth2 authentication process.
        
        Args:
            user_id: The ID of the user to authenticate
            redirect_uri: The URI to redirect to after authorization
            
        Returns:
            Dict containing the authorization URL and state
        """
        try:
            # Create the flow using the client secrets file
            flow = self.get_flow(redirect_uri)
            
            # Generate the authorization URL
            authorization_url, state = flow.authorization_url(
                # Enable offline access to get a refresh token
                access_type='offline',
                # Force approval prompt to ensure getting refresh token every time
                prompt='consent',
                # Include the user ID in the state for verification
                state=user_id
            )
            
            return {
                "authorization_url": authorization_url,
                "state": state
            }
        except Exception as e:
            logger.error(f"Error generating Google authorization URL: {str(e)}")
            raise ValueError(f"Failed to generate Google authorization URL: {str(e)}")
    
    async def store_google_tokens(
        self, 
        user_id: str, 
        auth_code: str, 
        redirect_uri: str,
        state: str
    ) -> Dict[str, Any]:
        """
        Exchange authorization code for access and refresh tokens and store them.
        
        Args:
            user_id: The ID of the user
            auth_code: The authorization code returned by Google
            redirect_uri: The redirect URI used in the initial request
            state: The state parameter from the authorization response
            
        Returns:
            Dict with token details and status
        """
        try:
            # Verify that the state matches the user_id
            if not state or user_id not in state:
                raise ValueError("Invalid state parameter")
            
            # Create the flow using the client secrets file
            flow = self.get_flow(redirect_uri)
            
            # Exchange authorization code for access and refresh tokens
            flow.fetch_token(code=auth_code)
            
            # Get credentials from flow
            credentials = flow.credentials
            
            # Prepare tokens for storage
            token_data = {
                "token": credentials.token,
                "refresh_token": credentials.refresh_token,
                "token_uri": credentials.token_uri,
                "client_id": credentials.client_id,
                "client_secret": credentials.client_secret,
                "scopes": credentials.scopes,
                "expiry": credentials.expiry.isoformat() if credentials.expiry else None
            }
            
            # Store tokens in the database
            tokens_collection = await get_collection("google_tokens")
            
            # Check if tokens already exist for this user
            existing_tokens = await tokens_collection.find_one({"user_id": user_id})
            
            if existing_tokens:
                # Update existing tokens
                await tokens_collection.update_one(
                    {"user_id": user_id},
                    {
                        "$set": {
                            "tokens": token_data,
                            "updated_at": datetime.utcnow()
                        }
                    }
                )
            else:
                # Insert new tokens
                await tokens_collection.insert_one({
                    "user_id": user_id,
                    "tokens": token_data,
                    "created_at": datetime.utcnow(),
                    "updated_at": datetime.utcnow()
                })
            
            return {
                "status": "success",
                "message": "Google Calendar access tokens stored successfully",
                "expires_at": credentials.expiry.isoformat() if credentials.expiry else None
            }
            
        except Exception as e:
            logger.error(f"Error storing Google access tokens: {str(e)}")
            raise ValueError(f"Failed to store Google access tokens: {str(e)}")
    
    async def get_credentials(self, user_id: str) -> Optional[Credentials]:
        """
        Retrieve and refresh Google OAuth credentials for a user.
        
        Args:
            user_id: The ID of the user
            
        Returns:
            Google OAuth credentials if available, None otherwise
        """
        try:
            # Get tokens from database
            tokens_collection = await get_collection("google_tokens")
            token_doc = await tokens_collection.find_one({"user_id": user_id})
            
            if not token_doc or "tokens" not in token_doc:
                logger.warning(f"No Google tokens found for user {user_id}")
                return None
            
            # Extract token data
            token_data = token_doc["tokens"]
            
            # Parse expiry if it exists
            if token_data.get("expiry"):
                token_data["expiry"] = datetime.fromisoformat(token_data["expiry"])
            
            # Create credentials object
            credentials = Credentials(
                token=token_data.get("token"),
                refresh_token=token_data.get("refresh_token"),
                token_uri=token_data.get("token_uri"),
                client_id=token_data.get("client_id"),
                client_secret=token_data.get("client_secret"),
                scopes=token_data.get("scopes")
            )
            
            # Check if token is expired and needs refreshing
            if not credentials.valid:
                try:
                    logger.info(f"Refreshing expired Google token for user {user_id}")
                    request = Request()
                    credentials.refresh(request)
                    
                    # Update the refreshed token in the database
                    token_data = {
                        "token": credentials.token,
                        "refresh_token": credentials.refresh_token,
                        "token_uri": credentials.token_uri,
                        "client_id": credentials.client_id,
                        "client_secret": credentials.client_secret,
                        "scopes": credentials.scopes,
                        "expiry": credentials.expiry.isoformat() if credentials.expiry else None
                    }
                    
                    await tokens_collection.update_one(
                        {"user_id": user_id},
                        {
                            "$set": {
                                "tokens": token_data,
                                "updated_at": datetime.utcnow()
                            }
                        }
                    )
                    
                    logger.info(f"Successfully refreshed token for user {user_id}")
                except RefreshError as refresh_error:
                    logger.error(f"Token refresh failed for user {user_id}: {str(refresh_error)}")
                    
                    # Mark the token as requiring re-authentication
                    await tokens_collection.update_one(
                        {"user_id": user_id},
                        {
                            "$set": {
                                "requires_reauth": True,
                                "reauth_reason": str(refresh_error),
                                "updated_at": datetime.utcnow()
                            }
                        }
                    )
                    return None
                except Exception as e:
                    logger.error(f"Error refreshing token for user {user_id}: {str(e)}")
                    return None
            
            return credentials
            
        except Exception as e:
            logger.error(f"Error retrieving Google credentials: {str(e)}")
            return None
    
    async def check_auth_status(self, user_id: str) -> Dict[str, Any]:
        """
        Check the authentication status for a user.
        
        Args:
            user_id: The ID of the user
            
        Returns:
            Dict with authentication status and details
        """
        try:
            # Get tokens collection
            tokens_collection = await get_collection("google_tokens")
            token_doc = await tokens_collection.find_one({"user_id": user_id})
            
            if not token_doc:
                return {
                    "authenticated": False,
                    "reason": "No tokens found"
                }
            
            # Check if re-authentication is required
            if token_doc.get("requires_reauth", False):
                return {
                    "authenticated": False,
                    "reason": "Refresh token expired or revoked",
                    "reauth_reason": token_doc.get("reauth_reason", "Unknown reason")
                }
            
            # Try to get valid credentials
            credentials = await self.get_credentials(user_id)
            
            if not credentials:
                return {
                    "authenticated": False,
                    "reason": "Could not retrieve valid credentials"
                }
            
            return {
                "authenticated": True,
                "expires_at": credentials.expiry.isoformat() if credentials.expiry else None,
                "scopes": credentials.scopes
            }
            
        except Exception as e:
            logger.error(f"Error checking auth status for user {user_id}: {str(e)}")
            return {
                "authenticated": False,
                "reason": f"Error checking auth status: {str(e)}"
            }
    
    async def list_calendars(self, user_id: str) -> List[Dict[str, Any]]:
        """
        List all calendars for a user.
        
        Args:
            user_id: The ID of the user
            
        Returns:
            List of calendar details
        """
        try:
            # Get credentials
            credentials = await self.get_credentials(user_id)
            
            if not credentials:
                raise ValueError("Google Calendar not authenticated")
            
            # Build the service
            service = build('calendar', 'v3', credentials=credentials)
            
            # Get list of calendars
            calendar_list = service.calendarList().list().execute()
            
            # Extract and return relevant calendar details
            calendars = []
            for calendar in calendar_list.get('items', []):
                calendars.append({
                    "id": calendar['id'],
                    "summary": calendar['summary'],
                    "description": calendar.get('description', ''),
                    "primary": calendar.get('primary', False)
                })
            
            return calendars
            
        except HttpError as e:
            error_content = json.loads(e.content.decode('utf-8'))
            logger.error(f"Google API error: {error_content}")
            
            # Handle specific error cases
            if e.resp.status == 401:
                # Store the authentication failure
                try:
                    tokens_collection = await get_collection("google_tokens")
                    await tokens_collection.update_one(
                        {"user_id": user_id},
                        {
                            "$set": {
                                "requires_reauth": True,
                                "reauth_reason": "Authentication failed: Token invalid or expired",
                                "updated_at": datetime.utcnow()
                            }
                        }
                    )
                except Exception as db_error:
                    logger.error(f"Error updating auth status: {str(db_error)}")
                
                raise ValueError("Authentication failed. Please reconnect your Google Calendar.")
            
            raise ValueError(f"Google Calendar API error: {error_content.get('error', {}).get('message', str(e))}")
        except Exception as e:
            logger.error(f"Error listing calendars: {str(e)}")
            raise ValueError(f"Failed to list calendars: {str(e)}")
    
    async def get_events(
        self, 
        user_id: str, 
        calendar_id: str = 'primary',
        time_min: Optional[datetime] = None,
        time_max: Optional[datetime] = None,
        max_results: int = 10
    ) -> List[Dict[str, Any]]:
        """
        Get events from a specific calendar.
        
        Args:
            user_id: The ID of the user
            calendar_id: The ID of the calendar (default: 'primary')
            time_min: Start time for events (default: now)
            time_max: End time for events (default: 7 days from now)
            max_results: Maximum number of events to return
            
        Returns:
            List of event details
        """
        try:
            # Get credentials with retry logic for token refresh
            retry_count = 0
            max_retries = 2
            credentials = None
            
            while retry_count <= max_retries:
                credentials = await self.get_credentials(user_id)
                if credentials:
                    break
                    
                retry_count += 1
                if retry_count <= max_retries:
                    logger.info(f"Retrying credential retrieval (attempt {retry_count}/{max_retries})")
                    time.sleep(1)  # Short delay before retry
            
            if not credentials:
                raise ValueError("Google Calendar not authenticated")
            
            # Build the service
            service = build('calendar', 'v3', credentials=credentials)
            
            # Set default time range if not provided
            if time_min is None:
                time_min = datetime.utcnow()
            if time_max is None:
                time_max = time_min + timedelta(days=7)
            
            # Format times for API
            time_min_str = time_min.isoformat() + 'Z'  # Z indicates UTC
            time_max_str = time_max.isoformat() + 'Z'
            
            # Get events
            events_result = service.events().list(
                calendarId=calendar_id,
                timeMin=time_min_str,
                timeMax=time_max_str,
                maxResults=max_results,
                singleEvents=True,
                orderBy='startTime'
            ).execute()
            
            # Extract and return relevant event details
            events = []
            for event in events_result.get('items', []):
                start = event['start'].get('dateTime', event['start'].get('date'))
                end = event['end'].get('dateTime', event['end'].get('date'))
                
                events.append({
                    "id": event['id'],
                    "summary": event.get('summary', 'No Title'),
                    "description": event.get('description', ''),
                    "start": start,
                    "end": end,
                    "location": event.get('location', ''),
                    "html_link": event.get('htmlLink', '')
                })
            
            return events
            
        except HttpError as e:
            error_content = json.loads(e.content.decode('utf-8'))
            logger.error(f"Google API error: {error_content}")
            
            # Handle authentication errors
            if e.resp.status == 401:
                try:
                    tokens_collection = await get_collection("google_tokens")
                    await tokens_collection.update_one(
                        {"user_id": user_id},
                        {
                            "$set": {
                                "requires_reauth": True,
                                "reauth_reason": "Authentication failed when fetching events",
                                "updated_at": datetime.utcnow()
                            }
                        }
                    )
                except Exception as db_error:
                    logger.error(f"Error updating auth status: {str(db_error)}")
                
                raise ValueError("Authentication failed. Please reconnect your Google Calendar.")
            
            raise ValueError(f"Google Calendar API error: {error_content.get('error', {}).get('message', str(e))}")
        except Exception as e:
            logger.error(f"Error getting events: {str(e)}")
            raise ValueError(f"Failed to get events: {str(e)}")
    
    async def create_event(
        self, 
        user_id: str, 
        calendar_id: str = 'primary',
        summary: str = '',
        description: str = '',
        location: str = '',
        start_time: datetime = None,
        end_time: datetime = None,
        attendees: List[str] = None,
        reminders: Dict[str, Any] = None
    ) -> Dict[str, Any]:
        """
        Create a new event in the calendar.
        
        Args:
            user_id: The ID of the user
            calendar_id: The ID of the calendar (default: 'primary')
            summary: Event title
            description: Event description
            location: Event location
            start_time: Start time (required)
            end_time: End time (required)
            attendees: List of email addresses for attendees
            reminders: Reminder settings
            
        Returns:
            Created event details
        """
        try:
            # Validate required parameters
            if not start_time or not end_time:
                raise ValueError("Start time and end time are required")
            
            # Get credentials with retry logic
            retry_count = 0
            max_retries = 2
            credentials = None
            
            while retry_count <= max_retries:
                credentials = await self.get_credentials(user_id)
                if credentials:
                    break
                    
                retry_count += 1
                if retry_count <= max_retries:
                    logger.info(f"Retrying credential retrieval (attempt {retry_count}/{max_retries})")
                    time.sleep(1)  # Short delay before retry
            
            if not credentials:
                raise ValueError("Google Calendar not authenticated")
            
            # Build the service
            service = build('calendar', 'v3', credentials=credentials)
            
            # Prepare attendees list if provided
            attendees_list = None
            if attendees:
                attendees_list = [{'email': email} for email in attendees]
            
            # Prepare reminder settings or use defaults
            if not reminders:
                reminders = {
                    'useDefault': True
                }
            
            # Format times for API
            start_time_str = start_time.isoformat()
            end_time_str = end_time.isoformat()
            
            # Create event
            event = {
                'summary': summary,
                'location': location,
                'description': description,
                'start': {
                    'dateTime': start_time_str,
                    'timeZone': 'UTC',
                },
                'end': {
                    'dateTime': end_time_str,
                    'timeZone': 'UTC',
                },
                'reminders': reminders,
            }
            
            # Add attendees if provided
            if attendees_list:
                event['attendees'] = attendees_list
            
            # Create the event
            created_event = service.events().insert(
                calendarId=calendar_id,
                body=event
            ).execute()
            
            return {
                "id": created_event['id'],
                "summary": created_event.get('summary', 'No Title'),
                "description": created_event.get('description', ''),
                "start": created_event['start'].get('dateTime', created_event['start'].get('date')),
                "end": created_event['end'].get('dateTime', created_event['end'].get('date')),
                "location": created_event.get('location', ''),
                "html_link": created_event.get('htmlLink', '')
            }
            
        except HttpError as e:
            error_content = json.loads(e.content.decode('utf-8'))
            logger.error(f"Google API error: {error_content}")
            
            # Handle authentication errors
            if e.resp.status == 401:
                try:
                    tokens_collection = await get_collection("google_tokens")
                    await tokens_collection.update_one(
                        {"user_id": user_id},
                        {
                            "$set": {
                                "requires_reauth": True,
                                "reauth_reason": "Authentication failed when creating event",
                                "updated_at": datetime.utcnow()
                            }
                        }
                    )
                except Exception as db_error:
                    logger.error(f"Error updating auth status: {str(db_error)}")
                
                raise ValueError("Authentication failed. Please reconnect your Google Calendar.")
            
            raise ValueError(f"Google Calendar API error: {error_content.get('error', {}).get('message', str(e))}")
        except Exception as e:
            logger.error(f"Error creating event: {str(e)}")
            raise ValueError(f"Failed to create event: {str(e)}")


# Create a singleton instance
google_calendar_service = GoogleCalendarService()
