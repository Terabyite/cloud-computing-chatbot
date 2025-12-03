# Use lightweight Python image
FROM python:3.10-slim

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git wget curl \
    && rm -rf /var/lib/apt/lists/*

# Copy project files
COPY . /app

# Install required Python deps
RUN pip install --no-cache-dir -r requirements.txt

# Download required NLTK datasets
RUN python3 - <<EOF
import nltk
nltk.download('punkt')
nltk.download('wordnet')
EOF

# Expose application port
EXPOSE 8080

# Run the chatbot
CMD ["python3", "chatdemo.py"]