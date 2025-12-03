# Use a stable Debian-based Python image known to work with TF wheels.
# You can change PYTHON base tag if you need a different version.
ARG PYTHON_TAG=3.10-slim-bullseye
FROM python:${PYTHON_TAG} AS base

# build args for flexibility
ARG TF_CPU_VERSION=2.12.0
ARG APP_USER=ec2-user
ARG APP_UID=1000
ARG APP_HOME=/home/${APP_USER}
ENV NLTK_DATA=/usr/share/nltk_data
ENV PYTHONUNBUFFERED=1
ENV PORT=8080

# Install OS packages required to build/use some python packages and tensorflow dependencies
# Keep them minimal. Add more if your app requires it.
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      build-essential \
      git \
      wget \
      ca-certificates \
      libatlas3-base \
      libopenblas-dev \
      liblapack-dev \
      libjpeg-dev \
      zlib1g-dev \
      libsndfile1 \
 && rm -rf /var/lib/apt/lists/*

# Create non-root user to match your EC2 user-data ownership
RUN useradd -m -u ${APP_UID} -s /bin/bash ${APP_USER} || true

WORKDIR ${APP_HOME}

# Copy project files
# Adjust as necessary; this assumes your repo root contains chatdemo.py and requirements.
COPY . ${APP_HOME}

# Ensure permissions so container user can access files (matches chown in your script)
RUN chown -R ${APP_USER}:${APP_USER} ${APP_HOME} \
 && chmod -R 755 ${APP_HOME}

# Switch to non-root user for installations where possible (pip can run as non-root)
USER ${APP_USER}

# Use per-user venv to keep environment isolated (optional but clean)
ENV VENV_PATH=${APP_HOME}/.venv
RUN python -m venv ${VENV_PATH}
ENV PATH="${VENV_PATH}/bin:${PATH}"

# Upgrade pip and wheel
RUN pip install --upgrade pip wheel

# Install python dependencies (match your user-data)
# Pin TensorFlow cpu version to the one you used in userdata.
# urllib3 and requests pinned similarly to your script.
# If you have a requirements.txt in repo, prefer that; this is a fallback.
RUN pip --disable-pip-version-check install \
      "tornado" \
      "keras" \
      "nltk" \
      "tensorflow-cpu==${TF_CPU_VERSION}" \
      "urllib3<2.0" \
      "requests<2.32"

# Download NLTK data globally (requires root). Switch to root temporarily.
USER root
RUN mkdir -p ${NLTK_DATA} \
 && python -m nltk.downloader -d ${NLTK_DATA} punkt wordnet || true \
 && chown -R ${APP_USER}:${APP_USER} ${NLTK_DATA}

# Revert to non-root user for runtime
USER ${APP_USER}
WORKDIR ${APP_HOME}

# Expose port used by your user-data (8080)
EXPOSE ${PORT}

# Simple healthcheck (tries to connect to port, requires curl)
USER root
RUN apt-get update && apt-get install -y --no-install-recommends curl && rm -rf /var/lib/apt/lists/*
USER ${APP_USER}

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD curl -fsS http://127.0.0.1:${PORT}/ || exit 1

# Default command to run the Tornado app as in your user-data.
# If your chatdemo.py accepts different flags or entrypoint, adapt accordingly.
CMD ["/home/ec2-user/.venv/bin/python", "/home/ec2-user/chatdemo.py", "--port=8080"]