import os

bind             = f"0.0.0.0:{os.environ.get('PORT', '8000')}"
workers          = 2  # keep within 512 MB free-tier RAM
worker_class     = "sync"
worker_tmp_dir   = "/dev/shm"
timeout          = 60
keepalive        = 5
max_requests     = 1000
max_requests_jitter = 50
accesslog        = "-"
errorlog         = "-"
loglevel         = "info"
forwarded_allow_ips = "*"
secure_scheme_headers = {"X-Forwarded-Proto": "https"}
