FROM debian:buster as build

RUN printf "Acquire::http::Pipeline-Depth 0;\nAcquire::http::No-Cache true;\nAcquire::BrokenProxy true;" > /etc/apt/apt.conf.d/99fixbadproxy

RUN apt-get update && apt-get install -y  --no-install-recommends \
  python3.7 \
  python3.7-dev \
  python3-distutils \
  python3-pip \
  python3-setuptools \
  gcc \
  uuid-dev \
  libcap-dev \
  libpcre3-dev

COPY requirements.txt .
RUN pip3 install --no-cache-dir --no-warn-script-location --root /packages -r requirements.txt

FROM debian:buster-slim as run

RUN printf "Acquire::http::Pipeline-Depth 0;\nAcquire::http::No-Cache true;\nAcquire::BrokenProxy true;" > /etc/apt/apt.conf.d/99fixbadproxy

RUN apt-get update && apt-get install -y --no-install-recommends \
  python3 \
  python3-setuptools \
  libcap2 \
  libpython3.7 \
  && rm -rf /var/lib/apt/lists/*

ENV USER=gunicorn UID=1000 GID=1000

RUN addgroup --gid "$GID" "$USER" \
  && adduser \
  --disabled-password \
  --gecos "" \
  --ingroup "$USER" \
  --uid "$UID" \
  "$USER"

COPY --from=build /packages/usr/local /usr/local
COPY --chown=gunicorn:gunicorn . /app
WORKDIR /app

EXPOSE 8080

USER gunicorn:gunicorn

CMD ["gunicorn", \
  "--bind", \
  "0.0.0.0:8080", \
  "--workers=2", \
  "--worker-class=gevent", \
  "--worker-connections=1000", \
  "--log-level=info", \
  "--access-logfile", "-", \
  "--access-logformat", "{\"remote_ip\":\"%(h)s\",\"request_id\":\"%({X-Request-Id}i)s\",\"response_code\":\"%(s)s\",\"request_method\":\"%(m)s\",\"request_path\":\"%(U)s\",\"request_querystring\":\"%(q)s\",\"request_timetaken\":\"%(D)s\",\"response_length\":\"%(B)s\"}", \
  "app.wsgi:application"]