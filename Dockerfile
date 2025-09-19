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

# 將本地 requirements 作為後備安裝清單（若上傳的完整專案內包含 requirements.txt，將優先使用該檔案）
COPY requirements.txt /app/requirements-base.txt

# 以壓縮檔方式攜帶完整專案（請上傳 mpt_app.tar.gz 到 Space 根目錄）
# Docker 的 ADD 會自動解開 tar.gz 到指定目錄 /app
ADD mpt_app.tar.gz /app/

# 安裝 Python 相依套件：若 /app/requirements.txt 存在則優先使用；否則使用本倉庫的後備清單
RUN bash -lc 'if [ -f /app/requirements.txt ]; then \
    echo "Using upstream /app/requirements.txt" && pip install --no-cache-dir -r /app/requirements.txt; \
  else \
    echo "Using fallback /app/requirements-base.txt" && pip install --no-cache-dir -r /app/requirements-base.txt; \
  fi'

# 手動補安裝 playwright 再下載瀏覽器（如無需可於上游 requirements 中移除）
RUN pip install --no-cache-dir playwright && playwright install chromium

# 暴露連接埠（HF Spaces 會注入 PORT）
EXPOSE ${PORT:-7860}

# 複製啟動腳本
COPY startup.sh /app/startup.sh
RUN chmod +x /app/startup.sh

# 讓非 root 執行者可寫入 /app（HF Spaces 預設以非 root 身分啟動容器）
RUN chmod -R a+rwX /app

# 啟動（會在 startup.sh 中自動偵測入口並啟動對應 Web UI）
CMD ["/bin/bash", "/app/startup.sh"]

# cache-bust 2025-09-20-04-05