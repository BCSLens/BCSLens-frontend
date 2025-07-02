# Use the official Flutter base image
FROM cirrusci/flutter:latest

# Set the working directory inside the container
WORKDIR /app

# Copy the Flutter project into the container
COPY . .

# Enable Flutter web (if needed)
RUN flutter config --enable-web

# Get dependencies
RUN flutter pub get

# Expose the necessary port (if running a web app)
EXPOSE 8080

# Default command to run the app (adjust for your target platform)
CMD ["flutter", "run", "-d", "web-server", "--web-port=8080", "--web-hostname=0.0.0.0"]
