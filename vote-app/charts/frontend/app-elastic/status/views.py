from django.shortcuts import render
from django.http import HttpResponse

def healthz(request):
  return HttpResponse("OK")


def readyz(request):
  return HttpResponse("OK")
