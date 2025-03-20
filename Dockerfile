FROM dart:stable AS build

WORKDIR /app
COPY bin/server.dart bin/
COPY pubspec.* ./
RUN dart pub get --no-precompile
RUN dart compile exe bin/server.dart -o bin/server

FROM debian:buster-slim
COPY --from=build /runtime/ /
COPY --from=build /app/bin/server /app/bin/server
ENV PORT=8080
EXPOSE 8080
CMD ["/app/bin/server"]
