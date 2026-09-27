# Collecta Backend — Dockerfile for Render
# Uses the official Dart SDK image to build and run the server.

FROM dart:stable AS build

WORKDIR /app

# Copy pubspec files first for better Docker layer caching.
COPY functions/pubspec.* ./functions/
RUN cd functions && dart pub get

# Copy the rest of the source code.
COPY functions/ ./functions/

# Compile the server to a self-contained executable.
RUN cd functions && dart compile exe bin/server.dart -o bin/server

# --- Runtime stage (smaller image) ---
FROM debian:bookworm-slim

# Install CA certificates (needed for HTTPS calls to Firebase/Daraja).
RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy the compiled executable from the build stage.
COPY --from=build /app/functions/bin/server /app/server

# Render injects PORT as an environment variable.
EXPOSE 8080

CMD ["/app/server"]
