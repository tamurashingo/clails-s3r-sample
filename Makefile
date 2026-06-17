.PHONY: image image.server image.client \
        image.rebuild image.server.rebuild image.client.rebuild \
        db.create db.migrate up.db \
        up up.server up.client \
        down logs \
        test test.db.create test.db.migrate test.server test.client

# -------------------------------------------------------
# Image build
# -------------------------------------------------------
image: image.server image.client

image.server:
	docker compose build server

image.client:
	docker compose build client

image.rebuild: image.server.rebuild image.client.rebuild

image.server.rebuild:
	docker compose build --no-cache server

image.client.rebuild:
	docker compose build --no-cache client

# -------------------------------------------------------
# Start database container
# -------------------------------------------------------
up.db:
	docker compose up -d db

# -------------------------------------------------------
# Database operations (run after starting db with up.db)
# -------------------------------------------------------
db.create:
	docker compose run --rm --entrypoint clails server db:create

db.migrate:
	docker compose run --rm --entrypoint clails server db:migrate

# -------------------------------------------------------
# Start services
# -------------------------------------------------------
up:
	docker compose up -d

up.server:
	docker compose up -d db server

up.client:
	docker compose up -d client

# -------------------------------------------------------
# Miscellaneous
# -------------------------------------------------------
down:
	docker compose down

logs:
	docker compose logs -f



# -------------------------------------------------------
# Test
# -------------------------------------------------------
test: test.db.create test.db.migrate test.server test.client
test.db.create:
	docker compose  run --rm \
	  -e CLAILS_ENV=test \
	  -e CLAILS_DB_NAME=todo_test \
	  --entrypoint clails server db:create

test.db.migrate:
	docker compose run --rm \
	  -e CLAILS_ENV=test \
	  -e CLAILS_DB_NAME=todo_test \
	  --entrypoint clails server db:migrate

test.server:
	docker compose run --rm \
	  -e CLAILS_ENV=test \
	  -e CLAILS_DB_NAME=todo_test \
	  --entrypoint clails server test

test.client:
	docker compose run --rm --no-deps \
	  -e CL_SOURCE_REGISTRY=/ext/cl-s3r//:/app//: \
	  -v $(abspath $(CURDIR)/../cl-s3r):/ext/cl-s3r \
	  --entrypoint rove client /app/todo-client.asd
