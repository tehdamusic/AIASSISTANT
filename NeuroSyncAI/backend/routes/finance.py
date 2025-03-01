from fastapi import APIRouter, Depends, HTTPException, status, Query
from pydantic import BaseModel, Field
from typing import List, Dict, Optional, Any
from datetime import datetime, timedelta
from bson import ObjectId
import logging

from services.banking_service import banking_service
from db.database import get_collection

# Configure logging
logger = logging.getLogger(__name__)

# Create the router
router = APIRouter(
    prefix="/finance",
    tags=["finance"],
    responses={404: {"description": "Not found"}},
)

# Pydantic models for request/response validation
class BudgetItem(BaseModel):
    """Budget item for a specific category"""
    category: str
    amount: float
    notes: Optional[str] = None


class BudgetRequest(BaseModel):
    """Request model for creating/updating a budget"""
    user_id: str
    month: str  # Format: YYYY-MM
    total_budget: float
    categories: List[BudgetItem]


class TransactionSummary(BaseModel):
    """Model for transaction summary response"""
    total_expenses: float
    total_income: float
    net_cash_flow: float
    expense_by_category: Dict[str, float]
    expense_by_high_level_category: Dict[str, float]
    largest_expenses: List[Dict[str, Any]]
    largest_income: List[Dict[str, Any]]
    transaction_count: int
    date_range: Dict[str, str]


class BudgetProgressItem(BaseModel):
    """Budget progress for a specific category"""
    category: str
    budget_amount: float
    spent_amount: float
    remaining_amount: float
    percentage_used: float  # 0-100
    status: str  # "on_track", "warning", "exceeded"


class BudgetProgress(BaseModel):
    """Overall budget progress"""
    user_id: str
    month: str
    total_budget: float
    total_spent: float
    remaining_budget: float
    percentage_used: float  # 0-100
    categories: List[BudgetProgressItem]
    last_updated: datetime


