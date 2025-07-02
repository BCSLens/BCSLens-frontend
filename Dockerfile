# ✅ ใช้ Flutter 3.22.0 ซึ่งมาพร้อม Dart 3.7.2
FROM ghcr.io/cirruslabs/flutter:3.22.0

WORKDIR /app

COPY . .

RUN flutter config --enable-web
RUN flutter pub get

EXPOSE 8080

CMD ["flutter", "run", "-d", "web-server", "--web-port=8080", "--web-hostname=0.0.0.0"]
