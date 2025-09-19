#!/bin/bash

# 創建必要的目錄
mkdir -p storage/temp
mkdir -p resource/fonts
mkdir -p resource/songs
mkdir -p resource/images

# 1. 動態生成 config.toml 檔案
echo "正在生成 config.toml 設定檔..."
cat > ./webui/config.toml << EOL
[pexels]
# Pexels API Key, 用於下載無版權影片素材
api_key = "${PEXELS_API_KEY}"

[openai]
# OpenAI API Key, 用於生成影片文案
api_key = "${OPENAI_API_KEY}"
# 如果您使用代理或第三方 OpenAI 服務，請填寫 API Base URL
api_base = "${OPENAI_API_BASE}"

[llm]
# 可選 "openai" 或 "gemini"
provider = "openai"

[gemini]
# Google Gemini API Key
api_key = "${GEMINI_API_KEY}"

[tts]
# 文字轉語音服務提供商, 可選 "openai", "elevenlabs"
provider = "${TTS_PROVIDER}"

[elevenlabs]
# ElevenLabs API Key
api_key = "${ELEVENLABS_API_KEY}"
# ElevenLabs 聲音 ID
voice_id = "${ELEVENLABS_VOICE_ID}"

[azure]
# Azure 語音服務金鑰與區域
speech_key = "${AZURE_SPEECH_KEY}"
speech_region = "${AZURE_SPEECH_REGION}"

[storage]
# 影片等檔案的儲存位置
storage_path = "storage"

[video]
# 影片尺寸, horizontal (1920x1080) 或 vertical (1080x1920)
resolution = "vertical"
# 字幕語言, 例如 "zh-CN", "en-US"
subtitle_language = "zh-CN"
EOL

# 設置環境變數
export STREAMLIT_SERVER_PORT=${PORT:-8501}
export STREAMLIT_SERVER_ADDRESS=0.0.0.0

# 2. 啟動 Streamlit 應用程式
echo "啟動 MoneyPrinterTurbo..."
streamlit run webui/Main.py --server.port=${STREAMLIT_SERVER_PORT} --server.address=${STREAMLIT_SERVER_ADDRESS} --server.headless true