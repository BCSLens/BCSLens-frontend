FROM dart:3.7.2 AS dart-env

# หรือ Flutter ที่ตรงเวอร์ชัน:
FROM cirrusci/flutter:3.19.2

WORKDIR /app

COPY . .

RUN flutter config --enable-web
RUN flutter pub get

EXPOSE 8080

CMD ["flutter", "run", "-d", "web-server", "--web-port=8080", "--web-hostname=0.0.0.0"]
