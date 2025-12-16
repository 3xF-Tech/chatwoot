# =============================================================================
# AI Engine - Production Dockerfile
# Multi-stage build for smaller image
# =============================================================================

FROM python:3.11-slim as builder

WORKDIR /app

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Poetry
RUN pip install --no-cache-dir poetry

# Copy dependency files
COPY pyproject.toml poetry.lock ./

# Export requirements (sem dev dependencies)
RUN poetry export -f requirements.txt --without-hashes --no-interaction > requirements.txt

# Production stage
FROM python:3.11-slim

WORKDIR /app

# Labels
LABEL maintainer="3xF.Tech <dev@3xf.tech>"
LABEL version="0.2.0"
LABEL description="AI Engine for Chatwoot CRM"

# Install runtime dependencies only
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq5 \
    curl \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Create non-root user
RUN useradd --create-home --shell /bin/bash aiengine
USER aiengine

# Copy requirements from builder
COPY --from=builder /app/requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir --user -r requirements.txt

# Add user bin to PATH
ENV PATH="/home/aiengine/.local/bin:${PATH}"

# Copy application code
COPY --chown=aiengine:aiengine . .

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# Expose port
EXPOSE 8000

# Default command
CMD ["python", "-m", "uvicorn", "api_gateway.main:app", "--host", "0.0.0.0", "--port", "8000"]