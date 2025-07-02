# BCSLens-frontend/Dockerfile
FROM dart:3.7 AS build-env

# Install Flutter
RUN git clone https://github.com/flutter/flutter.git /flutter
ENV PATH="/flutter/bin:/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Enable web support
RUN flutter channel stable && flutter upgrade && flutter config --enable-web

# Copy app
WORKDIR /app
COPY . .

# Install dependencies & build
RUN flutter pub get
RUN flutter build web --release
