# Stage 1: Build Flutter Web application
FROM ghcr.io/cirruslabs/flutter:stable AS builder

WORKDIR /app

# Cache dependencies
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Copy source code and build production web bundle
COPY . .
RUN flutter analyze
RUN flutter build web --release

# Stage 2: Serve using lightweight Nginx
FROM nginx:alpine

# Clean default assets
RUN rm -rf /usr/share/nginx/html/*

# Copy compiled web app
COPY --from=builder /app/build/web /usr/share/nginx/html

# Copy nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Render dynamically sets $PORT environment variable
EXPOSE 8080
CMD ["sh", "-c", "sed -i 's/8080/'\"${PORT:-8080}\"'/g' /etc/nginx/conf.d/default.conf && nginx -g 'daemon off;'"]
