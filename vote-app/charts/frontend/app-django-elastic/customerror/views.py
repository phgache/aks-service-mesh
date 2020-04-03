from django.shortcuts import render
from django.http import HttpResponse
# Create your views here.


def handler404(request, exception, template_name="404.html"):
	return render(request, 'error.html', {'title': '404', 'error': 'Page not found'})


def handler500(request, template_name="error.html"):
	return render(request, 'error.html', {'title': '500', 'error': 'Internal error'})
