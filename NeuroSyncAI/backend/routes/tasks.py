
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from datetime import datetime, timedelta
from ..db.database import get_db
from ..models.task import Task, RecurrenceEnum
from ..schemas.task_schema import TaskCreate, TaskResponse

router = APIRouter()

@router.post("/tasks/", response_model=TaskResponse, summary="Create a new task with optional recurrence")
def create_task(task: TaskCreate, db: Session = Depends(get_db)):
    """Creates a new task. If recurrence is set, the task will be scheduled to reappear automatically."""
    new_task = Task(
        title=task.title,
        description=task.description,
        completed=False,
        recurrence=task.recurrence
    )
    db.add(new_task)
    db.commit()
    db.refresh(new_task)
    return new_task

@router.get("/tasks/recurring", summary="Generate recurring tasks automatically")
def process_recurring_tasks(db: Session = Depends(get_db)):
    """Checks for tasks that need to be recreated based on their recurrence type and generates them."""
    now = datetime.utcnow()
    tasks = db.query(Task).filter(Task.recurrence != RecurrenceEnum.NONE).all()

    for task in tasks:
        if task.recurrence == RecurrenceEnum.DAILY:
            next_due = now + timedelta(days=1)
        elif task.recurrence == RecurrenceEnum.WEEKLY:
            next_due = now + timedelta(weeks=1)
        elif task.recurrence == RecurrenceEnum.MONTHLY:
            next_due = now + timedelta(days=30)
        else:
            continue

        # Check if the task already exists for the next occurrence to prevent duplication
        existing_task = db.query(Task).filter(
            Task.title == task.title,
            Task.description == task.description,
            Task.recurrence == task.recurrence,
            Task.completed == False
        ).first()

        if not existing_task:
            new_task = Task(
                title=task.title,
                description=task.description,
                completed=False,
                recurrence=task.recurrence
            )
            db.add(new_task)

    db.commit()
    return {"message": "Recurring tasks processed successfully."}


from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from datetime import datetime
from database import get_db
from models.task import Task, RecurrenceType
from schemas.task import TaskCreate, TaskUpdate
from auth import get_current_user

router = APIRouter()

@router.post("/tasks/", response_model=Task)
def create_task(task: TaskCreate, db: Session = Depends(get_db), current_user=Depends(get_current_user)):
    new_task = Task(
        title=task.title,
        description=task.description,
        due_date=task.due_date,
        completed=False,
        user_id=current_user.id,
        recurrence=task.recurrence,
    )
    db.add(new_task)
    db.commit()
    db.refresh(new_task)
    return new_task

@router.put("/tasks/{task_id}/complete", response_model=Task)
def complete_task(task_id: int, db: Session = Depends(get_db), current_user=Depends(get_current_user)):
    task = db.query(Task).filter(Task.id == task_id, Task.user_id == current_user.id).first()
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")

    task.completed = True
    db.commit()

    # If the task is recurring, recreate it
    task.recreate_task(db)

    return task
