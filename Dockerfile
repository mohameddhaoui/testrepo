### Build image
FROM python:3.7-slim AS build

ARG TEST=false

# Save a few bytes (see: https://docs.python.org/3/using/cmdline.html#envvar-PYTHONDONTWRITEBYTECODE)
ENV PYTHONDONTWRITEBYTECODE=1

# Install poetry
RUN apt-get -y -q update && \
    apt-get install -y -q curl && \
    curl -sSL https://raw.githubusercontent.com/python-poetry/poetry/master/get-poetry.py | python -
ENV PATH=$PATH:/root/.poetry/bin

# Install Python dependencies. We don't install dev dependencies as we don't need
# them at runtime. Though we need them to run the tests...
WORKDIR /idp
COPY pyproject.toml .
COPY poetry.lock .
RUN poetry config virtualenvs.in-project true && \
    poetry install $([ $TEST = true ] || echo "--no-dev") --no-root --no-interaction

# Copy application code
COPY bin bin
COPY testname testname
COPY tests tests
RUN poetry install $([ $TEST = true ] || echo "--no-dev") --no-interaction

### Runtime image
FROM python:3.7-slim

WORKDIR /idp
COPY --from=build /idp/ .

# Activate virtualenv
ENV VIRTUAL_ENV=/idp/.venv
ENV PATH=$VIRTUAL_ENV/bin:$PATH

ENTRYPOINT ["pipeline"]
CMD ["--help"]
