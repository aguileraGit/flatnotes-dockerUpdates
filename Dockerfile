ARG BUILD_DIR=/build

# Build Container
FROM --platform=$BUILDPLATFORM node:20-alpine AS build

ARG BUILD_DIR

RUN mkdir ${BUILD_DIR}
WORKDIR ${BUILD_DIR}

COPY package.json package-lock.json vite.config.js .htmlnanorc ./
RUN npm ci

COPY client ./client
RUN npm run build

# Runtime Container
FROM python:3.11-slim-bullseye

ARG BUILD_DIR

ENV PUID=1000
ENV PGID=1000
ENV EXEC_TOOL=gosu

ENV APP_PORT=8080

ENV APP_PATH=/app
ENV FLATNOTES_PATH=/data

RUN mkdir -p ${APP_PATH}
RUN mkdir -p ${FLATNOTES_PATH}

RUN apt update && apt install -y \
    curl \
    gosu \
    && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir pipenv

WORKDIR ${APP_PATH}

COPY LICENSE Pipfile Pipfile.lock ./
RUN pipenv install --deploy --ignore-pipfile --system && \
    pipenv --clear

COPY server ./server
COPY --from=build ${BUILD_DIR}/client/dist ./client/dist

VOLUME /data
# Is probably not needed per https://docs.docker.com/reference/dockerfile/#expose
EXPOSE ${APP_PORT}/tcp
HEALTHCHECK --interval=60s --timeout=10s CMD curl -f http://localhost:${APP_PORT}/health || exit 1

COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh
ENTRYPOINT [ "/entrypoint.sh" ]
