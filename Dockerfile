# 使用官方 Python 3.10 slim 映像
FROM python:3.10-slim

# 安裝系統相依套件（含 ImageMagick 7）
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    ffmpeg \
    imagemagick \
    && rm -rf /var/lib/apt/lists/*

# 不論 ImageMagick 6 或 7，找到 policy.xml 就刪除「@*」那一行
RUN sed -i '/<policy domain="path" rights="none" pattern="@\*"/d' \
    /etc/ImageMagick-*/policy.xml || true

# 複製 requirements.txt（如存在）
COPY requirements.txt* ./

# 複製 Streamlit 前端
COPY webui/ ./webui/

# 複製後端 API（如存在）
COPY nutrition-api/ ./nutrition-api/ || true

# 安裝 Python 相依套件
RUN pip install --no-cache-dir -r requirements.txt

# 安裝 Playwright 並下載瀏覽器
RUN playwright install chromium

# 下載 config.toml（如存在）
RUN curl -fsSL -o /webui/.streamlit/config.toml \
    https://raw.githubusercontent.com/106587361/MoneyPrinterTurbo/main/webui/.streamlit/config.toml || true

# 暴露連接埠（HF Spaces 會注入 PORT）
EXPOSE ${PORT:-8501}

# 啟動 Streamlit
CMD ["streamlit", "run", "webui/Main.py", "--server.port=${PORT:-8501}", "--server.address=0.0.0.0"]
