# todo-server development Dockerfile
FROM fukamachi/sbcl:latest

ENV BIND_ADDRESS="0.0.0.0" \
    PORT="5000" \
    CLAILS_HOME=/app \
    PATH=${PATH}:/root/.roswell/bin:/qlot/.qlot/bin


RUN apt-get update && apt-get install -y --no-install-recommends \
  git \
  curl \
  ca-certificates \
  libpq-dev \
  postgresql-client \
  && rm -rf /var/lib/apt/lists/*

RUN ros install fukamachi/cl-dbi
RUN ros install tamurashingo/cl-dbi-connection-pool
RUN ros install tamurashingo/cl-batis
RUN ros install tamurashingo/getcmd

# install clails
ARG CLAILS_BRANCH=develop
RUN ros install tamurashingo/clails/${CLAILS_BRANCH}

RUN ros install fukamachi/clack


WORKDIR /app
COPY . .

EXPOSE 5000

ENTRYPOINT ["/bin/sh", "-c"]
CMD ["exec clails server -b ${BIND_ADDRESS} --port ${PORT}"]

