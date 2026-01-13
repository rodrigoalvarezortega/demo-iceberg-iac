"""
FastAPI application for GCP Serverless Demo
Endpoints: /v1/health, /v1/items (POST, GET)
"""
import os
from datetime import datetime
from typing import Optional
import uuid

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from google.cloud import firestore

app = FastAPI(title="Demo API", version="1.0.0")

# Initialize Firestore client
db = firestore.Client(project=os.getenv("GCP_PROJECT"))


class ItemCreate(BaseModel):
    name: str
    ts: Optional[int] = None


class ItemResponse(BaseModel):
    id: str
    data: dict


@app.get("/v1/health")
async def health():
    """Health check endpoint"""
    return {"ok": True}


@app.post("/v1/items", response_model=ItemResponse)
async def create_item(item: ItemCreate):
    """Create a new item in Firestore"""
    item_id = str(uuid.uuid4())
    item_data = {
        "name": item.name,
        "ts": item.ts if item.ts is not None else int(datetime.now().timestamp()),
        "created_at": datetime.utcnow().isoformat()
    }
    
    # Save to Firestore
    doc_ref = db.collection("items").document(item_id)
    doc_ref.set(item_data)
    
    return ItemResponse(id=item_id, data=item_data)


@app.get("/v1/items/{item_id}", response_model=ItemResponse)
async def get_item(item_id: str):
    """Get an item by ID from Firestore"""
    doc_ref = db.collection("items").document(item_id)
    doc = doc_ref.get()
    
    if not doc.exists:
        raise HTTPException(status_code=404, detail="Item not found")
    
    return ItemResponse(id=item_id, data=doc.to_dict())


if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("PORT", 8080))
    uvicorn.run(app, host="0.0.0.0", port=port)
