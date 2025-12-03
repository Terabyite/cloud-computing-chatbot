# Use a small base with Python 3.9
FROM python:3.9-slim

ENV PYTHONUNBUFFERED=1 \
    DEBIAN_FRONTEND=noninteractive

WORKDIR /app

# Install minimal build deps (if needed for packages)
RUN apt-get update \
 && apt-get install -y --no-install-recommends build-essential git \
 && rm -rf /var/lib/apt/lists/*

# Install Python deps
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy app source
COPY . .

# Download NLTK data used by the bot (punkt, wordnet)
RUN python -m nltk.downloader -d /usr/share/nltk_data punkt wordnet || true

EXPOSE 8080

# Run Tornado app
CMD ["python", "chatdemo.py", "--port=8080"]