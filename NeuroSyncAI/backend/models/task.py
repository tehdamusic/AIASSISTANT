
from enum import Enum
from sqlalchemy import Column, String, Integer, Boolean, Enum as SQLAlchemyEnum
from sqlalchemy.orm import relationship
from ..db.database import Base

class RecurrenceEnum(str, Enum):
    NONE = "none"
    DAILY = "daily"
    WEEKLY = "weekly"
    MONTHLY = "monthly"

class Task(Base):
    __tablename__ = "tasks"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, index=True)
    description = Column(String, nullable=True)
    completed = Column(Boolean, default=False)
    recurrence = Column(SQLAlchemyEnum(RecurrenceEnum), default=RecurrenceEnum.NONE)  # New recurrence field


from enum import Enum
from datetime import datetime, timedelta
from sqlalchemy import Column, Integer, String, Boolean, DateTime, Enum as SAEnum, ForeignKey
from sqlalchemy.orm import relationship
from database import Base

class RecurrenceType(str, Enum):
    NONE = "none"
    DAILY = "daily"
    WEEKLY = "weekly"
    MONTHLY = "monthly"

class Task(Base):
    __tablename__ = "tasks"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, index=True)
    description = Column(String, nullable=True)
    due_date = Column(DateTime, nullable=True)
    completed = Column(Boolean, default=False)
    user_id = Column(Integer, ForeignKey("users.id"))
    recurrence = Column(SAEnum(RecurrenceType), default=RecurrenceType.NONE)

    user = relationship("User", back_populates="tasks")

    def recreate_task(self, session):
        if self.recurrence == RecurrenceType.NONE:
            return
        new_due_date = None
        if self.recurrence == RecurrenceType.DAILY:
            new_due_date = self.due_date + timedelta(days=1)
        elif self.recurrence == RecurrenceType.WEEKLY:
            new_due_date = self.due_date + timedelta(weeks=1)
        elif self.recurrence == RecurrenceType.MONTHLY:
            new_due_date = self.due_date + timedelta(weeks=4)  # Approximate monthly recurrence

        new_task = Task(
            title=self.title,
            description=self.description,
            due_date=new_due_date,
            completed=False,
            user_id=self.user_id,
            recurrence=self.recurrence,
        )
        session.add(new_task)
        session.commit()
