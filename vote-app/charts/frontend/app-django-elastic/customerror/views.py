from django.shortcuts import render
from django.http import HttpResponse
import sys
import traceback
# Create your views here.


def handler404(request, exception, template_name="404.html"):
	return render(request, 'error.html', {'title': '== 404 ==', 'error': 'Page not found'})


def handler500(request, template_name="error.html"):
	type, value, tb = sys.exc_info()
	return render(request, 'error.html', {'title': '== 500 ==', 'error': value})
