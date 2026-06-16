FROM fukamachi/sbcl:latest

ENV PATH=/root/.roswell/bin:$PATH

RUN apt-get update && apt-get install -y --no-install-recommends \
    git curl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN ros install tamurashingo/cl-s3r
RUN ros install rove

WORKDIR /app
COPY . .

EXPOSE 3000

ENTRYPOINT ["s3rup"]
CMD ["/app/todo-client.asd"]
