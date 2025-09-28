# Docker Setup for FastMRZ API

This document explains how to run the FastMRZ API using Docker.

## Quick Start

### Development Mode
```bash
# Build and run in development mode with hot reload
docker-compose -f docker-compose.dev.yml up --build

# Run in background
docker-compose -f docker-compose.dev.yml up -d --build
```

### Production Mode
```bash
# Run with nginx reverse proxy
docker-compose --profile production up --build

# Run API only (without nginx)
docker-compose up --build
```

## Available Services

### Development (`docker-compose.dev.yml`)
- **fastmrz-api-dev**: FastMRZ API with hot reload enabled
- Port: 8000
- Features: Source code mounting, auto-reload

### Production (`docker-compose.yml`)
- **fastmrz-api**: FastMRZ API service
- **nginx**: Reverse proxy (optional, use `--profile production`)
- Ports: 8000 (API), 80 (nginx)

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `TESSDATA_PREFIX` | `/app/tessdata` | Path to Tesseract training data |
| `PYTHONPATH` | `/app` | Python path |
| `PYTHONUNBUFFERED` | `1` | Unbuffered Python output |
| `ENVIRONMENT` | `production` | Environment mode |

## Health Checks

The API includes health check endpoints:
- `GET /healthz` - Basic health check
- `GET /readyz` - Readiness check

## API Endpoints

- `POST /api/mrz` - Extract MRZ data from images
- `GET /docs` - API documentation (Swagger UI)
- `GET /openapi.json` - OpenAPI schema

## File Upload Limits

- Maximum file size: 10MB
- Supported formats: JPEG, PNG
- Rate limiting: 10 requests/second per IP

## Building Custom Images

```bash
# Build the image
docker build -t fastmrz-api .

# Run the container
docker run -p 8000:8000 fastmrz-api
```

## Troubleshooting

### Common Issues

1. **Tesseract not found**: Ensure `tessdata` directory is properly mounted
2. **Permission denied**: Check file permissions in mounted volumes
3. **Port conflicts**: Change port mapping in docker-compose files

### Logs

```bash
# View logs
docker-compose logs -f fastmrz-api

# View logs for specific service
docker-compose logs -f nginx
```

### Debugging

```bash
# Access container shell
docker-compose exec fastmrz-api bash

# Check container status
docker-compose ps
```