@router.get("/summary/{user_id}", response_model=TransactionSummary)
async def get_financial_summary(
    user_id: str,
    start_date: Optional[str] = None,
    end_date: Optional[str] = None,
    refresh: bool = False
):
    """
    Get a summary of a user's financial transactions.
    
    Args:
        user_id: The ID of the user
        start_date: Start date for transactions (YYYY-MM-DD)
        end_date: End date for transactions (YYYY-MM-DD)
        refresh: Whether to refresh transaction data from the bank API
        
    Returns:
        Summary of the user's financial activity
    """
    try:
        # Set default date range if not provided
        if not start_date:
            # Default to the beginning of the current month
            today = datetime.now()
            start_date = datetime(today.year, today.month, 1).strftime('%Y-%m-%d')
        if not end_date:
            end_date = datetime.now().strftime('%Y-%m-%d')
        
        # Check if we have cached data in the database
        transactions_collection = await get_collection("bank_transactions")
        summaries_collection = await get_collection("financial_summaries")
        
        # Only use cached data if refresh is False
        cached_summary = None
        if not refresh:
            # Look for a cached summary with matching parameters
            cached_summary = await summaries_collection.find_one({
                "user_id": user_id,
                "date_range.start_date": start_date,
                "date_range.end_date": end_date,
                "created_at": {"$gte": datetime.now() - timedelta(hours=24)}  # Less than 24 hours old
            })
        
        if cached_summary and not refresh:
            # Remove MongoDB _id from response
            cached_summary.pop("_id", None)
            return cached_summary
        
        # No valid cached data, fetch from banking service
        try:
            # Fetch transactions from the banking service
            transactions_data = await banking_service.fetch_bank_transactions(
                user_id=user_id,
                start_date=start_date,
                end_date=end_date
            )
            
            # Extract the summary
            summary = transactions_data["summary"]
            
            # Add transaction count and date range for the response
            summary["transaction_count"] = transactions_data["transaction_count"]
            summary["date_range"] = transactions_data["date_range"]
            
            # Cache the summary for future requests
            await summaries_collection.update_one(
                {
                    "user_id": user_id,
                    "date_range.start_date": start_date,
                    "date_range.end_date": end_date
                },
                {
                    "$set": {
                        **summary,
                        "created_at": datetime.now()
                    }
                },
                upsert=True
            )
            
            return summary
            
        except ValueError as e:
            # Check if we have any stored transactions for this user
            if not refresh:
                transaction_count = await transactions_collection.count_documents({
                    "user_id": user_id,
                    "date": {
                        "$gte": datetime.strptime(start_date, '%Y-%m-%d'),
                        "$lte": datetime.strptime(end_date, '%Y-%m-%d')
                    }
                })
                
                if transaction_count > 0:
                    # Generate summary from stored transactions
                    logger.info(f"Generating summary from {transaction_count} stored transactions")
                    summary = await self._generate_summary_from_stored_transactions(
                        user_id, start_date, end_date
                    )
                    return summary
            
            # No stored transactions or refresh requested
            raise ValueError(f"Could not fetch banking data: {str(e)}")
            
    except ValueError as e:
        logger.error(f"Error in financial summary: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except Exception as e:
        logger.error(f"Error getting financial summary: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error retrieving financial summary: {str(e)}"
        )


@router.post("/budget", status_code=status.HTTP_201_CREATED)
async def create_budget(
    budget: BudgetRequest,
    budgets_collection = Depends(lambda: get_collection("budgets"))
):
    """
    Create or update a monthly budget.
    
    Args:
        budget: Budget details including categories and amounts
        
    Returns:
        Created/updated budget information
    """
    try:
        # Validate that the month is in the correct format (YYYY-MM)
        try:
            datetime.strptime(budget.month, '%Y-%m')
        except ValueError:
            raise ValueError("Month must be in the format YYYY-MM")
        
        # Convert the budget model to a dict for storage
        budget_dict = budget.dict()
        
        # Add timestamps
        current_time = datetime.utcnow()
        budget_dict["created_at"] = current_time
        budget_dict["updated_at"] = current_time
        
        # Check if a budget already exists for this user/month
        existing_budget = await budgets_collection.find_one({
            "user_id": budget.user_id,
            "month": budget.month
        })
        
        if existing_budget:
            # Update existing budget
            result = await budgets_collection.update_one(
                {"_id": existing_budget["_id"]},
                {
                    "$set": {
                        "total_budget": budget.total_budget,
                        "categories": [cat.dict() for cat in budget.categories],
                        "updated_at": current_time
                    }
                }
            )
            
            if result.modified_count == 0:
                logger.warning(f"Budget update had no effect for user {budget.user_id}")
            
            # Return the updated budget
            updated_budget = await budgets_collection.find_one({"_id": existing_budget["_id"]})
            updated_budget["_id"] = str(updated_budget["_id"])
            
            return {
                "message": "Budget updated successfully",
                "budget": updated_budget
            }
        else:
            # Create new budget
            result = await budgets_collection.insert_one(budget_dict)
            
            # Return the created budget
            created_budget = await budgets_collection.find_one({"_id": result.inserted_id})
            created_budget["_id"] = str(created_budget["_id"])
            
            return {
                "message": "Budget created successfully",
                "budget": created_budget
            }
            
    except ValueError as e:
        logger.error(f"Validation error in budget creation: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except Exception as e:
        logger.error(f"Error creating budget: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error creating budget: {str(e)}"
        )


@router.get("/progress/{user_id}", response_model=BudgetProgress)
async def get_budget_progress(
    user_id: str,
    month: Optional[str] = None,
    budgets_collection = Depends(lambda: get_collection("budgets")),
    transactions_collection = Depends(lambda: get_collection("bank_transactions"))
):
    """
    Get a user's progress against their monthly budget.
    
    Args:
        user_id: The ID of the user
        month: Month to check (YYYY-MM format, defaults to current month)
        
    Returns:
        Budget progress information with category breakdowns
    """
    try:
        # Set default month to current month if not provided
        if not month:
            today = datetime.now()
            month = f"{today.year}-{today.month:02d}"
        
        # Validate month format
        try:
            month_date = datetime.strptime(month, '%Y-%m')
        except ValueError:
            raise ValueError("Month must be in the format YYYY-MM")
        
        # Get the budget for this month
        budget = await budgets_collection.find_one({
            "user_id": user_id,
            "month": month
        })
        
        if not budget:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"No budget found for user {user_id} in month {month}"
            )
        
        # Calculate start and end dates for the month
        start_date = datetime(month_date.year, month_date.month, 1)
        
        # Last day of month calculation
        if month_date.month == 12:
            end_date = datetime(month_date.year + 1, 1, 1) - timedelta(days=1)
        else:
            end_date = datetime(month_date.year, month_date.month + 1, 1) - timedelta(days=1)
        
        end_date = datetime.combine(end_date, datetime.max.time())
        
        # Get transactions for this month
        # First try to get them from the banking service for freshest data
        try:
            transactions_data = await banking_service.fetch_bank_transactions(
                user_id=user_id,
                start_date=start_date.strftime('%Y-%m-%d'),
                end_date=end_date.strftime('%Y-%m-%d')
            )
            
            # Get spending by category
            spending_by_category = transactions_data["summary"]["expense_by_category"]
            total_spent = transactions_data["summary"]["total_expenses"]
            
        except Exception as bank_error:
            logger.warning(f"Could not fetch fresh banking data: {str(bank_error)}")
            
            # Fall back to stored transactions
            pipeline = [
                {
                    "$match": {
                        "user_id": user_id,
                        "date": {
                            "$gte": start_date,
                            "$lte": end_date
                        },
                        "transaction_type": "expense",
                        "pending": {"$ne": True}
                    }
                },
                {
                    "$group": {
                        "_id": "$enhanced_category",
                        "total": {"$sum": "$amount"}
                    }
                }
            ]
            
            category_totals = await transactions_collection.aggregate(pipeline).to_list(length=100)
            
            # Convert to the format we need
            spending_by_category = {}
            for item in category_totals:
                spending_by_category[item["_id"]] = item["total"]
            
            # Get total spending
            total_query = {
                "user_id": user_id,
                "date": {
                    "$gte": start_date,
                    "$lte": end_date
                },
                "transaction_type": "expense",
                "pending": {"$ne": True}
            }
            
            total_pipeline = [
                {"$match": total_query},
                {"$group": {"_id": None, "total": {"$sum": "$amount"}}}
            ]
            
            total_result = await transactions_collection.aggregate(total_pipeline).to_list(length=1)
            total_spent = total_result[0]["total"] if total_result else 0
        
        # Calculate progress for each category
        categories_progress = []
        
        for cat_budget in budget["categories"]:
            category = cat_budget["category"]
            budget_amount = cat_budget["amount"]
            spent_amount = spending_by_category.get(category, 0)
            remaining = budget_amount - spent_amount
            percentage = (spent_amount / budget_amount * 100) if budget_amount > 0 else 0
            
            # Determine status
            if percentage < 80:
                status = "on_track"
            elif percentage < 100:
                status = "warning"
            else:
                status = "exceeded"
            
            categories_progress.append({
                "category": category,
                "budget_amount": budget_amount,
                "spent_amount": spent_amount,
                "remaining_amount": remaining,
                "percentage_used": percentage,
                "status": status
            })
        
        # Calculate overall progress
        total_budget = budget["total_budget"]
        remaining_budget = total_budget - total_spent
        percentage_used = (total_spent / total_budget * 100) if total_budget > 0 else 0
        
        # Build response
        budget_progress = {
            "user_id": user_id,
            "month": month,
            "total_budget": total_budget,
            "total_spent": total_spent,
            "remaining_budget": remaining_budget,
            "percentage_used": percentage_used,
            "categories": categories_progress,
            "last_updated": datetime.utcnow()
        }
        
        return budget_progress
        
    except HTTPException:
        # Re-raise HTTP exceptions
        raise
    except ValueError as e:
        logger.error(f"Validation error in budget progress: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except Exception as e:
        logger.error(f"Error getting budget progress: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error retrieving budget progress: {str(e)}"
        )


@router.get("/budgets/{user_id}")
async def list_user_budgets(
    user_id: str,
    limit: int = 12,
    budgets_collection = Depends(lambda: get_collection("budgets"))
):
    """
    List all budgets for a user.
    
    Args:
        user_id: The ID of the user
        limit: Maximum number of budgets to return
        
    Returns:
        List of budgets with basic information
    """
    try:
        # Find all budgets for this user, sorted by month
        cursor = budgets_collection.find(
            {"user_id": user_id}
        ).sort("month", -1).limit(limit)
        
        # Convert cursor to list
        budgets = await cursor.to_list(length=limit)
        
        # Format response
        formatted_budgets = []
        for budget in budgets:
            budget["_id"] = str(budget["_id"])
            formatted_budgets.append(budget)
        
        return {"budgets": formatted_budgets}
        
    except Exception as e:
        logger.error(f"Error listing budgets: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error listing budgets: {str(e)}"
        )


async def _generate_summary_from_stored_transactions(
    user_id: str,
    start_date: str,
    end_date: str,
    transactions_collection = None
) -> Dict[str, Any]:
    """
    Generate a financial summary from stored transactions.
    
    Args:
        user_id: The ID of the user
        start_date: Start date string (YYYY-MM-DD)
        end_date: End date string (YYYY-MM-DD)
        transactions_collection: MongoDB collection (optional)
        
    Returns:
        Transaction summary
    """
    if transactions_collection is None:
        transactions_collection = await get_collection("bank_transactions")
    
    # Convert dates to datetime objects
    start_datetime = datetime.strptime(start_date, '%Y-%m-%d')
    end_datetime = datetime.strptime(end_date, '%Y-%m-%d')
    
    # Query for transactions in the date range
    query = {
        "user_id": user_id,
        "date": {
            "$gte": start_datetime,
            "$lte": end_datetime
        }
    }
    
    # Get all matching transactions
    cursor = transactions_collection.find(query)
    transactions = await cursor.to_list(length=1000)  # Limit to 1000 transactions
    
    # Initialize summary structure
    summary = {
        "total_expenses": 0,
        "total_income": 0,
        "net_cash_flow": 0,
        "expense_by_category": {},
        "expense_by_high_level_category": {},
        "largest_expenses": [],
        "largest_income": [],
        "transaction_count": len(transactions),
        "date_range": {
            "start_date": start_date,
            "end_date": end_date
        }
    }
    
    # Decrypt sensitive fields
    for transaction in transactions:
        # Process each transaction for the summary
        amount = transaction.get("amount", 0)
        transaction_type = transaction.get("transaction_type", "expense")
        
        if transaction.get("pending", False):
            continue
            
        # Track expenses and income
        if transaction_type == "expense":
            summary["total_expenses"] += amount
            
            # Track by category
            category = transaction.get("enhanced_category", "Uncategorized")
            if category in summary["expense_by_category"]:
                summary["expense_by_category"][category] += amount
            else:
                summary["expense_by_category"][category] = amount
                
            # Track by high-level category
            high_level = transaction.get("high_level_category", "Uncategorized")
            if high_level in summary["expense_by_high_level_category"]:
                summary["expense_by_high_level_category"][high_level] += amount
            else:
                summary["expense_by_high_level_category"][high_level] = amount
                
            # Track for largest expenses
            summary["largest_expenses"].append({
                "name": transaction.get("name", "Unknown"),
                "amount": amount,
                "date": transaction.get("date").strftime('%Y-%m-%d') if isinstance(transaction.get("date"), datetime) else transaction.get("date"),
                "category": category
            })
        else:
            # Track income
            summary["total_income"] += abs(amount)
            
            # Track for largest income
            summary["largest_income"].append({
                "name": transaction.get("name", "Unknown"),
                "amount": abs(amount),
                "date": transaction.get("date").strftime('%Y-%m-%d') if isinstance(transaction.get("date"), datetime) else transaction.get("date")
            })
    
    # Calculate net cash flow
    summary["net_cash_flow"] = summary["total_income"] - summary["total_expenses"]
    
    # Sort largest expenses/income
    summary["largest_expenses"] = sorted(
        summary["largest_expenses"],
        key=lambda x: x["amount"],
        reverse=True
    )[:5]  # Top 5
    
    summary["largest_income"] = sorted(
        summary["largest_income"],
        key=lambda x: x["amount"],
        reverse=True
    )[:5]  # Top 5
    
    return summary
