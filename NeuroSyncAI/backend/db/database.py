from motor.motor_asyncio import AsyncIOMotorClient
from functools import lru_cache
import logging
from typing import Optional

from config import get_settings

# Set up logging
logger = logging.getLogger(__name__)

class Database:
    client: Optional[AsyncIOMotorClient] = None
    db_name: str = None

    async def connect_to_database(self):
        """
        Create database connection with MongoDB using motor
        """
        settings = get_settings()
        
        if self.client is None:
            try:
                self.client = AsyncIOMotorClient(settings.MONGODB_URI)
                self.db_name = settings.MONGODB_DB_NAME
                
                # Log connection info (without credentials)
                logger.info(
                    f"Connected to MongoDB at {settings.MONGODB_URI.split('@')[-1]} "
                    f"using database '{self.db_name}'"
                )
            except Exception as e:
                logger.error(f"Failed to connect to MongoDB: {str(e)}")
                raise e

    async def close_database_connection(self):
        """
        Close database connection
        """
        if self.client is not None:
            self.client.close()
            self.client = None
            logger.info("MongoDB connection closed")

    def get_database(self):
        """
        Return database instance
        """
        if self.client is None:
            raise RuntimeError("Database client not initialized. Call connect_to_database first.")
        
        return self.client[self.db_name]

    def get_collection(self, collection_name: str):
        """
        Return a specific collection from the database
        """
        return self.get_database()[collection_name]


# Create a singleton instance of the database
db = Database()


# Dependency to get the MongoDB database
async def get_database():
    """
    Dependency that returns the MongoDB database instance
    """
    return db.get_database()


# Dependency to get a specific MongoDB collection
async def get_collection(collection_name: str):
    """
    Dependency that returns a specific MongoDB collection
    """
    return db.get_collection(collection_name)
