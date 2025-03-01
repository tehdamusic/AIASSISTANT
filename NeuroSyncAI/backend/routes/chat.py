from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime
import logging
from bson import ObjectId

from services.openai_service import openai_service
from db.database import get_collection

# Configure logging
logger = logging.getLogger(__name__)

# Create the router
router = APIRouter(
    prefix="/chat",
    tags=["chat"],
    responses={404: {"description": "Not found"}},
)

# Request/Response models
class ChatMessage(BaseModel):
    """Model for chat messages"""
    message: str
    user_id: Optional[str] = None
    context: Optional[dict] = None


class ChatResponse(BaseModel):
    """Model for chat responses"""
    response: str
    conversation_id: Optional[str] = None
    timestamp: datetime = datetime.utcnow()


class ConversationHistory(BaseModel):
    """Model for storing conversation history"""
    user_id: str
    messages: List[dict]  # List of message objects with role, content, timestamp
    created_at: datetime = datetime.utcnow()
    updated_at: datetime = datetime.utcnow()


@router.post("", response_model=ChatResponse)
async def chat_endpoint(
    chat_message: ChatMessage,
    conversations_collection = Depends(lambda: get_collection("conversations"))
):
    """
    Process a chat message and return an AI-generated response.
    
    Args:
        chat_message: The user's message and optional context
        
    Returns:
        AI-generated response
    """
    try:
        user_id = chat_message.user_id
        user_message = chat_message.message
        context = chat_message.context or {}
        
        # Prepare response object
        chat_response = ChatResponse(
            response="",
            timestamp=datetime.utcnow()
        )
        
        # Track conversation if user_id is provided
        conversation_id = None
        conversation = None
        
        if user_id:
            # Find existing conversation or create new one
            if ObjectId.is_valid(user_id):
                # Find the most recent conversation for this user
                conversation = await conversations_collection.find_one(
                    {"user_id": user_id},
                    sort=[("updated_at", -1)]
                )
                
                # If no conversation exists or it's older than 6 hours, create a new one
                current_time = datetime.utcnow()
                
                if (not conversation or
                    (current_time - conversation["updated_at"]).total_seconds() > 6 * 3600):
                    
                    # Create a new conversation
                    new_conversation = {
                        "user_id": user_id,
                        "messages": [],
                        "created_at": current_time,
                        "updated_at": current_time
                    }
                    
                    result = await conversations_collection.insert_one(new_conversation)
                    conversation_id = result.inserted_id
                    conversation = await conversations_collection.find_one({"_id": conversation_id})
                else:
                    conversation_id = conversation["_id"]
        
        # Fetch conversation history if available
        conversation_history = []
        custom_system_prompt = None
        
        if conversation and "messages" in conversation:
            # Get last few messages for context (limit to recent messages)
            conversation_history = conversation["messages"][-10:]  # Last 10 messages
            
            # Build conversation context
            system_prompt = context.get("system_prompt", None)
            if system_prompt:
                custom_system_prompt = system_prompt
        
        # Build message history for AI context
        formatted_history = []
        
        # Add system prompt if provided in context, otherwise use default
        if custom_system_prompt:
            formatted_history.append(f"System: {custom_system_prompt}")
        
        # Add conversation history
        for msg in conversation_history:
            role = "User" if msg["role"] == "user" else "Assistant"
            formatted_history.append(f"{role}: {msg['content']}")
        
        # Prepare the prompt with history if available
        final_prompt = user_message
        
        if formatted_history:
            history_text = "\n".join(formatted_history)
            final_prompt = f"Conversation history:\n{history_text}\n\nUser's new message: {user_message}\n\nRespond to the user's new message with the conversation history in mind."
        
        # Generate response from OpenAI
        ai_response = await openai_service.generate_response(
            final_prompt,
            system_prompt=custom_system_prompt if custom_system_prompt else None,
            temperature=context.get("temperature", 0.7)
        )
        
        # Update conversation with the new messages if tracking
        if conversation_id:
            # Add user message
            await conversations_collection.update_one(
                {"_id": conversation_id},
                {
                    "$push": {
                        "messages": {
                            "role": "user",
                            "content": user_message,
                            "timestamp": datetime.utcnow()
                        }
                    },
                    "$set": {"updated_at": datetime.utcnow()}
                }
            )
            
            # Add assistant response
            await conversations_collection.update_one(
                {"_id": conversation_id},
                {
                    "$push": {
                        "messages": {
                            "role": "assistant",
                            "content": ai_response,
                            "timestamp": datetime.utcnow()
                        }
                    },
                    "$set": {"updated_at": datetime.utcnow()}
                }
            )
            
            # Convert ObjectId to string for response
            chat_response.conversation_id = str(conversation_id)
        
        # Set the response
        chat_response.response = ai_response
        
        return chat_response
        
    except Exception as e:
        logger.error(f"Error in chat endpoint: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error generating response: {str(e)}"
        )


@router.get("/history/{user_id}", response_model=List[dict])
async def get_chat_history(
    user_id: str,
    limit: int = 50,
    conversations_collection = Depends(lambda: get_collection("conversations"))
):
    """
    Retrieve chat history for a user.
    
    Args:
        user_id: The ID of the user to fetch chat history for
        limit: Maximum number of messages to return
        
    Returns:
        List of chat messages
    """
    try:
        # Validate user_id format
        if not ObjectId.is_valid(user_id):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid user ID format"
            )
        
        # Find the most recent conversation
        conversation = await conversations_collection.find_one(
            {"user_id": user_id},
            sort=[("updated_at", -1)]
        )
        
        if not conversation:
            return []
        
        # Get messages and limit to requested amount
        messages = conversation.get("messages", [])[-limit:]
        
        # Format messages for response
        formatted_messages = []
        for msg in messages:
            formatted_messages.append({
                "role": msg["role"],
                "content": msg["content"],
                "timestamp": msg["timestamp"]
            })
        
        return formatted_messages
        
    except HTTPException:
        # Re-raise HTTP exceptions
        raise
    except Exception as e:
        logger.error(f"Error fetching chat history: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error fetching chat history: {str(e)}"
        )


@router.delete("/history/{user_id}", status_code=status.HTTP_204_NO_CONTENT)
async def clear_chat_history(
    user_id: str,
    conversations_collection = Depends(lambda: get_collection("conversations"))
):
    """
    Clear chat history for a user.
    
    Args:
        user_id: The ID of the user to clear chat history for
        
    Returns:
        204 No Content on success
    """
    try:
        # Validate user_id format
        if not ObjectId.is_valid(user_id):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid user ID format"
            )
        
        # Delete all conversations for this user
        await conversations_collection.delete_many({"user_id": user_id})
        
        return None
        
    except HTTPException:
        # Re-raise HTTP exceptions
        raise
    except Exception as e:
        logger.error(f"Error clearing chat history: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error clearing chat history: {str(e)}"
        )
