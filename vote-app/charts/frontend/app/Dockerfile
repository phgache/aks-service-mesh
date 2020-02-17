FROM python:3.7-buster as build

WORKDIR /app

RUN python3 -m venv /venv

COPY requirements.txt .
RUN /venv/bin/pip3 install --no-cache-dir -r requirements.txt

FROM python:3.7-slim-buster as run

RUN apt-get update && apt-get install wget -y && rm -rf /var/lib/apt/lists/*

COPY --from=build /venv /venv
ENV PATH=/venv/bin:$PATH

WORKDIR /app
COPY . .

EXPOSE 80
CMD ["gunicorn","--bind","0.0.0.0:80","--workers=2","--worker-class=gevent","--worker-connections=1000","--log-level=debug","main:app"]