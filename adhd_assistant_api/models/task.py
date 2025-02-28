from typing import Optional
from datetime import datetime
from enum import Enum
from pydantic import BaseModel, Field
from bson import ObjectId

# Custom type for MongoDB ObjectId handling
class PyObjectId(ObjectId):
    @classmethod
    def __get_validators__(cls):
        yield cls.validate

    @classmethod
    def validate(cls, v):
        if not ObjectId.is_valid(v):
            raise ValueError("Invalid ObjectId")
        return ObjectId(v)

    @classmethod
    def __modify_schema__(cls, field_schema):
        field_schema.update(type="string")


class TaskPriority(str, Enum):
    """Enum for task priority levels"""
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"


class TaskBase(BaseModel):
    """Base Task model with common fields"""
    title: str
    completed: bool = False
    due_date: Optional[datetime] = None
    priority: TaskPriority = TaskPriority.MEDIUM
    description: Optional[str] = None
    tags: list[str] = Field(default_factory=list)


class TaskCreate(TaskBase):
    """Task model for creation"""
    user_id: str  # Will be converted to ObjectId


class TaskInDB(TaskBase):
    """Task model as stored in database"""
    id: PyObjectId = Field(default_factory=PyObjectId, alias="_id")
    user_id: PyObjectId
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    
    class Config:
        allow_population_by_field_name = True
        arbitrary_types_allowed = True
        json_encoders = {
            ObjectId: str,
            datetime: lambda dt: dt.isoformat()
        }
        schema_extra = {
            "example": {
                "_id": "60d5ec9af3a6b9d4b1f7b1f8",
                "title": "Finish project report",
                "completed": False,
                "due_date": "2023-04-15T17:00:00",
                "priority": "high",
                "description": "Complete the quarterly project report",
                "tags": ["work", "report", "quarterly"],
                "user_id": "60d5ec9af3a6b9d4b1f7b1f7",
                "created_at": "2023-04-10T10:30:00",
                "updated_at": "2023-04-10T10:30:00"
            }
        }


class Task(TaskBase):
    """Task model for response"""
    id: str = Field(alias="_id")
    user_id: str
    created_at: datetime
    updated_at: datetime
    
    class Config:
        allow_population_by_field_name = True
        arbitrary_types_allowed = True
        schema_extra = {
            "example": {
                "_id": "60d5ec9af3a6b9d4b1f7b1f8",
                "title": "Finish project report",
                "completed": False,
                "due_date": "2023-04-15T17:00:00",
                "priority": "high",
                "description": "Complete the quarterly project report",
                "tags": ["work", "report", "quarterly"],
                "user_id": "60d5ec9af3a6b9d4b1f7b1f7",
                "created_at": "2023-04-10T10:30:00",
                "updated_at": "2023-04-10T10:30:00"
            }
        }


class TaskUpdate(BaseModel):
    """Task model for update operations"""
    title: Optional[str] = None
    completed: Optional[bool] = None
    due_date: Optional[datetime] = None
    priority: Optional[TaskPriority] = None
    description: Optional[str] = None
    tags: Optional[list[str]] = None
    
    class Config:
        arbitrary_types_allowed = True
        schema_extra = {
            "example": {
                "title": "Finish project report (updated)",
                "completed": True,
                "priority": "medium",
                "tags": ["work", "report", "completed"]
            }
        }
