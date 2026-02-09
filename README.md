# burlh – Minimal HTTP client in Bash

`burlh` is a small Bash function that performs **HTTP GET requests** using raw TCP
sockets (`/dev/tcp`), with no external dependencies like `curl` or `wget`.

It is designed for minimal or restricted environments such as slim containers,
Kubernetes pods, recovery shells, or systems without standard networking tools.

---

## Features

- No external dependencies
- Pure Bash
- Supports:
  - URLs with or without path
  - Explicit port or default port (`80`)
  - Custom HTTP headers
- Output separation:
  - HTTP headers to `stderr`
  - Response body to `stdout`

---

## Limitations

- HTTP only (no HTTPS)
- Uses `HTTP/1.0`
- GET method only
- No redirect handling
- No chunked encoding handling

---

## Usage

Basic request
`burlh http://example.com`

With path
`burlh http://example.com/index.html`

With custom headers
```burlh http://example.com "User-Agent: burlh/1.0"

burlh http://example.com \
  "Authorization: Bearer TOKEN123"```
