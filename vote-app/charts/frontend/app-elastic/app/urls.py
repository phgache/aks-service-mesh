# from django.contrib import admin
from django.urls import include, path

urlpatterns = [
    path('', include('vote.urls')),
    path('status/', include('status.urls')),
]

handler404 = 'customerror.views.handler404'
handler500 = 'customerror.views.handler500'
