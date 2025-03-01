import logging
import time
from typing import Dict, List, Optional, Union, Any

from openai import OpenAI, APIError, RateLimitError, APIConnectionError
from config import get_settings

# Configure logging
logger = logging.getLogger(__name__)

class OpenAIService:
    """Service for interacting with OpenAI API"""
    
    def __init__(self):
        settings = get_settings()
        self.api_key = settings.OPENAI_API_KEY
        self.model = settings.OPENAI_MODEL
        self.client = OpenAI(api_key=self.api_key)
        
        # Log initialization without exposing API key
        logger.info(f"OpenAI service initialized with model: {self.model}")
    
    async def generate_response(
        self, 
        prompt: str, 
        system_prompt: str = "You are an assistant for people with ADHD. Keep responses clear, concise, and easy to follow.",
        max_retries: int = 3,
        temperature: float = 0.7
    ) -> str:
        """
        Generate a response from OpenAI based on the given prompt
        
        Args:
            prompt: The user prompt to generate a response for
            system_prompt: Instructions to guide the model's behavior
            max_retries: Maximum number of retry attempts on rate limit or connection error
            temperature: Controls randomness (0-1), lower is more deterministic
            
        Returns:
            Generated text response
            
        Raises:
            Exception: If the API call fails after all retries
        """
        messages = [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": prompt}
        ]
        
        retry_count = 0
        backoff_time = 1  # Initial backoff time in seconds
        
        while retry_count <= max_retries:
            try:
                logger.debug(f"Sending request to OpenAI API with prompt: {prompt[:50]}...")
                
                response = self.client.chat.completions.create(
                    model=self.model,
                    messages=messages,
                    temperature=temperature,
                )
                
                # Extract the response text
                response_text = response.choices[0].message.content
                logger.debug(f"Received response from OpenAI API: {response_text[:50]}...")
                
                return response_text
                
            except RateLimitError as e:
                retry_count += 1
                if retry_count > max_retries:
                    logger.error(f"Rate limit exceeded after {max_retries} retries: {str(e)}")
                    raise Exception(f"OpenAI API rate limit exceeded: {str(e)}")
                
                logger.warning(f"Rate limit error, retrying in {backoff_time} seconds...")
                time.sleep(backoff_time)
                backoff_time *= 2  # Exponential backoff
                
            except APIConnectionError as e:
                retry_count += 1
                if retry_count > max_retries:
                    logger.error(f"Connection error after {max_retries} retries: {str(e)}")
                    raise Exception(f"OpenAI API connection error: {str(e)}")
                
                logger.warning(f"Connection error, retrying in {backoff_time} seconds...")
                time.sleep(backoff_time)
                backoff_time *= 2
                
            except APIError as e:
                logger.error(f"OpenAI API error: {str(e)}")
                raise Exception(f"OpenAI API error: {str(e)}")
                
            except Exception as e:
                logger.error(f"Unexpected error when calling OpenAI API: {str(e)}")
                raise Exception(f"Error generating response: {str(e)}")
    
    async def analyze_task(self, task_title: str, task_description: Optional[str] = None) -> Dict[str, Any]:
        """
        Analyze a task to extract relevant ADHD-friendly information
        
        Args:
            task_title: The title of the task
            task_description: Optional detailed description of the task
            
        Returns:
            Dictionary with analysis results (estimated_time, difficulty, etc.)
        """
        prompt = f"Task: {task_title}\n"
        if task_description:
            prompt += f"Description: {task_description}\n"
            
        prompt += """
        Please analyze this task for someone with ADHD. Provide:
        1. Estimated time to complete (in minutes)
        2. Difficulty level (easy, medium, hard)
        3. Suggested breakdown into smaller steps
        4. Potential obstacles
        
        Return your response as a JSON object with the following keys:
        estimated_time_minutes, difficulty, steps (array), potential_obstacles (array)
        """
        
        try:
            response = await self.generate_response(prompt, temperature=0.3)
            
            # In a real implementation, you would parse the JSON here
            # For now, we'll just return a mock structure
            # This would be replaced with actual parsing of the response
            
            # Mock return - in reality would parse the response
            analysis = {
                "estimated_time_minutes": 30,
                "difficulty": "medium",
                "steps": [
                    "Step 1: Gather materials",
                    "Step 2: Start with the easiest part",
                    "Step 3: Take a short break",
                    "Step 4: Complete the remaining work"
                ],
                "potential_obstacles": [
                    "Distractions from notifications",
                    "Task switching",
                    "Losing focus after 15 minutes"
                ]
            }
            
            return analysis
            
        except Exception as e:
            logger.error(f"Error analyzing task: {str(e)}")
            raise Exception(f"Error analyzing task: {str(e)}")

# Create a singleton instance
openai_service = OpenAIService()
