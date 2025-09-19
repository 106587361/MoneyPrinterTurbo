# 使用精簡版 Python 基底映像
FROM python:3.10-slim

# 常用環境變數與 pip 行為調整
ENV PIP_NO_CACHE_DIR=1 \ 
    PYTHONUNBUFFERED=1 \ 
    PATH="/root/.local/bin:${PATH}" \ 
    PYTHONPATH="${PYTHONPATH}:/root/.local/lib/python3.10/site-packages"

# 安裝系統層級依賴  
RUN apt-get update && apt-get install -y --no-install-recommends \
    git curl ffmpeg \
 && rm -rf /var/lib/apt/lists/*

# 建立工作目錄
WORKDIR /app

# 淺層 clone MoneyPrinterTurbo（加速建置）
RUN git clone --depth=1 https://github.com/harry0703/MoneyPrinterTurbo.git /app/MoneyPrinterTurbo

# 進入專案目錄
WORKDIR /app/MoneyPrinterTurbo

# 升級 pip 並安裝 Python 依賴（含 playwright）
RUN python -m pip install --upgrade pip \
 && pip install --no-cache-dir -r requirements.txt \
 && pip install --no-cache-dir playwright

# 安裝 Playwright 瀏覽器與系統依賴
RUN python -m playwright install --with-deps

# ===== 下載你的 config.toml =====
ARG CONFIG_RAW_URL="https://raw.githubusercontent.com/106587361/config/main/config.toml"
RUN curl -fSL "${CONFIG_RAW_URL}" -o ./config.toml

# 對外開放 Streamlit 埠（本地 8501；雲端環境會帶入 $PORT）
EXPOSE 8501

# 啟動 Streamlit（相容 Hugging Face Spaces 的 $PORT）
CMD ["sh","-lc","streamlit run ./webui/Main.py --server.address=0.0.0.0 --server.port=${PORT:-8501} --server.enableCORS=true --browser.gatherUsageStats=false"]
