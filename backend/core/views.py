from .models import *
from .serializers import *
from movies.models import Movie

from lib.views_funcs import create_response, verify_token

from rest_framework.decorators import api_view

import jwt
from argon2.exceptions import VerifyMismatchError

from datetime import datetime, timedelta, timezone
import json

 


### Users
#


# /signup
#
@api_view(['POST'])
def signup(request):
    #Check for required attributes
    if not request.POST.keys() >= {'username', 'email', 'password'}: return create_response('fail', err='missing_arg')

    try:
        user = InternalUserManager().create_user(request.POST['email'], request.POST['username'], request.POST['password'])
        return create_response('success', user=UserInfoSerializer(user).data)
    except InternalUserManager.InvalidArgError as e:
        return create_response('fail', err='invalid_arg', invalid=e.attribute)
    except InternalUserManager.DuplicateValError as e:
        return create_response('fail', err='duplication', duplicate=e.arg)
    except:
        return create_response('fail', err='database_error')



# /login
#
@api_view(['POST'])
def login(request):
    #Check for password and either username or password
    if not 'password' in request.POST or not request.POST.keys() & {'username', 'email'}: return create_response('fail', err='missing_arg')
    
    if not len(request.POST['password']): return create_response('fail', err='empty_password')

    #Filter by email or username and check for results
    user = InternalUser.objects.filter(email=request.POST['email']) if ('email' in request.POST) else InternalUser.objects.filter(username=request.POST['username'])
    if not len(user): return create_response('fail', err='no_user_match')
    user = user[0]

    #Verify Password
    try:
        InternalUserManager._pwd_hasher.verify(user.password_hash, request.POST['password'])
    except VerifyMismatchError:
        return create_response('fail', err='invalid_password')

    #Create token and response
    token = jwt.encode(
        payload={'sub': user.id, 'username': user.username, "exp": datetime.now(tz=timezone.utc) + timedelta(hours=3)}, 
        key='fight_club' #Replace with real key?
    )
    return create_response('success', token=token, user=UserInfoSerializer(user).data)



# /user/<str:username>/validate
#
@api_view(['GET'])
def get_user(request, username):
    #Make sure token was sent
    if not request.headers.keys() & {'token', 'authorization', 'authentication'}: return create_response('fail', err='no_token')
    token = request.headers.get('token', '') or request.headers.get('authorization', '') or request.headers.get('authentication', '')

    #Validate structure
    try:
        data = jwt.decode(token, key='fight_club', algorithms=['HS256', ])
    except jwt.InvalidSignatureError:
        return create_response('fail', err='invalid_token')
    except jwt.ExpiredSignatureError:
        return create_response('fail', err='expired_token')
    
    #Check for and validate expected data
    if not data.keys() >= {'sub', 'username'}: return create_response('fail', err='missing_data')

    user = InternalUser.objects.filter(id=data['sub'], username=data['username'])
    if not len(user) or not username == user[0].username: return create_response('fail', err='invalid_data')

    return create_response('success', user=UserInfoSerializer(user[0]).data)



# /user/<str:username>/pwd/change
#
@api_view(['POST'])
def change_pwd(request, username):
    #Validate User
    user = verify_token(request, username)
    if not user: return create_response('fail', err='invalid_token')

    #Validate Passwords
    if not request.POST.keys() >= {'old_pwd', 'new_pwd'}: return create_response('fail', err='missing_arg')
    desired_pwd = request.POST['new_pwd']

    try:
        InternalUserManager._pwd_hasher.verify(user.password_hash, request.POST['old_pwd'])
    except VerifyMismatchError:
        return create_response('fail', err='invalid_old_password')

    #Set
    if InternalUserManager.password_allowed(desired_pwd):
        InternalUserManager.change_password(user, desired_pwd)
    
    #Check for successful change
    try:
        InternalUserManager._pwd_hasher.verify(InternalUser.objects.filter(id=user.id)[0].password_hash, desired_pwd)
    except VerifyMismatchError:
        return create_response('fail', err='unknown')
    
    
    return create_response('success')



# /user/<str:username>/email/change
#
@api_view(['POST'])
def change_email(request, username):
    #Validate Token
    user = verify_token(request, username)
    if not user: return create_response('fail', err='bad_token')

    #Check Password
    if not request.POST.keys() >= {'password', 'new_email'}: return create_response('fail', err='missing_arg')

    try:
        InternalUserManager._pwd_hasher.verify(user.password_hash, request.POST['password'])
    except VerifyMismatchError:
        return create_response('fail', err='invalid_password')

    #Make sure email doesnt already exist
    desired_email = request.POST['new_email']
    if InternalUser.objects.filter(email=desired_email): return create_response('fail', err='duplicate_email')

    InternalUserManager.change_email(user, desired_email)

    #Check for successful change
    if not InternalUser.objects.filter(email=desired_email): return create_response('fail', err='unknown')
    
    
    return create_response('success')


