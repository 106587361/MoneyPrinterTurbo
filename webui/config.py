# 基本配置
import os

# API Keys (從環境變數讀取)
PEXELS_API_KEY = os.getenv("PEXELS_API_KEY", "")
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY", "")
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY", "")

# 基本設定
VIDEO_RESOLUTION = "vertical"  # vertical 或 horizontal
SUBTITLE_LANGUAGE = "zh-CN"
STORAGE_PATH = "storage"

# TTS 設定
VOICE_LANGUAGE = "zh-CN"
VOICE_STYLE = "standard"

# 影片素材來源
VIDEO_SOURCE = "pexels"  # pexels, pixabay, local