from django.http import HttpResponseRedirect
from django.shortcuts import render
from django.views import View
from django.conf import settings
from django.http import HttpResponseServerError

import requests
from flask_opentracing import FlaskTracing
from elasticapm.contrib.flask import ElasticAPM
from elasticapm.handlers.logging import LoggingHandler
from elasticapm.contrib.opentracing import Tracer
from opentracing.propagation import Format

from .forms import VoteForm

tracer = Tracer()

def get_hits_count(id):
	with tracer.start_span('get_hits_count_{}'.format(id)) as span:
		# headers = getForwardHeaders(request, span)
		url = settings.BACKEND_BASE_URL + '/' + str(id)
		try:
			result = requests.get(url)
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
		# headers = getForwardHeaders(request, span)
		url = settings.BACKEND_BASE_URL
		try:
			result = requests.post(url, json={'id': id})
			span.log_kv({'requests': url, 'response': result})
			result.raise_for_status()
		except Exception as e:
			span.set_tag('error', 'true')
			span.log_kv({'requests': url, 'exception': e})
			raise


def reset_hits_count(id):
	with tracer.start_span('reset_hits_count_{}'.format(id)) as span:
		# headers = getForwardHeaders(request, span)
		url = settings.BACKEND_BASE_URL + '/{:d}/'.format(id)
		try:
			result = requests.delete(url)
			span.log_kv({'requests': url, 'response': result})
			result.raise_for_status()
		except Exception as e:
				span.set_tag('error', 'true')
				span.log_kv({'requests': url, 'exception': e})
				raise


class VoteView(View):
	form_class = VoteForm
	initial = {'button1': 'value', 'button2': 'value'}
	template_name = 'index.html'

	def get(self, request, *args, **kwargs):
		try:
			form = self.form_class(initial=self.initial)
			# Get current values
			vote1, v1version = get_hits_count(1)
			vote2, v2version = get_hits_count(2)
			return render(request, self.template_name, {'button1': settings.VOTE1VALUE, 'button2': settings.VOTE2VALUE, 'value1': vote1, 'value2': vote2, 'frontend_version': settings.FRONTEND_VERSION, 'v1_backend_version': v1version, 'v2_backend_version': v2version})
		except Exception as e:
			raise
		# 	return HttpResponseServerError(e.args[0])

	def post(self, request, *args, **kwargs):
		try:
			form = self.form_class(request.POST)
			if form.is_valid():
				vote = form.cleaned_data.get("vote")
				if vote == 'reset':
					# Empty table and return results
					reset_hits_count(1)
					reset_hits_count(2)
				else:
					# Insert vote result into DB
					if vote == 'choicea':
							add_hits_count(1)
					if vote == 'choiceb':
							add_hits_count(2)
				raise Exception()
				vote1, v1version = get_hits_count(1)
				vote2, v2version = get_hits_count(2)
				return render(request, self.template_name, {'button1': settings.VOTE1VALUE, 'button2': settings.VOTE2VALUE, 'value1': vote1, 'value2': vote2, 'frontend_version': settings.FRONTEND_VERSION, 'v1_backend_version': v1version, 'v2_backend_version': v2version})
		except Exception as e:
			raise
		# 	return HttpResponseServerError(e.args[0])
