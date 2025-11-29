from fastapi import FastAPI, HTTPException, BackgroundTasks
from pydantic import BaseModel
from typing import Optional
import yt_dlp
import os
import uuid
import tempfile
import subprocess
import re
from urllib.parse import urlparse
import time
from config import CACHE_DIR, MAX_CACHE_AGE, ALLOWED_DOMAINS, YT_DLP_OPTIONS

app = FastAPI(title="Audio Playlist Backend API", version="1.0.0")

# Ensure cache directory exists
os.makedirs(CACHE_DIR, exist_ok=True)

class ExtractRequest(BaseModel):
    url: str

class ExtractResponse(BaseModel):
    audio_url: str
    title: str
    duration: Optional[int] = None

class TaskStatusResponse(BaseModel):
    status: str  # pending, processing, completed, failed
    audio_url: Optional[str] = None
    title: Optional[str] = None
    duration: Optional[int] = None

# In-memory task storage (for demo purposes, use Redis/database in production)
tasks = {}

def is_url_allowed(url: str) -> bool:
    """Check if the URL is from an allowed domain"""
    try:
        parsed = urlparse(url)
        domain = parsed.netloc.lower()
        # Handle subdomains
        if domain.endswith('.youtube.com') or domain.endswith('.vimeo.com') or domain.endswith('.soundcloud.com'):
            return True
        return domain in ALLOWED_DOMAINS
    except:
        return False

def clean_old_files():
    """Remove cached files older than MAX_CACHE_AGE"""
    current_time = time.time()
    for filename in os.listdir(CACHE_DIR):
        filepath = os.path.join(CACHE_DIR, filename)
        if os.path.isfile(filepath):
            file_age = current_time - os.path.getmtime(filepath)
            if file_age > MAX_CACHE_AGE:
                try:
                    os.remove(filepath)
                except:
                    pass  # Ignore errors when removing old files

def extract_audio(url: str, task_id: str):
    """Background task to extract audio from URL"""
    tasks[task_id] = {"status": "processing", "progress": 0}
    
    try:
        # Validate URL
        if not is_url_allowed(url):
            tasks[task_id] = {"status": "failed", "error": "URL not allowed"}
            return
        
        # Create temporary file for audio
        temp_filename = os.path.join(CACHE_DIR, f"{task_id}.mp3")
        
        # yt-dlp options
        ydl_opts = YT_DLP_OPTIONS.copy()
        ydl_opts['outtmpl'] = os.path.join(CACHE_DIR, f'{task_id}.%(ext)s')
        
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            info = ydl.extract_info(url, download=True)
            
        # Get the actual filename after processing
        actual_filename = os.path.join(CACHE_DIR, f"{task_id}.mp3")
        
        # Check if file exists, if not try other extensions
        if not os.path.exists(actual_filename):
            for ext in ['m4a', 'webm', 'aac', 'opus']:
                temp_ext = os.path.join(CACHE_DIR, f"{task_id}.{ext}")
                if os.path.exists(temp_ext):
                    # Convert to MP3 using ffmpeg
                    actual_filename = os.path.join(CACHE_DIR, f"{task_id}.mp3")
                    subprocess.run([
                        'ffmpeg', '-y', '-i', temp_ext, 
                        '-b:a', '192k', actual_filename
                    ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                    # Remove the original file
                    os.remove(temp_ext)
                    break
        
        # Update task status
        title = info.get('title', 'Unknown Title')
        duration = info.get('duration', None)
        
        tasks[task_id] = {
            "status": "completed",
            "audio_url": f"/cache/{task_id}.mp3",
            "title": title,
            "duration": int(duration) if duration else None
        }
        
    except Exception as e:
        tasks[task_id] = {"status": "failed", "error": str(e)}

@app.post("/extract", response_model=ExtractResponse)
async def extract_audio_endpoint(request: ExtractRequest, background_tasks: BackgroundTasks):
    """Extract audio from a URL"""
    if not is_url_allowed(request.url):
        raise HTTPException(status_code=400, detail="URL not allowed")
    
    # Clean old files
    clean_old_files()
    
    # Generate task ID
    task_id = str(uuid.uuid4())
    
    # Start background extraction
    background_tasks.add_task(extract_audio, request.url, task_id)
    
    # Wait briefly for initial processing
    time.sleep(0.5)
    
    # Poll for completion (in a real app, you'd use a separate endpoint)
    max_wait = 30  # seconds
    wait_time = 0
    while wait_time < max_wait:
        task = tasks.get(task_id, {})
        if task.get("status") == "completed":
            return ExtractResponse(
                audio_url=f"http://localhost:8000{task['audio_url']}",
                title=task["title"],
                duration=task["duration"]
            )
        elif task.get("status") == "failed":
            raise HTTPException(status_code=500, detail=task.get("error", "Extraction failed"))
        time.sleep(0.5)
        wait_time += 0.5
    
    # If still processing after max wait, return task ID for polling
    raise HTTPException(status_code=202, detail="Processing, check status endpoint")

@app.get("/status/{task_id}", response_model=TaskStatusResponse)
async def get_task_status(task_id: str):
    """Get the status of an extraction task"""
    task = tasks.get(task_id, {"status": "not_found"})
    return TaskStatusResponse(
        status=task.get("status", "not_found"),
        audio_url=task.get("audio_url"),
        title=task.get("title"),
        duration=task.get("duration")
    )

@app.get("/cache/{filename}")
async def get_cached_file(filename: str):
    """Serve cached audio files"""
    import os
    from fastapi.responses import FileResponse
    
    filepath = os.path.join(CACHE_DIR, filename)
    if not os.path.exists(filepath):
        raise HTTPException(status_code=404, detail="File not found")
    
    return FileResponse(filepath, media_type="audio/mpeg")

@app.get("/")
async def root():
    return {"message": "Audio Playlist Backend API", "version": "1.0.0"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)