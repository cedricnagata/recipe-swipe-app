from fastapi import FastAPI
from app.core.database import engine, Base
from app.routers import recipes, chef, filters, collection, saved_recipes, swipe_sessions

# Create all tables
Base.metadata.create_all(bind=engine)

app = FastAPI(title="Little Chef API")

# Include routers
app.include_router(recipes.router)
app.include_router(chef.router)
app.include_router(filters.router)
app.include_router(collection.router)
app.include_router(saved_recipes.router)
app.include_router(swipe_sessions.router)

@app.get("/")
async def root():
    return {"message": "Welcome to Little Chef API"}