"""
Configuration file for the Audio Playlist Backend API
"""

import os
from typing import List

# Server configuration
HOST = os.getenv("HOST", "0.0.0.0")
PORT = int(os.getenv("PORT", "8000"))
DEBUG = os.getenv("DEBUG", "False").lower() == "true"

# Cache configuration
CACHE_DIR = os.getenv("CACHE_DIR", "cache")
MAX_CACHE_AGE = int(os.getenv("MAX_CACHE_AGE", "86400"))  # 24 hours in seconds
MAX_CACHE_SIZE = int(os.getenv("MAX_CACHE_SIZE", "1073741824"))  # 1GB in bytes

# Security configuration
ALLOWED_DOMAINS: List[str] = [
    'youtube.com', 'www.youtube.com', 'youtu.be',
    'vimeo.com', 'www.vimeo.com',
    'soundcloud.com', 'www.soundcloud.com'
]

# Add any additional domains from environment variable
ADDITIONAL_DOMAINS = os.getenv("ADDITIONAL_ALLOWED_DOMAINS", "")
if ADDITIONAL_DOMAINS:
    ALLOWED_DOMAINS.extend(ADDITIONAL_DOMAINS.split(","))

# yt-dlp configuration
YT_DLP_OPTIONS = {
    'format': 'bestaudio/best',
    'postprocessors': [{
        'key': 'FFmpegExtractAudio',
        'preferredcodec': 'mp3',
        'preferredquality': '192',
    }],
    'postprocessor_args': [
        '-ar', '44100'
    ],
    'prefer_ffmpeg': True,
    'audioquality': '0',
    'extractaudio': True,
    'audioformat': 'mp3',
    'noplaylist': True,
}

# Rate limiting (requests per minute)
RATE_LIMIT = int(os.getenv("RATE_LIMIT", "10"))