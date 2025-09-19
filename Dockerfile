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

# 生成最小可用的 webui 應用（避免 Space 倉庫缺少 webui 目錄導致 COPY 失敗）
RUN mkdir -p /app/webui && \
    printf '' > /app/webui/Main.py && \
    echo 'import streamlit as st' >> /app/webui/Main.py && \
    echo 'import time' >> /app/webui/Main.py && \
    echo '' >> /app/webui/Main.py && \
    echo 'st.set_page_config(page_title="MoneyPrinterTurbo 影片生成器", page_icon="🤖", layout="wide")' >> /app/webui/Main.py && \
    echo 'st.title("🤖 MoneyPrinterTurbo 影片生成器")' >> /app/webui/Main.py && \
    echo 'st.markdown("---")' >> /app/webui/Main.py && \
    echo '' >> /app/webui/Main.py && \
    echo 'with st.container():' >> /app/webui/Main.py && \
    echo '    st.header("🎬 影片參數設定")' >> /app/webui/Main.py && \
    echo '    col1, col2 = st.columns(2)' >> /app/webui/Main.py && \
    echo '    with col1:' >> /app/webui/Main.py && \
    echo '        video_subject = st.text_input("📋 影片主題", placeholder="請輸入影片主題或關鍵詞")' >> /app/webui/Main.py && \
    echo '        video_language = st.selectbox("🌐 影片語言", ["中文", "English", "Auto Detect"]) ' >> /app/webui/Main.py && \
    echo '    with col2:' >> /app/webui/Main.py && \
    echo '        video_length = st.selectbox("⏱️ 影片長度", ["短 (30-60秒)", "中 (1-3分鐘)", "長 (3-5分鐘)"])' >> /app/webui/Main.py && \
    echo '        video_aspect = st.selectbox("📱 影片比例", ["9:16 豎屏", "16:9 橫屏", "1:1 方形"]) ' >> /app/webui/Main.py && \
    echo '' >> /app/webui/Main.py && \
    echo 'st.markdown("---")' >> /app/webui/Main.py && \
    echo '' >> /app/webui/Main.py && \
    echo 'col1, col2, col3 = st.columns([1, 2, 1])' >> /app/webui/Main.py && \
    echo 'with col2:' >> /app/webui/Main.py && \
    echo '    if st.button("🚀 開始生成影片", type="primary", use_container_width=True):' >> /app/webui/Main.py && \
    echo '        if not video_subject:' >> /app/webui/Main.py && \
    echo '            st.error("❌ 請先輸入影片主題！")' >> /app/webui/Main.py && \
    echo '        else:' >> /app/webui/Main.py && \
    echo '            with st.spinner("🎬 正在生成影片，請稍候..."):' >> /app/webui/Main.py && \
    echo '                progress_bar = st.progress(0)' >> /app/webui/Main.py && \
    echo '                for i in range(100):' >> /app/webui/Main.py && \
    echo '                    time.sleep(0.02)' >> /app/webui/Main.py && \
    echo '                    progress_bar.progress(i + 1)' >> /app/webui/Main.py && \
    echo '                st.success("✅ 影片生成完成！(Demo)")' >> /app/webui/Main.py && \
    echo '                st.info("這是示範版本，請於後續整合真實生成流程。")' >> /app/webui/Main.py

# 安裝 Python 相依套件
RUN pip install --no-cache-dir -r /app/requirements.txt

# 手動補安裝 playwright 再下載瀏覽器
RUN pip install --no-cache-dir playwright && playwright install chromium

# 暴露連接埠（HF Spaces 會注入 PORT）
EXPOSE ${PORT:-7860}

# 複製啟動腳本
COPY startup.sh /app/startup.sh
RUN chmod +x /app/startup.sh

# 讓非 root 執行者可寫入 /app（HF Spaces 預設以非 root 身分啟動容器）
RUN chmod -R a+rwX /app

# 啟動 Streamlit
CMD ["/bin/bash", "/app/startup.sh"]

# cache-bust 2025-09-19-19-28