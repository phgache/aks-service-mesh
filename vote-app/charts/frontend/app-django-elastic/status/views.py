from django.shortcuts import render
from django.http import HttpResponse

def healthz(request, exception):
  return HttpResponse("OK")


def readyz(request, exception):
  return HttpResponse("OK")
