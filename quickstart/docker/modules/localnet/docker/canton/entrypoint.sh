#!/bin/bash

# Install Python if not already installed
if ! command -v python3 &> /dev/null; then
    echo "Installing Python environment..."
    apt-get update && apt-get install -y \
        python3 \
        python3-pip \
        python3-venv \
        python3-dev \
        build-essential \
        && rm -rf /var/lib/apt/lists/*
    
    # Create Python virtual environment
    python3 -m venv /opt/python-env
    
    # Install common Python packages
    . /opt/python-env/bin/activate && \
    pip install --upgrade pip && \
    pip install \
        requests \
        numpy \
        pandas \
        matplotlib \
        jupyter
    
    echo "Python environment installed successfully"
else
    echo "Python environment already available"
fi

# Activate Python environment for the session
export PATH="/opt/python-env/bin:$PATH"

# Execute the original Canton command with proper arguments
# The original Canton container runs: /app/bin/canton daemon --config /app/app.conf
exec /app/bin/canton daemon --config /app/app.conf "$@" 