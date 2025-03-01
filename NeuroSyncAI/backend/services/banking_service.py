import os
import logging
import json
from typing import Dict, List, Optional, Any
from datetime import datetime, timedelta
import base64
from cryptography.fernet import Fernet
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC
from bson.objectid import ObjectId

# Plaid SDK
import plaid
from plaid.api import plaid_api
from plaid.model.link_token_create_request import LinkTokenCreateRequest
from plaid.model.link_token_create_request_user import LinkTokenCreateRequestUser
from plaid.model.item_public_token_exchange_request import ItemPublicTokenExchangeRequest
from plaid.model.products import Products
from plaid.model.country_code import CountryCode
from plaid.model.transactions_get_request import TransactionsGetRequest
from plaid.model.transactions_get_request_options import TransactionsGetRequestOptions

from config import get_settings
from db.database import get_collection

# Configure logging
logger = logging.getLogger(__name__)

class BankingService:
    """Service for interacting with banking APIs (Plaid)"""
    
    def __init__(self):
        """Initialize the banking service with configuration from settings"""
        self.settings = get_settings()
        
        # Initialize Plaid client
        self.plaid_client = self._init_plaid_client()
        
        # Set up encryption for storing sensitive tokens
        self._init_encryption()
        
        logger.info("Banking service initialized")
    
    def _init_plaid_client(self) -> plaid_api.PlaidApi:
        """Initialize Plaid API client with keys from settings"""
        try:
            # Get Plaid credentials from settings
            plaid_client_id = self.settings.PLAID_CLIENT_ID
            plaid_secret = self.settings.PLAID_SECRET
            plaid_env = self.settings.PLAID_ENVIRONMENT
            
            # Set environment
            if plaid_env == "sandbox":
                host = plaid.Environment.Sandbox
            elif plaid_env == "development":
                host = plaid.Environment.Development
            else:
                host = plaid.Environment.Production
                
            # Configure Plaid
            configuration = plaid.Configuration(
                host=host,
                api_key={
                    'clientId': plaid_client_id,
                    'secret': plaid_secret,
                    'plaidVersion': '2020-09-14'
                }
            )
            
            # Initialize API client
            api_client = plaid.ApiClient(configuration)
            plaid_client = plaid_api.PlaidApi(api_client)
            
            return plaid_client
            
        except Exception as e:
            logger.error(f"Error initializing Plaid client: {str(e)}")
            raise ValueError(f"Failed to initialize Plaid client: {str(e)}")
    
    def _init_encryption(self):
        """Initialize encryption for sensitive data"""
        try:
            # Get encryption key from settings
            encryption_key_base = self.settings.ENCRYPTION_KEY
            salt = self.settings.ENCRYPTION_SALT.encode()
            
            # Derive a key using PBKDF2
            kdf = PBKDF2HMAC(
                algorithm=hashes.SHA256(),
                length=32,
                salt=salt,
                iterations=100000,
            )
            
            # Create Fernet cipher
            key = base64.urlsafe_b64encode(kdf.derive(encryption_key_base.encode()))
            self.cipher = Fernet(key)
            
        except Exception as e:
            logger.error(f"Error initializing encryption: {str(e)}")
            raise ValueError(f"Failed to initialize encryption: {str(e)}")
    
    def _encrypt_token(self, token: str) -> str:
        """Encrypt sensitive token data before storing"""
        if not token:
            return None
        return self.cipher.encrypt(token.encode()).decode()
    
    def _decrypt_token(self, encrypted_token: str) -> str:
        """Decrypt token data when retrieving from storage"""
        if not encrypted_token:
            return None
        return self.cipher.decrypt(encrypted_token.encode()).decode()
    
    async def authenticate_bank(
        self, 
        user_id: str, 
        client_name: str = "ADHD Assistant",
        products: List[str] = ["transactions"],
        country_codes: List[str] = ["US", "CA", "GB"],
        redirect_uri: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Start the bank authentication process by generating a Plaid Link token.
        
        Args:
            user_id: The ID of the user
            client_name: The name of your app to display in the Plaid Link interface
            products: Plaid products to request access to (transactions, auth, identity, etc.)
            country_codes: Countries to support for bank selection
            redirect_uri: Redirect URI for OAuth bank connections (required for some banks)
            
        Returns:
            Dict containing the link_token to initialize Plaid Link
        """
        try:
            # Convert product strings to Plaid Products enum
            plaid_products = []
            for product in products:
                if product.lower() == "transactions":
                    plaid_products.append(Products("transactions"))
                elif product.lower() == "auth":
                    plaid_products.append(Products("auth"))
                elif product.lower() == "identity":
                    plaid_products.append(Products("identity"))
                elif product.lower() == "assets":
                    plaid_products.append(Products("assets"))
                elif product.lower() == "investments":
                    plaid_products.append(Products("investments"))
                else:
                    logger.warning(f"Unknown Plaid product: {product}")
            
            # Convert country codes to Plaid CountryCode enum
            plaid_country_codes = []
            for code in country_codes:
                plaid_country_codes.append(CountryCode(code))
            
            # Create a Link token request
            request = LinkTokenCreateRequest(
                user=LinkTokenCreateRequestUser(
                    client_user_id=user_id
                ),
                client_name=client_name,
                products=plaid_products,
                country_codes=plaid_country_codes,
                language='en'
            )
            
            # Add optional redirect URI if provided
            if redirect_uri:
                request.redirect_uri = redirect_uri
            
            # Create Link token with Plaid
            response = self.plaid_client.link_token_create(request)
            link_token = response.link_token
            
            # Store link token in the database
            try:
                link_tokens_collection = await get_collection("plaid_link_tokens")
                
                # Store the token and metadata
                await link_tokens_collection.insert_one({
                    "user_id": user_id,
                    "link_token": link_token,
                    "products": products,
                    "created_at": datetime.utcnow(),
                    "expires_at": datetime.utcnow() + timedelta(hours=4)  # Link tokens expire in 4 hours
                })
            except Exception as db_error:
                logger.error(f"Error storing link token: {str(db_error)}")
                # Continue even if we fail to store the token
            
            return {
                "link_token": link_token,
                "expires_in": 14400  # 4 hours in seconds
            }
            
        except plaid.ApiException as e:
            error_response = json.loads(e.body)
            logger.error(f"Plaid API error: {error_response}")
            raise ValueError(f"Plaid error: {error_response.get('error_message', str(e))}")
        except Exception as e:
            logger.error(f"Error creating Link token: {str(e)}")
            raise ValueError(f"Failed to create bank authentication link: {str(e)}")
    
    async def exchange_public_token(
        self, 
        user_id: str, 
        public_token: str,
        institution_id: Optional[str] = None,
        institution_name: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Exchange a public token for an access token after successful Link flow.
        
        Args:
            user_id: The ID of the user
            public_token: The public token from Plaid Link onSuccess callback
            institution_id: The ID of the financial institution (optional)
            institution_name: The name of the financial institution (optional)
            
        Returns:
            Dict with status of the exchange
        """
        try:
            # Exchange public token for access token
            exchange_request = ItemPublicTokenExchangeRequest(public_token=public_token)
            exchange_response = self.plaid_client.item_public_token_exchange(exchange_request)
            
            # Get tokens from response
            access_token = exchange_response.access_token
            item_id = exchange_response.item_id
            
            # Encrypt sensitive access token before storage
            encrypted_access_token = self._encrypt_token(access_token)
            
            # Store the access token in the database
            plaid_tokens_collection = await get_collection("plaid_tokens")
            
            # Check if we already have a token for this user/institution
            existing_token = None
            if institution_id:
                existing_token = await plaid_tokens_collection.find_one({
                    "user_id": user_id,
                    "institution_id": institution_id
                })
            
            token_data = {
                "user_id": user_id,
                "access_token": encrypted_access_token,
                "item_id": item_id,
                "updated_at": datetime.utcnow()
            }
            
            # Add institution data if available
            if institution_id:
                token_data["institution_id"] = institution_id
            if institution_name:
                token_data["institution_name"] = institution_name
            
            if existing_token:
                # Update existing token
                await plaid_tokens_collection.update_one(
                    {"_id": existing_token["_id"]},
                    {"$set": token_data}
                )
            else:
                # Insert new token record
                token_data["created_at"] = datetime.utcnow()
                await plaid_tokens_collection.insert_one(token_data)
            
            return {
                "success": True,
                "item_id": item_id,
                "institution_id": institution_id,
                "institution_name": institution_name
            }
            
        except plaid.ApiException as e:
            error_response = json.loads(e.body)
            logger.error(f"Plaid API error: {error_response}")
            raise ValueError(f"Plaid error: {error_response.get('error_message', str(e))}")
        except Exception as e:
            logger.error(f"Error exchanging public token: {str(e)}")
            raise ValueError(f"Failed to complete bank connection: {str(e)}")
    
    async def get_access_token(self, user_id: str, institution_id: Optional[str] = None) -> str:
        """
        Retrieve a decrypted access token for a user.
        
        Args:
            user_id: The ID of the user
            institution_id: The ID of the financial institution (optional)
            
        Returns:
            Decrypted access token
        """
        try:
            # Get token from database
            plaid_tokens_collection = await get_collection("plaid_tokens")
            
            # Build query based on available parameters
            query = {"user_id": user_id}
            if institution_id:
                query["institution_id"] = institution_id
            
            # Get the most recently updated token if no institution specified
            sort = [("updated_at", -1)]
            
            # Find token in database
            token_doc = await plaid_tokens_collection.find_one(query, sort=sort)
            
            if not token_doc or "access_token" not in token_doc:
                logger.warning(f"No access token found for user {user_id}")
                return None
            
            # Decrypt the access token
            encrypted_token = token_doc["access_token"]
            access_token = self._decrypt_token(encrypted_token)
            
            return access_token
            
        except Exception as e:
            logger.error(f"Error retrieving access token: {str(e)}")
            return None
    
    async def get_transactions(
        self,
        user_id: str,
        institution_id: Optional[str] = None,
        start_date: Optional[datetime] = None,
        end_date: Optional[datetime] = None,
        count: int = 100
    ) -> List[Dict[str, Any]]:
        """
        Get transactions for a user's connected bank account.
        
        Args:
            user_id: The ID of the user
            institution_id: The ID of the financial institution (optional)
            start_date: Start date for transactions (default: 30 days ago)
            end_date: End date for transactions (default: today)
            count: Maximum number of transactions to return
            
        Returns:
            List of transaction objects
        """
        try:
            # Get access token
            access_token = await self.get_access_token(user_id, institution_id)
            
            if not access_token:
                raise ValueError("No banking connection found")
            
            # Set default date range if not provided
            if not start_date:
                start_date = datetime.now() - timedelta(days=30)
            if not end_date:
                end_date = datetime.now()
            
            # Format dates for Plaid API
            start_date_str = start_date.strftime('%Y-%m-%d')
            end_date_str = end_date.strftime('%Y-%m-%d')
            
            # Build request
            options = TransactionsGetRequestOptions(count=count)
            request = TransactionsGetRequest(
                access_token=access_token,
                start_date=start_date_str,
                end_date=end_date_str,
                options=options
            )
            
            # Get transactions from Plaid
            response = self.plaid_client.transactions_get(request)
            transactions = response.transactions
            
            # Process transactions
            transaction_list = []
            for transaction in transactions:
                # Convert to dict and format for our usage
                trans_dict = {
                    "transaction_id": transaction.transaction_id,
                    "account_id": transaction.account_id,
                    "amount": transaction.amount,
                    "date": transaction.date,
                    "name": transaction.name,
                    "merchant_name": transaction.merchant_name,
                    "category": transaction.category,
                    "category_id": transaction.category_id,
                    "pending": transaction.pending,
                    "payment_channel": transaction.payment_channel
                }
                transaction_list.append(trans_dict)
            
            return transaction_list
            
        except plaid.ApiException as e:
            error_response = json.loads(e.body)
            logger.error(f"Plaid API error: {error_response}")
            
            # Handle common error cases
            error_code = error_response.get('error_code')
            if error_code == 'ITEM_LOGIN_REQUIRED':
                raise ValueError("Banking connection requires re-authentication")
            
            raise ValueError(f"Banking API error: {error_response.get('error_message', str(e))}")
        except Exception as e:
            logger.error(f"Error getting transactions: {str(e)}")
            raise ValueError(f"Failed to retrieve transactions: {str(e)}")
    
    async def fetch_bank_transactions(
        self,
        user_id: str,
        start_date: str = None,
        end_date: str = None,
        store: bool = True
    ) -> Dict[str, Any]:
        """
        Fetch, categorize, and store bank transactions for a user.
        
        Args:
            user_id: The ID of the user
            start_date: Start date (YYYY-MM-DD) for transactions (default: 30 days ago)
            end_date: End date (YYYY-MM-DD) for transactions (default: today)
            store: Whether to store transactions in MongoDB (default: True)
            
        Returns:
            Dict with transactions, categories, and summary data
        """
        try:
            # Parse dates
            parsed_start_date = None
            parsed_end_date = None
            
            if start_date:
                parsed_start_date = datetime.strptime(start_date, '%Y-%m-%d')
            if end_date:
                parsed_end_date = datetime.strptime(end_date, '%Y-%m-%d')
                
            # Get all connected banks for the user
            connected_banks = await self.get_connected_banks(user_id)
            
            if not connected_banks:
                raise ValueError("No connected banks found for this user")
            
            all_transactions = []
            transactions_by_bank = {}
            
            # Fetch transactions from each connected bank
            for bank in connected_banks:
                institution_id = bank.get("institution_id")
                institution_name = bank.get("institution_name", "Unknown Bank")
                
                try:
                    # Get transactions for this bank
                    bank_transactions = await self.get_transactions(
                        user_id=user_id,
                        institution_id=institution_id,
                        start_date=parsed_start_date,
                        end_date=parsed_end_date,
                        count=500  # Get a reasonable amount of transactions
                    )
                    
                    # Add bank information to each transaction
                    for transaction in bank_transactions:
                        transaction["institution_id"] = institution_id
                        transaction["institution_name"] = institution_name
                        
                    all_transactions.extend(bank_transactions)
                    transactions_by_bank[institution_id] = bank_transactions
                    
                except Exception as bank_error:
                    logger.error(f"Error fetching transactions for bank {institution_id}: {str(bank_error)}")
                    # Continue to next bank if one fails
            
            if not all_transactions:
                raise ValueError("No transactions found for the specified period")
            
            # Enhanced categorization
            categorized_transactions = self._categorize_transactions(all_transactions)
            
            # Generate summary statistics
            summary = self._generate_transaction_summary(categorized_transactions)
            
            # Store transactions securely if requested
            if store:
                await self._store_transactions(user_id, categorized_transactions)
            
            # Return the results
            return {
                "transactions": categorized_transactions,
                "summary": summary,
                "transaction_count": len(categorized_transactions),
                "date_range": {
                    "start_date": start_date or (datetime.now() - timedelta(days=30)).strftime('%Y-%m-%d'),
                    "end_date": end_date or datetime.now().strftime('%Y-%m-%d')
                }
            }
            
        except Exception as e:
            logger.error(f"Error fetching and processing bank transactions: {str(e)}")
            raise ValueError(f"Failed to fetch bank transactions: {str(e)}")
    
    def _categorize_transactions(self, transactions: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """
        Enhance transaction categorization beyond Plaid's categories.
        
        Args:
            transactions: List of transaction dictionaries
            
        Returns:
            Transactions with enhanced categorization
        """
        # Define our custom category mapping
        # Map common merchants and keywords to specific categories
        merchant_category_map = {
            # Food & Dining
            "grocery": "Groceries",
            "supermarket": "Groceries",
            "restaurant": "Restaurants",
            "doordash": "Food Delivery",
            "ubereats": "Food Delivery",
            "grubhub": "Food Delivery",
            "bakery": "Restaurants",
            "cafe": "Restaurants",
            "coffee shop": "Coffee & Tea",
            "starbucks": "Coffee & Tea",
            
            # Bills & Utilities
            "electric": "Utilities",
            "water": "Utilities",
            "gas": "Utilities",
            "internet": "Internet",
            "cable": "Internet",
            "phone": "Phone",
            "mobile": "Phone",
            "insurance": "Insurance",
            "rent": "Housing",
            "mortgage": "Housing",
            
            # Entertainment
            "netflix": "Streaming Services",
            "hulu": "Streaming Services",
            "disney+": "Streaming Services",
            "spotify": "Music",
            "apple music": "Music",
            "movie": "Entertainment",
            "cinema": "Entertainment",
            "theatre": "Entertainment",
            "concert": "Entertainment",
            
            # Shopping
            "amazon": "Online Shopping",
            "walmart": "Shopping",
            "target": "Shopping",
            "clothing": "Clothing",
            "electronics": "Electronics",
            
            # Transportation
            "uber": "Rideshare",
            "lyft": "Rideshare",
            "gas station": "Gas",
            "fuel": "Gas",
            "parking": "Parking",
            "transit": "Public Transit",
            "subway": "Public Transit",
            "bus": "Public Transit",
            "train": "Public Transit",
            "airline": "Air Travel",
            "flight": "Air Travel",
            
            # Health
            "pharmacy": "Healthcare",
            "doctor": "Healthcare",
            "medical": "Healthcare",
            "dental": "Healthcare",
            "gym": "Fitness",
            "fitness": "Fitness",
            
            # Personal
            "salon": "Personal Care",
            "barber": "Personal Care",
            "spa": "Personal Care",
            
            # Education
            "tuition": "Education",
            "school": "Education",
            "book": "Education",
            "university": "Education",
            "college": "Education",
            
            # Miscellaneous
            "atm": "ATM/Cash",
            "withdrawal": "ATM/Cash",
            "fee": "Fees",
            "service fee": "Fees",
            "tax": "Taxes",
            "donation": "Charity",
            "gift": "Gifts"
        }
        
        # Define hierarchy of high-level categories
        high_level_categories = {
            "Food & Dining": ["Groceries", "Restaurants", "Food Delivery", "Coffee & Tea"],
            "Housing & Utilities": ["Housing", "Utilities", "Internet", "Phone"],
            "Entertainment": ["Streaming Services", "Music", "Entertainment"],
            "Shopping": ["Online Shopping", "Shopping", "Clothing", "Electronics"],
            "Transportation": ["Rideshare", "Gas", "Parking", "Public Transit", "Air Travel"],
            "Health & Wellness": ["Healthcare", "Fitness", "Personal Care"],
            "Education": ["Education"],
            "Financial": ["ATM/Cash", "Fees", "Taxes"],
            "Miscellaneous": ["Charity", "Gifts"]
        }
        
        for transaction in transactions:
            # Get existing Plaid categories
            plaid_categories = transaction.get("category", [])
            plaid_category = plaid_categories[0] if plaid_categories else "Uncategorized"
            
            # Start with Plaid's categorization
            transaction["enhanced_category"] = plaid_category
            transaction["category_confidence"] = "medium"
            
            # Try to find a better match based on transaction description
            name = transaction.get("name", "").lower()
            merchant = transaction.get("merchant_name", "").lower()
            
            # Check merchant name and transaction name against our mapping
            for keyword, category in merchant_category_map.items():
                if keyword in merchant or keyword in name:
                    transaction["enhanced_category"] = category
                    transaction["category_confidence"] = "high"
                    break
            
            # Add high-level category
            transaction["high_level_category"] = "Uncategorized"
            for high_cat, sub_cats in high_level_categories.items():
                if transaction["enhanced_category"] in sub_cats:
                    transaction["high_level_category"] = high_cat
                    break
            
            # Determine if expense or income
            amount = transaction.get("amount", 0)
            if amount > 0:
                transaction["transaction_type"] = "expense"
            else:
                transaction["transaction_type"] = "income"
                # If it's income, override the category
                transaction["enhanced_category"] = "Income"
                transaction["high_level_category"] = "Income"
        
        return transactions
    
    def _generate_transaction_summary(self, transactions: List[Dict[str, Any]]) -> Dict[str, Any]:
        """
        Generate summary statistics from transactions.
        
        Args:
            transactions: List of categorized transactions
            
        Returns:
            Dictionary with summary statistics
        """
        # Initialize summary data
        summary = {
            "total_expenses": 0,
            "total_income": 0,
            "net_cash_flow": 0,
            "expense_by_category": {},
            "expense_by_high_level_category": {},
            "transaction_count_by_category": {},
            "largest_expenses": [],
            "largest_income": []
        }
        
        # Process each transaction
        for transaction in transactions:
            amount = transaction.get("amount", 0)
            category = transaction.get("enhanced_category", "Uncategorized")
            high_level_category = transaction.get("high_level_category", "Uncategorized")
            transaction_type = transaction.get("transaction_type", "expense")
            
            # Skip pending transactions for calculations
            if transaction.get("pending", False):
                continue
                
            # Calculate totals
            if transaction_type == "expense":
                summary["total_expenses"] += amount
                
                # Add to category totals
                if category in summary["expense_by_category"]:
                    summary["expense_by_category"][category] += amount
                else:
                    summary["expense_by_category"][category] = amount
                    
                # Add to high-level category totals
                if high_level_category in summary["expense_by_high_level_category"]:
                    summary["expense_by_high_level_category"][high_level_category] += amount
                else:
                    summary["expense_by_high_level_category"][high_level_category] = amount
                    
                # Track for largest expenses
                summary["largest_expenses"].append({
                    "name": transaction.get("name", "Unknown"),
                    "amount": amount,
                    "date": transaction.get("date"),
                    "category": category
                })
            else:
                # Track income
                summary["total_income"] += abs(amount)
                
                # Track for largest income
                summary["largest_income"].append({
                    "name": transaction.get("name", "Unknown"),
                    "amount": abs(amount),
                    "date": transaction.get("date")
                })
            
            # Count transactions by category
            if category in summary["transaction_count_by_category"]:
                summary["transaction_count_by_category"][category] += 1
            else:
                summary["transaction_count_by_category"][category] = 1
        
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
    
    async def _store_transactions(
        self, 
        user_id: str, 
        transactions: List[Dict[str, Any]]
    ) -> None:
        """
        Securely store transactions in MongoDB.
        
        Args:
            user_id: The ID of the user
            transactions: List of transactions to store
        """
        try:
            # Get transactions collection
            transactions_collection = await get_collection("bank_transactions")
            
            # Process and store each transaction
            stored_count = 0
            for transaction in transactions:
                # Create a copy to avoid modifying the original
                trans_to_store = transaction.copy()
                
                # Add user_id
                trans_to_store["user_id"] = user_id
                
                # Encrypt sensitive fields
                sensitive_fields = [
                    "name", 
                    "merchant_name", 
                    "account_id"
                ]
                
                for field in sensitive_fields:
                    if field in trans_to_store and trans_to_store[field]:
                        trans_to_store[field] = self._encrypt_token(str(trans_to_store[field]))
                
                # Add timestamps
                trans_to_store["stored_at"] = datetime.utcnow()
                
                # Convert date string to datetime object if needed
                if "date" in trans_to_store and isinstance(trans_to_store["date"], str):
                    trans_to_store["date"] = datetime.strptime(trans_to_store["date"], '%Y-%m-%d')
                
                # Check if transaction already exists (avoid duplicates)
                existing = await transactions_collection.find_one({
                    "user_id": user_id,
                    "transaction_id": trans_to_store.get("transaction_id")
                })
                
                if existing:
                    # Update existing transaction
                    await transactions_collection.update_one(
                        {"_id": existing["_id"]},
                        {"$set": trans_to_store}
                    )
                else:
                    # Insert new transaction
                    await transactions_collection.insert_one(trans_to_store)
                    stored_count += 1
            
            logger.info(f"Stored {stored_count} new transactions for user {user_id}")
            
        except Exception as e:
            logger.error(f"Error storing transactions: {str(e)}")
            # Don't raise the exception as this is a non-critical operation
            # The caller still has the transactions in memory
    
    async def get_connected_banks(self, user_id: str) -> List[Dict[str, Any]]:
        """
        Get all connected banks for a user.
        
        Args:
            user_id: The ID of the user
            
        Returns:
            List of connected bank information
        """
        try:
            # Get tokens from database
            plaid_tokens_collection = await get_collection("plaid_tokens")
            
            # Find all tokens for this user
            cursor = plaid_tokens_collection.find({"user_id": user_id})
            
            banks = []
            async for token_doc in cursor:
                bank_info = {
                    "item_id": token_doc.get("item_id"),
                    "institution_id": token_doc.get("institution_id"),
                    "institution_name": token_doc.get("institution_name", "Unknown Bank"),
                    "connected_at": token_doc.get("created_at"),
                    "last_updated": token_doc.get("updated_at")
                }
                banks.append(bank_info)
            
            return banks
            
        except Exception as e:
            logger.error(f"Error getting connected banks: {str(e)}")
            raise ValueError(f"Failed to retrieve connected banks: {str(e)}")
    
    async def disconnect_bank(self, user_id: str, item_id: str) -> Dict[str, Any]:
        """
        Disconnect a bank connection.
        
        Args:
            user_id: The ID of the user
            item_id: The Plaid Item ID to disconnect
            
        Returns:
            Dict with status of the disconnection
        """
        try:
            # Get token document to find the access token
            plaid_tokens_collection = await get_collection("plaid_tokens")
            token_doc = await plaid_tokens_collection.find_one({
                "user_id": user_id,
                "item_id": item_id
            })
            
            if not token_doc:
                raise ValueError(f"Bank connection not found for item_id: {item_id}")
            
            # Get and decrypt access token
            encrypted_token = token_doc.get("access_token")
            access_token = self._decrypt_token(encrypted_token)
            
            # Remove the item from Plaid
            # Note: This is not supported in the sandbox environment
            try:
                from plaid.model.item_remove_request import ItemRemoveRequest
                request = ItemRemoveRequest(access_token=access_token)
                self.plaid_client.item_remove(request)
            except plaid.ApiException as e:
                error_response = json.loads(e.body)
                logger.warning(f"Plaid item removal error: {error_response}")
                # Continue with local removal even if Plaid removal fails
            
            # Remove the token from our database
            result = await plaid_tokens_collection.delete_one({
                "user_id": user_id,
                "item_id": item_id
            })
            
            if result.deleted_count == 0:
                logger.warning(f"No token document deleted for item_id: {item_id}")
            
            return {
                "success": True,
                "message": "Bank connection removed successfully"
            }
            
        except Exception as e:
            logger.error(f"Error disconnecting bank: {str(e)}")
            raise ValueError(f"Failed to disconnect bank: {str(e)}")


# Create a singleton instance
banking_service = BankingService()
