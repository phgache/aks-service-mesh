from flask import Flask, jsonify, request, session, render_template, redirect, url_for
from flask_api import status
import os
import random
import socket
import sys
import requests
import logging
from flask_opentracing import FlaskTracing
from elasticapm.contrib.flask import ElasticAPM
from elasticapm.handlers.logging import LoggingHandler
from elasticapm.contrib.opentracing import Tracer
from opentracing.propagation import Format

app = Flask(__name__)

# configure to use ELASTIC_APM in your application's settings from elasticapm.contrib.flask import ElasticAPM
app.config['ELASTIC_APM'] = {
    'SERVICE_NAME': 'frontend',
    'SECRET_TOKEN': '78n6rh8nlp4ls96zk7cspk8h',
    'SERVER_URL': 'http://apmserver-apm-http.elastic-system.svc.cluster.local:8200'
}
apm = ElasticAPM(app, logging=True)

# Load configurations from environment or config file
app.config.from_pyfile('config_file.cfg')

if __name__ != '__main__':
    handler = LoggingHandler(client=apm.client)
    handler.setLevel(logging.DEBUG)
    app.logger.addHandler(handler)

if ("VOTE1VALUE" in os.environ and os.environ['VOTE1VALUE']):
    button1 = os.environ['VOTE1VALUE']
else:
    button1 = app.config['VOTE1VALUE']

if ("VOTE2VALUE" in os.environ and os.environ['VOTE2VALUE']):
    button2 = os.environ['VOTE2VALUE']
else:
    button2 = app.config['VOTE2VALUE']

if ("TITLE" in os.environ and os.environ['TITLE']):
    title = os.environ['TITLE']
else:
    title = app.config['TITLE']

if ("FRONTEND_VERSION" in os.environ and os.environ['FRONTEND_VERSION']):
    frontend_version = os.environ['FRONTEND_VERSION']
else:
    frontend_version = 'local'

base_url = os.environ['BACKEND_BASE_URL']


def get_hits_count(id):
    with tracer.start_span('get_hits_count_{}'.format(id)) as span:
        headers = getForwardHeaders(request, span)
        url = base_url + '/' + str(id)
        try:
            result = requests.get(url, headers=headers)
            result.raise_for_status()
            resp = result.json()
            span.log_kv({'requests': url, 'result': result, 'response': resp})
            return resp['count'], resp['backendVersion']
        except Exception as e:
            span.set_tag('error', 'true')
            span.log_kv({'requests': url, 'exception': e})
            raise


def add_hits_count(id):
    with tracer.start_span('add_hits_count_{}'.format(id)) as span:
        headers = getForwardHeaders(request, span)
        url = base_url
        try:
            result = requests.post(url, json={'id': id}, headers=headers)
            span.log_kv({'requests': url, 'response': result})
            result.raise_for_status()
        except Exception as e:
            span.set_tag('error', 'true')
            span.log_kv({'requests': url, 'exception': e})
            raise


def reset_hits_count(id):
    with tracer.start_span('reset_hits_count_{}'.format(id)) as span:
        headers = getForwardHeaders(request, span)
        url = base_url + '/{:d}/'.format(id)
        try:
            result = requests.delete(url, headers=headers)
            span.log_kv({'requests': url, 'response': result})
            result.raise_for_status()
        except Exception as e:
            span.set_tag('error', 'true')
            span.log_kv({'requests': url, 'exception': e})
            raise


# Change title to host name to demo NLB
if app.config['SHOWHOST'] == "true":
    title = socket.gethostname()


@app.route('/status/healthz')
def healthz():
    return "OK", status.HTTP_200_OK


@app.route('/status/readyz')
def readyz():
    return "OK", status.HTTP_200_OK


@app.route('/', methods=['GET', 'POST'])
def index():
    try:
        if request.method == 'POST':
            if request.form['vote'] == 'reset':
                # Empty table and return results
                reset_hits_count(1)
                reset_hits_count(2)
            else:
                # Insert vote result into DB
                vote = request.form['vote']
                print(vote)
                if vote == button1:
                    add_hits_count(1)
                if vote == button2:
                    add_hits_count(2)

        # Get current values
        vote1, v1version = get_hits_count(1)
        vote2, v2version = get_hits_count(2)

        with tracer.start_span('render_template') as render_span:
            return render_template("index.html", value1=int(vote1), value2=int(vote2), button1=button1, button2=button2, title=title, frontend_version=frontend_version, v1_backend_version=v1version, v2_backend_version=v2version)
    except Exception as e:
        return render_template("error.html", title=title, error=e.args[0]), status.HTTP_503_SERVICE_UNAVAILABLE


def getForwardHeaders(request, span):
    headers = {}

    # x-b3-*** headers can be populated using the opentracing span
    carrier = {}
    tracer.inject(
        span_context=span.context,
        format=Format.HTTP_HEADERS,
        carrier=carrier)

    headers.update(carrier)

    # We handle other (non x-b3-***) headers manually
    if 'user' in session:
        headers['end-user'] = session['user']

    incoming_headers = ['x-request-id']

    # Add user-agent to headers manually
    if 'user-agent' in request.headers:
        headers['user-agent'] = request.headers.get('user-agent')

    for ihdr in incoming_headers:
        val = request.headers.get(ihdr)
        if val is not None:
            headers[ihdr] = val
            # print "incoming: "+ihdr+":"+val

    return headers

def init_tracer():
    opentracing_tracer = Tracer()
    tracing = FlaskTracing(opentracing_tracer, True, app)
    return opentracing_tracer


tracer = init_tracer()

if __name__ == "__main__":
    app.run(port=4000)
