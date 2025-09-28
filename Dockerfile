# syntax=docker/dockerfile:1
FROM python:3.11-slim

# Install system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        tesseract-ocr \
        tesseract-ocr-eng \
        libglib2.0-0 \
        libsm6 \
        libxext6 \
        libxrender1 \
        libgl1-mesa-dri \
        libgl1 \
        libgthread-2.0-0 \
        ca-certificates \
        curl && \
    rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy requirements first for better caching
COPY requirements.txt ./
COPY setup.py ./
COPY README.md ./

# Install Python dependencies
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY fastmrz/ ./fastmrz/
COPY api/ ./api/
COPY tessdata/ ./tessdata/

# Install the package in development mode
RUN pip install --no-cache-dir -e .

# Set environment variables
ENV TESSDATA_PREFIX=/app/tessdata
ENV PYTHONPATH=/app
ENV PYTHONUNBUFFERED=1

# Create non-root user
RUN useradd -m -u 1000 appuser && \
    chown -R appuser:appuser /app
USER appuser

# Health check
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/healthz || exit 1

# Expose port
EXPOSE 8000

# Run the application
CMD ["uvicorn", "api.app:app", "--host", "0.0.0.0", "--port", "8000"]