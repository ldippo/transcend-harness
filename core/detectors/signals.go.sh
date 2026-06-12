#!/usr/bin/env sh
# Go signal probe. Read-only. Prints `key=value` lines.
# Usage: signals.go.sh PROJECT_DIR
# POSIX sh.

DIR="${1:-$(pwd)}"
GOMOD="$DIR/go.mod"

has_go_mod=0
has_http_framework=0
has_golangci=0
go_module=""

if [ -f "$GOMOD" ]; then
  has_go_mod=1
  go_module="$(awk '/^module / { print $2; exit }' "$GOMOD")"
  # Common HTTP/service frameworks strengthen the "service" assumption.
  if grep -qE 'gin-gonic/gin|labstack/echo|go-chi/chi|gofiber/fiber|gorilla/mux|grpc' "$GOMOD" 2>/dev/null; then
    has_http_framework=1
  fi
fi
for f in "$DIR/.golangci.yml" "$DIR/.golangci.yaml" "$DIR/.golangci.toml"; do
  [ -f "$f" ] && has_golangci=1 && break
done

printf 'has_go_mod=%s\n' "$has_go_mod"
printf 'has_http_framework=%s\n' "$has_http_framework"
printf 'has_golangci=%s\n' "$has_golangci"
printf 'go_module=%s\n' "$go_module"
