from django.urls import path
from . import views

urlpatterns = [
    path('<str:id>/basic', views.get_basic_info),
    path('<str:id>/full', views.get_full_info),
    path('search', views.search),
    path('search/all', views.search_all),
    path('random', views.random),
    path('random/<int:num>', views.random),
    path('recs', views.get_rec_from_reviews),
    path('recs/<str:username>', views.get_rec_from_user)
]