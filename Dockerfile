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

# 建立工作目錄
WORKDIR /app

# 下載 requirements.txt（如存在）
RUN curl -fsSL -o requirements.txt https://raw.githubusercontent.com/106587361/MoneyPrinterTurbo/main/requirements.txt || true

# 用 git clone 取得 Streamlit 前端（純下載，不綁本機）
RUN git clone --depth 1 https://github.com/106587361/MoneyPrinterTurbo.git /tmp/mp \
    && mv /tmp/mp/webui ./webui \
    && rm -rf /tmp/mp

# 用 git clone 取得後端 API（可有可無，HF 不會報錯）
RUN git clone --depth 1 https://github.com/106587361/MoneyPrinterTurbo.git /tmp/mp2 \
    && mv /tmp/mp2/nutrition-api ./nutrition-api || true \
    && rm -rf /tmp/mp2 || true

# 安裝 Python 相依套件
RUN pip install --no-cache-dir -r requirements.txt

# 安裝 Playwright 並下載瀏覽器
RUN playwright install chromium

# 下載 config.toml（如存在）
RUN curl -fsSL -o /app/webui/.streamlit/config.toml \
    https://raw.githubusercontent.com/106587361/MoneyPrinterTurbo/main/webui/.streamlit/config.toml || true

# 暴露連接埠（HF Spaces 會注入 PORT）
EXPOSE ${PORT:-8501}

# 啟動 Streamlit
CMD ["streamlit", "run", "webui/Main.py", "--server.port=${PORT:-8501}", "--server.address=0.0.0.0"]