# /user/<str:username>/delete
# 
@api_view(['POST'])
def delete_user(request, username):
    #Validate Token
    user = verify_token(request, username)
    if not user: return create_response('fail', err='bad_token')

    try:
        user.delete()
        return create_response('success')
    except Exception as e:
        print(e)
        return create_response('fail', err='database_error')



### Reviews
#


# /user/<str:username>/review/add
#
@api_view(['POST'])
def add_review(request, username):
    return _add_reviews(request, username)


# /user/<str:username>/review/add/multiple
#
@api_view(['POST'])
def add_reviews(request, username):
    return _add_reviews(request, username)



# /user/<str:username>/review/get/<str:movie_id>
#
@api_view(['GET'])
def get_review(request, username, movie_id):
    return _get_review(request, username, movie_id, UserReviewSerializer)



# /user/<str:username>/review/get/<str:movie_id>/info
#
@api_view(['GET'])
def get_review_info(request, username, movie_id):
    return _get_review(request, username, movie_id, UserReviewInfoSerializer)



# /user/<str:username>/review/get/?<int:page>?
#
@api_view(['GET'])
def get_review_page(request, username, page = 1):
    return _get_review_page(request, username, page, UserReviewSerializer)



# /user/<str:username>/review/get/<int:page>/info
#
@api_view(['GET'])
def get_review_page_info(request, username, page = 1):
    return _get_review_page(request, username, page, UserReviewInfoSerializer)


# /user/<str:username>/review/count
#
@api_view(['GET'])
def get_review_count(request, username):
    #Validate Token
    user = verify_token(request, username)
    if not user: return create_response('fail', err='bad_token')

    #Get Reviews
    movies = InternalUserReview.objects.filter(user_id=user.id)

    return create_response('success', count=len(movies))


# /user/<str:username>/review/delete/<str:movie_id>
#
@api_view(['POST'])
def delete_review(request, username, movie_id):
    #Validate Token
    user = verify_token(request, username)
    if not user: return create_response('fail', err='database_error')

    review = InternalUserReview.objects.filter(user_id=user.id, movie_id=movie_id)
    if not len(review): return create_response('fail', err='no_review')

    try:
        review[0].delete()
        return create_response('success')
    except Exception as e:
        print(e)
        return create_response('fail', err='database_error')



### Funcs
#


def _add_reviews(request, username):
    #Validate Token
    user = verify_token(request, username)
    if not user: return create_response('fail', err='bad_token')

    #Get review list
    reviews = []
    #Single review
    if request.POST.keys() >= {'tomato_url', 'rating'}:
        reviews = [{'tomato_url':request.POST['tomato_url'], 'rating':request.POST['rating']}]
    #Multiple reviews
    elif 'reviews' in request.POST.keys():
        for review in json.loads(request.POST['reviews']):
            if not review.keys() >= {'tomato_url', 'rating'}: return create_response('fail', err='invalid_review')
            reviews.append(review)
    else:
        return create_response('fail', err='missing_arg')

    #Add reviews to db
    review_return_list = []
    for i, review in enumerate(reviews):
        #Validate rating args
        movies = Movie.objects.filter(tomato_url=review['tomato_url'])
        if not len(movies): return create_response('fail', err='invalid_movie', successes=i)
        
        rating = int(review['rating'])
        if rating < 0 or rating > 10: return create_response('fail', err='invalid_rating', successes=i)
        
        #If review already exist edit it
        reviews = InternalUserReview.objects.filter(user_id=user.id, movie_id=review['tomato_url'])
        if len(reviews):
            final_review = reviews[0]
            final_review.rating = rating
        else:
            final_review = InternalUserReview(
                user=user,
                movie=movies[0],
                rating=rating
            )

        try:
            final_review.save()
            review_return_list.append(final_review)
        except Exception as e:
            print(e)
            return create_response('fail', err='database_error', successes=i)

    return create_response('success', reviews=[UserReviewInfoSerializer(review).data for review in review_return_list])


def _get_review(request, username, movie_id, Serializer):
    #Validate Token
    user = verify_token(request, username)
    if not user: return create_response('fail', err='bad_token')

    movie = InternalUserReview.objects.filter(user_id=user.id, movie_id=movie_id)
    if not len(movie): return create_response('fail', err='no_review')

    return create_response('success', review=Serializer(movie[0]).data)


_reviews_page_length = 10
def _get_review_page(request, username, page, Serializer):
    #Validate Token
    user = verify_token(request, username)
    if not user: return create_response('fail', err='bad_token')

    #Get Reviews
    movies = InternalUserReview.objects.filter(user_id=user.id)
    movies_count = len(movies)
    if not movies_count: return create_response('fail', err='no_reviews')

    #Handle Pages
    if page < 1: return create_response('fail', err='invalid_page')
    if page == 1: return create_response('success', reviews=[Serializer(mov).data for mov in (movies[:_reviews_page_length] if movies_count > _reviews_page_length else movies)])
    last_before = (_reviews_page_length * (page - 1))
    last = _reviews_page_length * page
    if movies_count <= last_before: return create_response('fail', err='empty_page')
    return create_response('success', reviews=[Serializer(mov).data for mov in (movies[last_before:last] if movies_count > last else movies[last_before:])])