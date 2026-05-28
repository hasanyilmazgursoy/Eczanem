FROM python:3.12-slim

# PYTHONDONTWRITEBYTECODE: .pyc dosyası yazılmasını önler (imaj boyutunu küçültür)
# PYTHONUNBUFFERED: stdout/stderr'ı tamponlamadan yazar — Docker log'ları anlık görünür
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# Önce bağımlılıkları kopyala; uygulama kodu değiştiğinde bu katman yeniden build edilmez
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# Güvenlik: root yerine düşük yetkili sistem kullanıcısı oluştur
RUN addgroup --system appgroup \
    && adduser --system --ingroup appgroup --no-create-home appuser \
    && chown -R appuser:appgroup /app

USER appuser

# Docker daemon'ın konteynerin sağlığını otomatik izlemesini sağlar.
# Başarısız probe → container "unhealthy" → depends_on(condition: service_healthy) bloğu çalışır.
HEALTHCHECK --interval=30s --timeout=10s --start-period=20s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')" || exit 1

# Worker sayısı ortam değişkeniyle override edilebilir (varsayılan: 2)
ENV WORKERS=2

# exec ile uvicorn PID 1 olur ve SIGTERM/SIGINT sinyallerini doğrudan alır
CMD ["sh", "-c", "exec uvicorn app.main:app --host 0.0.0.0 --port 8000 --workers ${WORKERS}"]

