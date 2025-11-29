# Audio Playlist Application

A mobile application that allows users to create, manage, and play audio playlists with support for local files and remote audio extraction from YouTube and other platforms.

## Features

- Create, name, and describe multiple playlists
- Add tracks from:
  - Local audio files
  - Remote audio URLs
  - YouTube and other video platform links (via backend extraction)
- Play, pause, stop, and seek audio tracks
- Resume playback from last listening position
- Simple, modern UI with light/dark theme support
- Compatible with Android and iOS

## Architecture

```
[ Mobile App (Flutter) ] ←→ [ Backend API ] ←→ [ Temp Storage ]
        ↑                          ↑
   Local files            yt-dlp + FFmpeg
```

## Backend API

### Endpoints

- `POST /extract` - Extract audio from a URL
  - Request: `{"url": "https://youtube.com/..."}`
  - Response: `{"audio_url": "...", "title": "...", "duration": 185}`

- `GET /status/{task_id}` - Check extraction status

- `GET /cache/{filename}` - Serve cached audio files

### Security

- URL validation with allowed domains whitelist
- Rate limiting (not implemented in basic version)
- Temporary file storage with automatic cleanup (24 hours)

## Mobile App

### Technologies

- Flutter (Dart)
- Hive for local storage
- just_audio for audio playback
- audio_service for background playback
- file_picker for local file selection

### Data Model

#### Playlist
- id (UUID)
- name (string, required)
- description (string, optional)
- created_at (datetime)

#### Track
- id (UUID)
- playlist_id (UUID)
- title (string)
- source_type: local_file | remote_url | extracted
- source_path: local path or URL
- duration_seconds (optional)
- last_position_ms (optional)
- is_completed (boolean)
- added_at (datetime)

## Setup Instructions

### Backend Setup

1. Install Python dependencies:
```bash
pip install -r requirements.txt
```

2. Make sure FFmpeg is installed on your system:
```bash
# Ubuntu/Debian
sudo apt update && sudo apt install ffmpeg

# macOS
brew install ffmpeg
```

3. Start the backend server:
```bash
cd backend
python main.py
```

### Mobile App Setup

1. Install Flutter (if not already installed)

2. Get dependencies:
```bash
cd mobile_app
flutter pub get
```

3. Generate Hive adapters:
```bash
flutter packages pub run build_runner build
```

4. Run the app:
```bash
flutter run
```

## Docker Deployment

Build and run the backend with Docker:

```bash
cd backend
docker build -t audio-playlist-backend .
docker run -p 8000:8000 audio-playlist-backend
```

## Project Structure

```
audio-playlist-app/
├── backend/                 # FastAPI backend
│   ├── main.py             # Main API implementation
│   ├── requirements.txt    # Python dependencies
│   ├── Dockerfile         # Docker configuration
│   └── start.sh           # Start script
└── mobile_app/            # Flutter mobile application
    ├── lib/
    │   ├── main.dart      # App entry point
    │   ├── models/        # Data models
    │   ├── services/      # Business logic
    │   ├── ui/            # UI screens
    │   └── utils/         # Utility functions
    └── pubspec.yaml       # Flutter dependencies
```

## Future Enhancements (V2)

- User accounts and cloud synchronization
- Custom themes and UI settings
- Podcast RSS feed support
- Collaborative playlists
- Advanced audio editing features

## Legal Notice

The backend API does not store user data or track usage beyond what is necessary for audio extraction. Users are responsible for ensuring they have the right to download and use any content they add to their playlists.