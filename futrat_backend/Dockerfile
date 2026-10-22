FROM python:3.15.0-slim@sha256:f48fda6d59b2b3437781d1c3ccf4aa0e26ae871de3cdd758b49ab45ee7291619 AS base

ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1
WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir --require-hashes --only-binary=:all: -r requirements.txt \
    && pip check

FROM base AS test
COPY requirements-dev.txt .
RUN pip install --no-cache-dir --require-hashes --only-binary=:all: -r requirements-dev.txt \
    && pip check
COPY app ./app
COPY tests ./tests
COPY pytest.ini .
CMD ["python", "-m", "pytest", "-q"]

FROM base AS production
ENV APP_ENV=production
COPY app ./app
RUN groupadd --system --gid 10001 futrat \
    && useradd --uid 10001 --gid futrat --no-create-home --shell /usr/sbin/nologin futrat
USER 10001:10001
EXPOSE 8000
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]

FROM base AS runtime
COPY app ./app
EXPOSE 8000
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
