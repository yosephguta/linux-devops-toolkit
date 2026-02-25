FROM nginx:alpine

# Build arguments
ARG BUILD_DATE
ARG VERSION
ARG VCS_REF

# OCI image labels (industry standard)
LABEL org.opencontainers.image.created=$BUILD_DATE \
      org.opencontainers.image.version=$VERSION \
      org.opencontainers.image.revision=$VCS_REF \
      org.opencontainers.image.title="yoseph-site" \
      org.opencontainers.image.description="Simple nginx production deployment practice" \
      org.opencontainers.image.source="https://github.com/yosephguta/linux-devops-toolkit"

COPY index.html /usr/share/nginx/html/index.html