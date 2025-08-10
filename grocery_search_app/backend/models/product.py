from pydantic import BaseModel
from typing import Optional

class Product(BaseModel):
    id: str
    name: str
    price: float
    store_name: str
    category: Optional[str] = None
    image_url: Optional[str] = None
    
    class Config:
        orm_mode = True