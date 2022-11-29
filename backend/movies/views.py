from .models import *
from .serializers import *

from core.models import InternalUserReview
from core.serializers import UserReviewSerializer

from lib.views_funcs import create_response, verify_token

from rest_framework.decorators import api_view

import json

from django.db import connection
from django.db.utils import DataError



### Movies
#


# /movie/<str:id>/basic
#
@api_view(['GET'])
def get_basic_info(request, id):
    return _get_info(id, BasicMovieSerializer)



# /movie/<str:id>/full
#
@api_view(['GET'])
def get_full_info(request, id):
    return _get_info(id, FullMovieSerializer)


# /movie/search
#
@api_view(['POST'])
def search(request):
    return _search(request)


# /movie/search/all
#
@api_view(['POST'])
def search_all(request):
    return _search(request, getAll=True)



# /movie/random/?<int:num>?
#
@api_view(['GET'])
def random(request, num = 1):
    if num > 100: return create_response('fail', err='max_movies_exceeded')

    movie_list = [BasicMovieSerializer(mov).data for mov in Movie.objects.filter(priority__gte=80).all().order_by('?')[:num]]
    return create_response('success', movie_list=movie_list)



### Recs
#


# /movie/recs/<str:username>
#
@api_view(['GET'])
def get_rec_from_user(request, username):
    user = verify_token(request, username)
    if not user: return create_response('fail', err='invalid_token')

    reviews = InternalUserReview.objects.filter(user=user)
    if not reviews: return create_response('fail', err='no_reviews')

    return _get_recs([UserReviewSerializer(review).data for review in reviews])



# /movie/recs
#
@api_view(['POST'])
def get_rec_from_reviews(request):
    if not 'reviews' in request.POST: return create_response('fail', err='no_ratings')

    try:
        reviews = json.loads(request.POST['reviews'])
    except json.decoder.JSONDecodeError:
        return create_response('fail', err='invalid_json')

    return _get_recs(reviews)



### Funcs
#


def _get_info(id, Serializer):
    movie = Movie.objects.filter(tomato_url=id)

    if len(movie):
        return create_response('success', movie=Serializer(movie[0]).data)
    else:
        return create_response('fail', err='no_results')


def _search(request, getAll = False):
    if not 'search' in request.POST: return create_response('fail', err='no_search_provided')
    
    #Get matches by priority descending
    matches = Movie.objects.filter(title__icontains=request.POST['search']).order_by('-priority')
    match_count = len(matches)

    if not match_count: return create_response('fail', err='no_matches')

    #Get data for up to 5 matches or all matches
    movie_list = [BasicMovieSerializer(mov).data for mov in (matches if getAll else matches[:(5 if match_count > 4 else match_count)])]
    return create_response('success', movie_list=movie_list)


def _get_recs(reviews):
    for review in reviews:
        if not review.keys() >= {'rating', 'tomato_url'}: return create_response('fail', err='invalid_ratings')
        if not len(Movie.objects.filter(tomato_url=review['tomato_url'])): return create_response('fail', err='invalid_movie')

    if len(reviews) < 5: return create_response('fail', err='not_enough_reviews')

    with connection.cursor() as cursor:
        try:
            cursor.callproc('get_recs', [json.dumps(reviews)])
            output = cursor.fetchall()
        except DataError as e:
            print(e)
            return create_response('fail', err='generation_error')

    if not output: return create_response('fail', err='generation_error')

    recs = output[0][0]
    recs_len = len(recs)

    recs_page = recs[:(10 if recs_len > 10 else recs_len - 1)]
    
    movies = []
    for rec in recs_page:
        movie = Movie.objects.filter(tomato_url=rec)
        if len(movie): movies.append(movie[0])

    return create_response('success', recs=[BasicMovieSerializer(movie).data for movie in movies])
