FROM ghcr.io/gmeligio/flutter-web:3.47.7 AS build

WORKDIR /app

USER root
RUN git config --global --add safe.directory /home/flutter/sdks/flutter
RUN chown -R $(id -u):$(id -g) /app

COPY pubspec.* ./
RUN flutter pub get

COPY . .

ARG API_BASE_URL=

RUN flutter build web \
    --release \
    --dart-define=API_BASE_URL=${API_BASE_URL}


FROM nginx:alpine

COPY --from=build /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80