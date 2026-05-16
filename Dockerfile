# Use the official Flutter image
FROM ghcr.io/cirruslabs/flutter:stable

# Install additional tools for development including Linux Flutter dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    cmake \
    ninja-build \
    build-essential \
    pkg-config \
    libgtk-3-dev \
    clang \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /workspace

# Configure Flutter
RUN flutter config --enable-web
RUN flutter config --no-analytics
RUN flutter config --enable-linux-desktop

# Default command for development
CMD ["sleep", "infinity"]
