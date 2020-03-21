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
  python3.7 \
  libcap2 \
  libpython3.7 \
  && rm -rf /var/lib/apt/lists/*

ENV USER=uwsgi UID=1000 GID=1000

RUN addgroup --gid "$GID" "$USER" \
  && adduser \
  --disabled-password \
  --gecos "" \
  --ingroup "$USER" \
  --uid "$UID" \
  "$USER"

COPY --from=build /packages/usr/local /usr/local
COPY --chown=uwsgi:uwsgi . /app
WORKDIR /app

EXPOSE 8080

USER uwsgi:uwsgi

CMD [ "uwsgi", "--http-socket", ":8080", \
  "--uid", "1000", "--gid", "1000", \
  "--module", "main:app", "--enable-threads", "--processes", "2", "--threads", "4"]