FROM python:3.10-slim

ENV PYTHONUNBUFFERED=1 \
    NLTK_DATA=/usr/share/nltk_data

WORKDIR /app

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      git \
      wget \
      curl \
      ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt /app/

RUN pip install --no-cache-dir -r requirements.txt

COPY . /app

RUN mkdir -p /usr/share/nltk_data && \
    python -m nltk.downloader -d /usr/share/nltk_data punkt wordnet

EXPOSE 8080

CMD ["python", "chatdemo.py"]

#test