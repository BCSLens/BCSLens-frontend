### 🏗 Stage 1: Build Flutter Web
FROM dart:3.7 AS build-env

# Install Flutter
RUN git clone https://github.com/flutter/flutter.git /flutter
ENV PATH="/flutter/bin:/flutter/bin/cache/dart-sdk/bin:${PATH}"

RUN flutter channel stable && flutter upgrade && flutter config --enable-web

WORKDIR /app
COPY . .

RUN flutter pub get
RUN flutter build web --release

### 🌐 Stage 2: Serve with Nginx
FROM nginx:alpine

COPY --from=build-env /app/build/web /usr/share/nginx/html

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
