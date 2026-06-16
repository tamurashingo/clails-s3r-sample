# clails-s3r-sample

A multi-user TODO application built with [clails](https://github.com/tamurashingo/clails) (REST API server) and [cl-s3r](https://github.com/tamurashingo/cl-s3r) (BFF / SSR frontend), running on PostgreSQL via Docker Compose.

## Architecture

```
  Browser            cl-s3r (:3000)       clails (:5000)     PostgreSQL (:5432)
     │                     │                    │                     │
     │  GET /login         │                    │                     │
     │────────────────────►│                    │                     │
     │                     │ render HTML (SSR)  │                     │
     │◄────────────────────│                    │                     │
     │                     │                    │                     │
     │  POST /login        │                    │                     │
     │────────────────────►│                    │                     │
     │                     │ POST /api/sessions │                     │
     │                     │───────────────────►│                     │
     │                     │                    │  SELECT FROM users  │
     │                     │                    │────────────────────►│
     │                     │                    │◄────────────────────│
     │                     │◄───────────────────│                     │
     │  302 /todos         │                    │                     │
     │◄────────────────────│                    │                     │
     │                     │                    │                     │
     │  GET /todos         │                    │                     │
     │────────────────────►│                    │                     │
     │                     │ GET /api/todos     │                     │
     │                     │───────────────────►│                     │
     │                     │                    │  SELECT FROM todos  │
     │                     │                    │────────────────────►│
     │                     │                    │◄────────────────────│
     │                     │◄───────────────────│                     │
     │  render HTML (SSR)  │                    │                     │
     │◄────────────────────│                    │                     │
     │                     │                    │                     │
```

- **cl-s3r** — BFF / SSR frontend on port 3000; renders pages server-side and proxies form submissions to the API
- **clails** — REST API server on port 5000, backed by PostgreSQL

## Prerequisites

- Docker
- Docker Compose

## Getting Started

### 1. Build images

```bash
make image
```

### 2. Set up the database

```bash
make up.db          # start the PostgreSQL container
make db.create      # create the database
make db.migrate     # run migrations
```

### 3. Start all services

```bash
make up
```

Open http://localhost:3000 in your browser.

## Testing

### Prerequisites

Build the Docker images and start the database before running tests.

```bash
make image       # build Docker images
make up.db       # start the PostgreSQL container
```

### Run all tests

```bash
make test
```

This runs `test.db.create`, `test.db.migrate`, `test.server`, and `test.client` in sequence.

### Step-by-step

```bash
make test.db.create    # create the test database
make test.db.migrate   # run migrations on the test database

make test.server       # run server tests
make test.client       # run client tests
```

## Make Targets

| Target | Description |
|---|---|
| `make image` | Build all Docker images |
| `make image.server` | Build the server image |
| `make image.client` | Build the client image |
| `make image.rebuild` | Build all images without cache |
| `make image.server.rebuild` | Build the server image without cache |
| `make image.client.rebuild` | Build the client image without cache |
| `make up.db` | Start the database container |
| `make db.create` | Create the database |
| `make db.migrate` | Run database migrations |
| `make up` | Start all services |
| `make up.server` | Start db + server |
| `make up.client` | Start client |
| `make down` | Stop all services |
| `make logs` | Tail logs from all services |
| `make test` | Run all tests (server + client) |
| `make test.db.create` | Create the test database |
| `make test.db.migrate` | Run migrations on the test database |
| `make test.server` | Run server tests |
| `make test.client` | Run client tests |

## API Endpoints

| Method | Path | Auth | Description |
|---|---|---|---|
| POST | `/api/users` | — | Sign up |
| POST | `/api/sessions` | — | Log in (returns token) |
| DELETE | `/api/sessions` | Bearer | Log out |
| GET | `/api/todos` | Bearer | List TODOs |
| POST | `/api/todos` | Bearer | Create TODO |
| GET | `/api/todos/:ulid` | Bearer | Get TODO |
| PUT | `/api/todos/:ulid` | Bearer | Update TODO |
| PUT | `/api/todos/:ulid/complete` | Bearer | Mark TODO as done |
| DELETE | `/api/todos/:ulid` | Bearer | Delete TODO |

## Pages

| Path | Description |
|---|---|
| `/login` | Log in |
| `/signup` | Create an account |
| `/todos` | TODO list with inline new-TODO modal |
| `/todo/:ulid` | TODO detail / edit |
| `/todo/new` | New TODO form (standalone) |

## License

MIT License

Copyright (c) 2026 tamurashingo

