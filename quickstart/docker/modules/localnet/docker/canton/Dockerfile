# Copyright (c) 2023, Digital Asset (Switzerland) GmbH and/or its affiliates. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

# Use the official Canton image as base
FROM ghcr.io/digital-asset/decentralized-canton-sync/docker/canton:0.4.20

# Switch to root user for installations
USER root

# Install system dependencies
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    build-essential \
    curl \
    wget \
    git \
    vim \
    jq \
    openssl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install grpcurl
RUN curl -L https://github.com/fullstorydev/grpcurl/releases/download/v1.9.3/grpcurl_1.9.3_linux_x86_64.tar.gz | tar -xz \
    && mv grpcurl /usr/local/bin/ \
    && chmod +x /usr/local/bin/grpcurl

# Create a Python virtual environment
RUN python3 -m venv /opt/python-env

# Activate the virtual environment and install common Python packages
RUN . /opt/python-env/bin/activate && \
    pip install --upgrade pip && \
    pip install \
        requests \
        numpy \
        pandas \
        matplotlib \
        jupyter \
        flask \
        fastapi \
        uvicorn \
        pytest \
        black \
        flake8 \
        scikit-learn

# Add the Python environment to PATH
ENV PATH="/opt/python-env/bin:$PATH"

# Create a startup script that activates Python environment and runs Canton
RUN echo '#!/bin/bash\n\
source /opt/python-env/bin/activate\n\
echo "Python environment ready!"\n\
echo "Python version: $(python --version)"\n\
echo "grpcurl version: $(grpcurl --version)"\n\
echo "jq version: $(jq --version)"\n\
echo "OpenSSL version: $(openssl version)"\n\
echo "Available Python packages:"\n\
pip list\n\
echo "Container is ready for development."\n\
exec /app/bin/canton "$@"' > /usr/local/bin/startup.sh && \
    chmod +x /usr/local/bin/startup.sh

# Set the default command
ENTRYPOINT ["/usr/local/bin/startup.sh"]
CMD ["daemon", "--config", "/app/app.conf"]
