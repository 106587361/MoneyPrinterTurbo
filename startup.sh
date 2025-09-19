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

# 以環境變數帶入預設值，並正規化布林值，避免 TOML 解析錯誤
LLM_PROVIDER=${LLM_PROVIDER:-openai}
SUBTITLE_PROVIDER=${SUBTITLE_PROVIDER:-edge}
VIDEO_SOURCE=${VIDEO_SOURCE:-pexels}
HIDE_CONFIG=${HIDE_CONFIG:-false}
UI_HIDE_LOG=${UI_HIDE_LOG:-false}

# 將多種真/假表示法轉成 TOML 需要的小寫 true/false
_to_bool_lc() {
  local v="${1}"
  v="${v,,}"  # to lowercase
  case "$v" in
    1|true|yes|on) echo true ;;
    0|false|no|off|"") echo false ;;
    *) echo false ;;
  esac
}
HIDE_CONFIG_TOML=$(_to_bool_lc "$HIDE_CONFIG")
UI_HIDE_LOG_TOML=$(_to_bool_lc "$UI_HIDE_LOG")

# 將字串轉成 TOML 單引號字面量可接受的形式：
# 1) 刪除 CR 字元  2) 單引號 -> 兩個單引號
_safe_toml_literal() {
  local s="$1"
  s="${s//$'\r'/}"
  s="${s//\'/''}"
  printf "%s" "$s"
}

# 為所有字串型設定預先做轉義
LLM_PROVIDER_S=$(_safe_toml_literal "$LLM_PROVIDER")
SUBTITLE_PROVIDER_S=$(_safe_toml_literal "$SUBTITLE_PROVIDER")
OPENAI_API_KEY_S=$(_safe_toml_literal "$OPENAI_API_KEY")
OPENAI_API_BASE_S=$(_safe_toml_literal "$OPENAI_API_BASE")
GEMINI_API_KEY_S=$(_safe_toml_literal "$GEMINI_API_KEY")
ENDPOINT_S=$(_safe_toml_literal "$ENDPOINT")
VIDEO_SOURCE_S=$(_safe_toml_literal "$VIDEO_SOURCE")
PEXELS_API_KEY_S=$(_safe_toml_literal "$PEXELS_API_KEY")
PIXABAY_API_KEY_S=$(_safe_toml_literal "$PIXABAY_API_KEY")
AZURE_SPEECH_KEY_S=$(_safe_toml_literal "$AZURE_SPEECH_KEY")
AZURE_SPEECH_REGION_S=$(_safe_toml_literal "$AZURE_SPEECH_REGION")

cat > ./config.toml <<EOL
# 根層：模型與字幕設定
llm_provider = '${LLM_PROVIDER_S}'
subtitle_provider = '${SUBTITLE_PROVIDER_S}'  # edge 或 whisper

# OpenAI / 相容 API
openai_api_key = '${OPENAI_API_KEY_S}'
openai_base_url = '${OPENAI_API_BASE_S}'

# Gemini
gemini_api_key = '${GEMINI_API_KEY_S}'

# 任務下載端點（可留空）
endpoint = '${ENDPOINT_S}'

# 應用設定區塊
[app]
video_source = '${VIDEO_SOURCE_S}'  # pexels 或 pixabay
hide_config = ${HIDE_CONFIG_TOML}
# 多把 Key 以逗號分隔；這裡自動將單一 Key 包裝成陣列
pexels_api_keys = ['${PEXELS_API_KEY_S}']
pixabay_api_keys = ['${PIXABAY_API_KEY_S}']

# Azure 語音（與官方範例一致的鍵名）
[azure]
speech_key = '${AZURE_SPEECH_KEY_S}'
speech_region = '${AZURE_SPEECH_REGION_S}'

# UI 區塊
[ui]
hide_log = ${UI_HIDE_LOG_TOML}
EOL

# 預覽前 80 行設定檔，方便除錯
echo "--- /app/config.toml (preview first 80 lines) ---"
head -n 80 ./config.toml || true

# 環境變數（提供給手動啟動或相容邏輯）
export STREAMLIT_SERVER_PORT=${PORT:-7860}
export STREAMLIT_SERVER_ADDRESS=0.0.0.0
export STREAMLIT_BROWSER_GATHERUSAGESTATS=false

# 3. 啟動應用程式（自動偵測：優先 Streamlit WebUI，其次 FastAPI/uvicorn）
echo "啟動 MoneyPrinterTurbo...（請用你的 hf.space 公開網址開啟，不要用 0.0.0.0）"

# 先偵測 WebUI（Streamlit）
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
fi

if [ -n "$ENTRY" ]; then
  echo "偵測到 WebUI 入口（$ENTRY），使用 Streamlit 啟動..."
  exec streamlit run "$ENTRY" --server.port=${STREAMLIT_SERVER_PORT} --server.address=${STREAMLIT_SERVER_ADDRESS} --server.headless true
fi

# 若無 WebUI，才偵測官方完整版本（FastAPI + Uvicorn）
if [ -f "/app/app/asgi.py" ]; then
  echo "未偵測到 WebUI，偵測到官方完整版本（FastAPI/Uvicorn），使用 Uvicorn 啟動..."
  exec uvicorn app.asgi:app --host 0.0.0.0 --port ${PORT:-7860} --log-level info
fi

# 兩者皆無，輸出提示並退出
echo "找不到 WebUI 或 FastAPI 入口。列出 /app 與 /app/webui 供排查："
ls -la /app || true
ls -la /app/webui || true
echo "未能自動找到入口，請確認上傳的 mpt_app.tar.gz 內含 WebUI 或 FastAPI 入口檔。"
exit 1