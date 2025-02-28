from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.responses import JSONResponse
from bson import ObjectId
from typing import List
from datetime import datetime
import logging

from db.database import get_collection
from models.task import Task, TaskCreate, TaskUpdate, TaskInDB
from services.openai_service import openai_service

# Configure logging
logger = logging.getLogger(__name__)

# Create the router
router = APIRouter(
    prefix="/tasks",
    tags=["tasks"],
    responses={404: {"description": "Not found"}},
)

@router.get("/{user_id}", response_model=List[Task])
async def get_tasks(
    user_id: str, 
    completed: bool = None,
    tasks_collection = Depends(lambda: get_collection("tasks"))
):
    """
    Retrieve all tasks for a specific user.
    
    Args:
        user_id: The ID of the user to fetch tasks for
        completed: Optional filter for completed status
        
    Returns:
        List of Task objects
    """
    try:
        # Validate that user_id is a valid ObjectId
        if not ObjectId.is_valid(user_id):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid user ID format"
            )
            
        # Create filter query
        query = {"user_id": ObjectId(user_id)}
        
        # Add completed filter if provided
        if completed is not None:
            query["completed"] = completed
        
        # Execute query
        cursor = tasks_collection.find(query)
        
        # Convert cursor to list of Task models
        tasks = []
        async for document in cursor:
            # Convert ObjectIds to strings for response
            document["_id"] = str(document["_id"])
            document["user_id"] = str(document["user_id"])
            tasks.append(document)
        
        return tasks
        
    except Exception as e:
        logger.error(f"Error fetching tasks: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error fetching tasks: {str(e)}"
        )

@router.post("/", response_model=Task, status_code=status.HTTP_201_CREATED)
async def create_task(
    task: TaskCreate,
    tasks_collection = Depends(lambda: get_collection("tasks"))
):
    """
    Create a new task.
    
    Args:
        task: TaskCreate model with task details
        
    Returns:
        Newly created Task
    """
    try:
        # Validate that user_id is a valid ObjectId
        if not ObjectId.is_valid(task.user_id):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid user ID format"
            )
        
        # Prepare the task for database insertion
        task_dict = task.dict()
        task_dict["user_id"] = ObjectId(task.user_id)
        task_dict["created_at"] = datetime.utcnow()
        task_dict["updated_at"] = task_dict["created_at"]
        
        # Optional: Analyze task with OpenAI
        if task.title:
            try:
                analysis = await openai_service.analyze_task(
                    task.title, 
                    task.description if hasattr(task, "description") else None
                )
                # Add analysis results to task
                task_dict["ai_analysis"] = analysis
            except Exception as e:
                # Log but don't fail if AI analysis fails
                logger.warning(f"AI task analysis failed: {str(e)}")
        
        # Insert the task
        result = await tasks_collection.insert_one(task_dict)
        
        # Check if insertion was successful
        if not result.inserted_id:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to create task"
            )
        
        # Fetch the inserted task to return
        created_task = await tasks_collection.find_one({"_id": result.inserted_id})
        
        # Convert ObjectIds to strings for response
        created_task["_id"] = str(created_task["_id"])
        created_task["user_id"] = str(created_task["user_id"])
        
        return created_task
        
    except HTTPException:
        # Re-raise HTTP exceptions
        raise
    except Exception as e:
        logger.error(f"Error creating task: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error creating task: {str(e)}"
        )

@router.get("/{task_id}", response_model=Task)
async def get_task(
    task_id: str,
    tasks_collection = Depends(lambda: get_collection("tasks"))
):
    """
    Retrieve a specific task by ID.
    
    Args:
        task_id: The ID of the task to retrieve
        
    Returns:
        Task object if found
    """
    try:
        # Validate task_id format
        if not ObjectId.is_valid(task_id):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid task ID format"
            )
        
        # Find the task
        task = await tasks_collection.find_one({"_id": ObjectId(task_id)})
        
        # Check if task exists
        if not task:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Task with ID {task_id} not found"
            )
        
        # Convert ObjectIds to strings for response
        task["_id"] = str(task["_id"])
        task["user_id"] = str(task["user_id"])
        
        return task
        
    except HTTPException:
        # Re-raise HTTP exceptions
        raise
    except Exception as e:
        logger.error(f"Error fetching task: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error fetching task: {str(e)}"
        )

@router.put("/{task_id}", response_model=Task)
async def update_task(
    task_id: str,
    task_update: TaskUpdate,
    tasks_collection = Depends(lambda: get_collection("tasks"))
):
    """
    Update an existing task.
    
    Args:
        task_id: The ID of the task to update
        task_update: TaskUpdate model with fields to update
        
    Returns:
        Updated Task object
    """
    try:
        # Validate task_id format
        if not ObjectId.is_valid(task_id):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid task ID format"
            )
        
        # Prepare update data
        update_data = task_update.dict(exclude_unset=True)
        
        # Add updated_at timestamp
        update_data["updated_at"] = datetime.utcnow()
        
        # If there's nothing to update
        if not update_data:
            # Just fetch and return the current task
            current_task = await tasks_collection.find_one({"_id": ObjectId(task_id)})
            if not current_task:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail=f"Task with ID {task_id} not found"
                )
            
            # Convert ObjectIds to strings for response
            current_task["_id"] = str(current_task["_id"])
            current_task["user_id"] = str(current_task["user_id"])
            
            return current_task
        
        # Update the task
        result = await tasks_collection.update_one(
            {"_id": ObjectId(task_id)},
            {"$set": update_data}
        )
        
        # Check if task was found and updated
        if result.matched_count == 0:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Task with ID {task_id} not found"
            )
        
        # Fetch and return the updated task
        updated_task = await tasks_collection.find_one({"_id": ObjectId(task_id)})
        
        # Convert ObjectIds to strings for response
        updated_task["_id"] = str(updated_task["_id"])
        updated_task["user_id"] = str(updated_task["user_id"])
        
        return updated_task
        
    except HTTPException:
        # Re-raise HTTP exceptions
        raise
    except Exception as e:
        logger.error(f"Error updating task: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error updating task: {str(e)}"
        )

@router.delete("/{task_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_task(
    task_id: str,
    tasks_collection = Depends(lambda: get_collection("tasks"))
):
    """
    Delete a task.
    
    Args:
        task_id: The ID of the task to delete
        
    Returns:
        204 No Content on success
    """
    try:
        # Validate task_id format
        if not ObjectId.is_valid(task_id):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid task ID format"
            )
        
        # Delete the task
        result = await tasks_collection.delete_one({"_id": ObjectId(task_id)})
        
        # Check if task was found and deleted
        if result.deleted_count == 0:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Task with ID {task_id} not found"
            )
        
        # Return no content
        return JSONResponse(status_code=status.HTTP_204_NO_CONTENT)
        
    except HTTPException:
        # Re-raise HTTP exceptions
        raise
    except Exception as e:
        logger.error(f"Error deleting task: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error deleting task: {str(e)}"
        )
