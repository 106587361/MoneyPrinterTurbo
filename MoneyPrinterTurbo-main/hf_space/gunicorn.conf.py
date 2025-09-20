# gunicorn 雙行程配置
# 端口由 HF 注入 ENV:PORT，預設 7860
bind = "0.0.0.0:" + str(os.getenv("PORT", "7860"))
workers = 1                     # 單 worker 即可
timeout = 120                   # 影片生成可能慢
worker_class = "sync"           # reverse_proxy.py 用同步邏輯即可
proc_name = "moneyprinter_combo"
pidfile = "/tmp/gunicorn.pid"

# 兩支行程：streamlit 與 fastapi
# 啟動後由 reverse_proxy.py 根據路徑分發