FROM dart:stable

WORKDIR /app/server
COPY server/pubspec.yaml .
RUN dart pub get

COPY server/server.dart .
CMD ["dart", "server.dart"]
