#!/bin/bash

# 創建必要的目錄
mkdir -p storage/temp
mkdir -p resource/fonts
mkdir -p resource/songs
mkdir -p resource/images

# 設置環境變數
export STREAMLIT_SERVER_PORT=${PORT:-8501}
export STREAMLIT_SERVER_ADDRESS=0.0.0.0

# 啟動 Streamlit
echo "啟動 MoneyPrinterTurbo..."
streamlit run webui/Main.py --server.port=${STREAMLIT_SERVER_PORT} --server.address=${STREAMLIT_SERVER_ADDRESS} --server.headless true