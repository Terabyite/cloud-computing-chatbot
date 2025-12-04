# Lightweight Python image
FROM python:3.10-slim

# Make Python output unbuffered (better logs)
ENV PYTHONUNBUFFERED=1

# Set working directory
WORKDIR /app

# Install system dependencies (NO libatlas-base-dev)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      build-essential \
      git \
      curl \
      ca-certificates \
      wget \
    && rm -rf /var/lib/apt/lists/*

# Copy only requirements first (better layer cache)
COPY requirements.txt /app/

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the app
COPY . /app

# Download NLTK data
RUN python - <<EOF
import nltk
nltk.download("punkt")
nltk.download("wordnet")
EOF

# Expose the Tornado port
EXPOSE 8080

# Start the chatbot
CMD ["python", "chatdemo.py"]