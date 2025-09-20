FROM python:3.11-slim

# 系統相依
RUN apt-get update && apt-get install -y \
    git build-essential ffmpeg curl && \
    rm -rf /var/lib/apt/lists/*

# Python 相依
COPY requirements.txt /tmp/
RUN pip install --no-cache-dir -r /tmp/requirements.txt

# 反向代理額外套件
RUN pip install --no-cache-dir flask gunicorn uvicorn[standard]

# 複製專案 & 代理腳本
WORKDIR /app
COPY . /app

# 權限
RUN chmod +x /app/reverse_proxy.py

# 7860 對外
EXPOSE 7860

# 啟動：gunicorn 掛 reverse_proxy → 同時跑 Streamlit + FastAPI
CMD ["gunicorn", "reverse_proxy:app", "-c", "gunicorn.conf.py"]