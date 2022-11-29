from django.urls import path
from core import views

urlpatterns = [
    # Users
    path('signup', views.signup),
    path('login', views.login),
    path('<str:username>/get', views.get_user),
    path('<str:username>/validate', views.get_user),
    path('<str:username>/change/pwd', views.change_pwd),
    path('<str:username>/change/email', views.change_email),
    path('<str:username>/delete', views.delete_user),
    #Reviews
    path('<str:username>/review/add', views.add_review),
    path('<str:username>/review/add/multiple', views.add_reviews),
    path('<str:username>/review/get/<str:movie_id>', views.get_review),
    path('<str:username>/review/get/<str:movie_id>/info', views.get_review_info),
    path('<str:username>/review/getpage', views.get_review_page),
    path('<str:username>/review/getpage/<int:page>', views.get_review_page),
    path('<str:username>/review/getpage/info', views.get_review_page_info),
    path('<str:username>/review/getpage/<int:page>/info', views.get_review_page_info),
    path('<str:username>/review/count', views.get_review_count),
    path('<str:username>/review/delete/<str:movie_id>', views.delete_review),
]