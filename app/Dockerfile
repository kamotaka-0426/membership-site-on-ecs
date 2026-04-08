# --- Stage 1 ---
FROM python:3.11-slim AS builder
WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir --target=/app -r requirements.txt

COPY . .

# --- Stage 2 ---
FROM gcr.io/distroless/python3-debian12
WORKDIR /app

COPY --from=builder /app /app

ENV PYTHONPATH=/app

EXPOSE 8000
ENTRYPOINT ["python3", "main.py"]