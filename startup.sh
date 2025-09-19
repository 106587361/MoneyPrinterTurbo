#!/bin/bash

# 創建必要的目錄
mkdir -p storage/temp
mkdir -p resource/fonts
mkdir -p resource/songs
mkdir -p resource/images

# 1. 生成 Streamlit 伺服器設定（.streamlit/config.toml）
echo "寫入 .streamlit/config.toml (Streamlit 伺服器設定)..."
mkdir -p ./.streamlit
cat > ./.streamlit/config.toml << EOF
[server]
headless = true
port = ${PORT:-7860}
address = "0.0.0.0"
# 在 HF 不需要 CORS，關掉可避免某些代理情況報錯
enableCORS = false

[browser]
# 關閉遙測與用量收集，避免在容器根目錄 '/.streamlit' 嘗試寫入而觸發 Permission denied
# 參考啟動時提示：To deactivate, set browser.gatherUsageStats to false
#gatherUsageStats = false
EOF

# 2. 生成應用程式配置（專案根目錄 config.toml，供 MoneyPrinterTurbo 讀取）
echo "寫入 專案配置 config.toml (應用層設定)..."
cat > ./config.toml << 'EOL'
# 根層：模型與字幕設定
llm_provider = "${LLM_PROVIDER:-openai}"
subtitle_provider = "${SUBTITLE_PROVIDER:-edge}"  # edge 或 whisper

# OpenAI / 相容 API
openai_api_key = "${OPENAI_API_KEY}"
openai_base_url = "${OPENAI_API_BASE}"

# Gemini
gemini_api_key = "${GEMINI_API_KEY}"

# 任務下載端點（可留空）
endpoint = "${ENDPOINT}"

# 應用設定區塊
[app]
video_source = "${VIDEO_SOURCE:-pexels}"  # pexels 或 pixabay
hide_config = ${HIDE_CONFIG:-false}
# 多把 Key 以逗號分隔；這裡自動將單一 Key 包裝成陣列
pexels_api_keys = ["${PEXELS_API_KEY}"]
pixabay_api_keys = ["${PIXABAY_API_KEY}"]

# Azure 語音（與官方範例一致的鍵名）
[azure]
speech_key = "${AZURE_SPEECH_KEY}"
speech_region = "${AZURE_SPEECH_REGION}"

# UI 區塊
[ui]
hide_log = ${UI_HIDE_LOG:-false}
EOL

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
export STREAMLIT_SERVER_PORT=${PORT:-7860}
export STREAMLIT_SERVER_ADDRESS=0.0.0.0
export STREAMLIT_BROWSER_GATHERUSAGESTATS=false

# 3. 啟動應用程式（自動偵測：優先 FastAPI/uvicorn，其次 Streamlit WebUI）
echo "啟動 MoneyPrinterTurbo...（請用你的 hf.space 公開網址開啟，不要用 0.0.0.0）"

# 先偵測官方完整版本（FastAPI + Uvicorn）
if [ -f "/app/app/asgi.py" ]; then
  echo "偵測到官方完整版本（FastAPI/Uvicorn），使用 Uvicorn 啟動..."
  exec uvicorn app.asgi:app --host 0.0.0.0 --port ${PORT:-7860} --log-level info
fi

# 否則退回到我們的 Streamlit WebUI（多入口自動偵測）
ENTRY=""
if [ -f "/app/webui/Main.py" ]; then
  ENTRY="/app/webui/Main.py"
elif [ -f "/app/webui/main.py" ]; then
  ENTRY="/app/webui/main.py"
elif [ -f "/app/webui/app.py" ]; then
  ENTRY="/app/webui/app.py"
elif [ -f "/app/app.py" ]; then
  ENTRY="/app/app.py"
elif [ -f "/app/main.py" ]; then
  ENTRY="/app/main.py"
else
  echo "找不到常見的入口檔 (webui/Main.py, webui/main.py, webui/app.py, app.py, main.py)。列出 /app 與 /app/webui 供排查："
  ls -la /app || true
  ls -la /app/webui || true
  echo "未能自動找到入口，請確認上傳的 mpt_app.tar.gz 內含 WebUI 或 FastAPI 入口檔。"
  exit 1
fi

exec streamlit run "$ENTRY" --server.port=${STREAMLIT_SERVER_PORT} --server.address=${STREAMLIT_SERVER_ADDRESS} --server.headless true