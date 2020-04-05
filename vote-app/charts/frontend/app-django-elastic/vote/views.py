from django.http import HttpResponseRedirect, HttpResponse
from django.shortcuts import render
from django.views import View
from django.conf import settings
import sys
import elasticapm
from elasticapm.contrib.django.client import client
from elasticapm import label

import requests
import structlog

from .forms import VoteForm

logger = structlog.get_logger(__name__)

from elasticapm.contrib.opentracing import Tracer

tracer = Tracer()

def get_hits_count(id):
	with tracer.start_span("get_hits_count_{}".format(id)) as span:
		# headers = getForwardHeaders(request, span)
		url = settings.BACKEND_BASE_URL + "/" + str(id)
		try:
			result = requests.get(url)
			result.raise_for_status()
			resp = result.json()
			logger.info("requests: {} result: {}, response: {}".format(url, result, resp))
			return resp["count"], resp["backendVersion"]
		except Exception as e:
			span.set_tag("error", "true")
			exc_type, exc_val, exc_tb = sys.exc_info()[:3]
			span.log_kv({
				"python.exception.type": exc_type,
				"python.exception.val": exc_val,
				"python.exception.tb": exc_tb
			})
			raise


def add_hits_count(id):
	with tracer.start_span("add_hits_count_{}".format(id)) as span:
		url = settings.BACKEND_BASE_URL
		try:
			result = requests.post(url, json={"id": id})
			logger.info("requests: {} result: {}".format(url, result))
			result.raise_for_status()
		except Exception as e:
			span.set_tag("error", "true")
			exc_type, exc_val, exc_tb = sys.exc_info()[:3]
			span.log_kv({
				"python.exception.type": exc_type,
				"python.exception.val": exc_val,
				"python.exception.tb": exc_tb
			})
			raise


def reset_hits_count(id):
	with tracer.start_span("reset_hits_count_{}".format(id)) as span:
		# headers = getForwardHeaders(request, span)
		url = settings.BACKEND_BASE_URL + "/{:d}/".format(id)
		try:
			result = requests.delete(url)
			logger.info("requests: {} result: {}".format(url, result))
			result.raise_for_status()
		except Exception as e:
			span.set_tag("error", "true")
			exc_type, exc_val, exc_tb = sys.exc_info()[:3]
			span.log_kv({
				"python.exception.type": exc_type,
				"python.exception.val": exc_val,
				"python.exception.tb": exc_tb
			})
			raise


class VoteView(View):
	form_class = VoteForm
	template_name = "index.html"

	def get(self, request, *args, **kwargs):
		try:
			# Get current values
			vote1, v1version = get_hits_count(1)
			vote2, v2version = get_hits_count(2)
			return render(request, self.template_name, {"title": settings.TITLE, "button1": settings.VOTE1VALUE, "button2": settings.VOTE2VALUE, "value1": vote1, "value2": vote2, "frontend_version": settings.FRONTEND_VERSION, "v1_backend_version": v1version, "v2_backend_version": v2version})
		except Exception:
			raise
			# return HttpResponse(status=500)

	def post(self, request, *args, **kwargs):
		try:
			form = self.form_class(request.POST)
			if form.is_valid():
				vote = form.cleaned_data.get("vote")
				if vote == "reset":
					# Empty table and return results
					reset_hits_count(1)
					reset_hits_count(2)
				else:
					# Insert vote result into DB
					if vote == "choicea":
							add_hits_count(1)
					if vote == "choiceb":
							add_hits_count(2)
				# raise Exception()
				vote1, v1version = get_hits_count(1)
				vote2, v2version = get_hits_count(2)
				return render(request, self.template_name, {"title": settings.TITLE, "button1": settings.VOTE1VALUE, "button2": settings.VOTE2VALUE, "value1": vote1, "value2": vote2, "frontend_version": settings.FRONTEND_VERSION, "v1_backend_version": v1version, "v2_backend_version": v2version})
		except Exception:
			raise
			# return HttpResponse(status=500)
