#!/bin/bash

# 創建必要的目錄
mkdir -p storage/temp
mkdir -p resource/fonts
mkdir -p resource/songs
mkdir -p resource/images

# 1. 生成 Streamlit 伺服器設定（.streamlit/config.toml）
echo "寫入 .streamlit/config.toml (Streamlit 伺服器設定)..."
mkdir -p ./webui/.streamlit
cat > ./webui/.streamlit/config.toml << EOF
[server]
headless = true
port = ${PORT:-8501}
address = "0.0.0.0"
# 在 HF 不需要 CORS，關掉可避免某些代理情況報錯
enableCORS = false
EOF

# 2. 生成應用程式配置（專案根目錄 config.toml，供 MoneyPrinterTurbo 讀取）
echo "寫入 專案配置 config.toml (應用層設定)..."
cat > ./config.toml << EOL
# 注意：MoneyPrinterTurbo 的 README 指出需要配置 pexels_api_keys 與 llm_provider 等關鍵項 <mcreference link="https://github.com/106587361/MoneyPrinterTurbo" index="0">0</mcreference>
pexels_api_keys = ["${PEXELS_API_KEY}"]
llm_provider = "openai"

# OpenAI / 第三方相容 API
openai_api_key = "${OPENAI_API_KEY}"
openai_api_base = "${OPENAI_API_BASE}"

# Google Gemini
gemini_api_key = "${GEMINI_API_KEY}"

# 語音合成（TTS）
tts_provider = "${TTS_PROVIDER}"
elevenlabs_api_key = "${ELEVENLABS_API_KEY}"
elevenlabs_voice_id = "${ELEVENLABS_VOICE_ID}"
azure_speech_key = "${AZURE_SPEECH_KEY}"
azure_speech_region = "${AZURE_SPEECH_REGION}"

# 儲存與影片參數
storage_path = "storage"
video_resolution = "vertical"   # vertical 或 horizontal
subtitle_language = "zh-CN"
EOL

# 環境變數（提供給手動啟動或相容邏輯）
export STREAMLIT_SERVER_PORT=${PORT:-8501}
export STREAMLIT_SERVER_ADDRESS=0.0.0.0

# 3. 啟動 Streamlit 應用程式
echo "啟動 MoneyPrinterTurbo..."
exec streamlit run webui/Main.py --server.port=${STREAMLIT_SERVER_PORT} --server.address=${STREAMLIT_SERVER_ADDRESS} --server.headless true