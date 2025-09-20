import os
import subprocess
import time
import signal
from flask import Flask, request, Response, send_from_directory
import requests

PORT = int(os.getenv("PORT", 7860))

# 啟動子行程：FastAPI (uvicorn)
fastapi_proc = subprocess.Popen([
    "uvicorn", "app.asgi:app",
    "--host", "127.0.0.1", "--port", "8001",
    "--log-level", "info"
])

# 啟動子行程：Streamlit
cmd_st = ["streamlit", "run", "webui/Main.py",
          "--server.port", "8002", "--server.headless", "true",
          "--server.address", "127.0.0.1"]
# 如果上游在子目錄，切過去再跑
if os.path.exists("/app/MoneyPrinterTurbo-main/mpt_app/webui/Main.py"):
    os.chdir("/app/MoneyPrinterTurbo-main/mpt_app")
streamlit_proc = subprocess.Popen(cmd_st)

app = Flask(__name__)

# 健康檢查
@app.route("/__health")
def health():
    return "OK", 200

# FastAPI 代理 /api/v1/*
@app.route("/api/v1/<path:subpath>", methods=["GET", "POST", "PUT", "DELETE"])
def proxy_api(subpath):
    url = f"http://127.0.0.1:8001/api/v1/{subpath}"
    resp = requests.request(
        method=request.method,
        url=url,
        headers={k: v for k, v in request.headers if k.lower() not in ["host"]},
        data=request.get_data(),
        cookies=request.cookies,
        allow_redirects=False,
        timeout=120
    )
    return Response(resp.content, status=resp.status_code, headers=dict(resp.headers))

# Streamlit 代理 /*
@app.route("/", defaults={"path": ""})
@app.route("/<path:path>")
def proxy_streamlit(path):
    # 靜態資源路徑微調
    if path.startswith("static/") or path.startswith("media/"):
        return send_from_directory(os.getcwd(), path)
    url = f"http://127.0.0.1:8002/{path}"
    resp = requests.request(
        method=request.method,
        url=url,
        headers={k: v for k, v in request.headers if k.lower() not in ["host"]},
        data=request.get_data(),
        cookies=request.cookies,
        allow_redirects=False,
        timeout=120
    )
    return Response(resp.content, status=resp.status_code, headers=dict(resp.headers))

def shutdown_handler(signum, frame):
    fastapi_proc.terminate()
    streamlit_proc.terminate()
    time.sleep(2)
    fastapi_proc.kill()
    streamlit_proc.kill()
    exit(0)

signal.signal(signal.SIGTERM, shutdown_handler)

if __name__ == "__main__":
    # 等待子服務起來
    time.sleep(3)
    app.run(host="0.0.0.0", port=PORT)