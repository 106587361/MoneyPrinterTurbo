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

# 設定 HOME 並預設關閉 Streamlit usage stats，避免寫入到根目錄 /.streamlit
ENV HOME=/app
ENV STREAMLIT_BROWSER_GATHERUSAGESTATS=false

# 直接在映像內生成 requirements.txt（避免 HF Space 倉庫缺少檔案導致 COPY 失敗）
RUN printf "streamlit==1.28.2\nrequests==2.31.0\npillow==10.0.1\npython-dotenv==1.0.0\n" > /app/requirements.txt

# 使用本地 webui 原始碼（Space 倉庫中必須有 webui 目錄）
COPY webui /app/webui

# 安裝 Python 相依套件
RUN pip install --no-cache-dir -r /app/requirements.txt

# 手動補安裝 playwright 再下載瀏覽器
RUN pip install --no-cache-dir playwright && playwright install chromium

# 不預先下載 webui/.streamlit/config.toml，啟動時會在 /app/.streamlit 動態生成

# 暴露連接埠（HF Spaces 會注入 PORT）
EXPOSE ${PORT:-7860}

# 複製啟動腳本
COPY startup.sh /app/startup.sh
RUN chmod +x /app/startup.sh

# 讓非 root 執行者可寫入 /app（HF Spaces 預設以非 root 身分啟動容器）
RUN chmod -R a+rwX /app

# 啟動 Streamlit（使用 shell 模式，讓 ${PORT:-7860} 可被展開）
CMD ["/bin/bash", "/app/startup.sh"]

# cache-bust 2025-09-19-19-05