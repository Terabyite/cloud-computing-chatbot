# Use lightweight Python image — change to TF base if you want preinstalled TF
FROM python:3.10-slim

# metadata
LABEL maintainer="you@example.com"
ENV PYTHONUNBUFFERED=1 \
    POETRY_VIRTUALENVS_CREATE=false \
    NLTK_DATA=/usr/share/nltk_data

WORKDIR /app

# Install system dependencies required for many scientific packages and for docker build reliability.
# Keep packages minimal; add any extras your requirements need.
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      build-essential \
      git \
      curl \
      ca-certificates \
      wget \
      gnupg \
      libatlas-base-dev \
      && rm -rf /var/lib/apt/lists/*

# Create non-root user
ARG UNAME=app
ARG UID=1000
RUN useradd --create-home --shell /bin/bash --uid ${UID} ${UNAME} && \
    chown -R ${UNAME}:${UNAME} /app

# Copy only requirements first to leverage layer cache
COPY requirements.txt /app/requirements.txt

# Upgrade pip & install requirements
RUN python3 -m pip install --upgrade pip setuptools wheel \
    && pip install --no-cache-dir -r /app/requirements.txt

# Create global nltk data dir and download required corpora
RUN mkdir -p /usr/share/nltk_data && \
    python3 -m nltk.downloader -d /usr/share/nltk_data punkt wordnet

# Copy app source
COPY . /app
RUN chown -R ${UNAME}:${UNAME} /app

# Expose port
EXPOSE 8080

# Healthcheck (assumes your tornado root / returns 200)
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD curl -f http://127.0.0.1:8080/ || exit 1

# Run as non-root user
USER ${UNAME}

# Default command
CMD ["python3", "chatdemo.py"]