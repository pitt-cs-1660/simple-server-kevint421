#build stage
FROM python:3.12 AS builder

COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv

WORKDIR /app

COPY pyproject.toml .

RUN uv venv && \
    uv pip install -r pyproject.toml

COPY cc_simple_server ./cc_simple_server
COPY tests ./tests

RUN touch cc_simple_server/__init__.py

#final stage
FROM python:3.12-slim

WORKDIR /app

COPY --from=builder /app/.venv /app/.venv

COPY --from=builder /app/cc_simple_server ./cc_simple_server

COPY --from=builder /app/tests ./tests

RUN useradd -m -u 1000 appuser && \
    chown -R appuser:appuser /app

USER appuser

ENV PATH="/app/.venv/bin:$PATH"
ENV PYTHONPATH="/app"

EXPOSE 8000

CMD ["uvicorn", "cc_simple_server.server:app", "--host", "0.0.0.0", "--port", "8000"]