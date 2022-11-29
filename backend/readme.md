# User Backend Tests
Test Django code for User/Movie API

## User_API
Main Django project files

## Core
For InternalUser & Interal Review models and handling

    Models:
        -InternalUser
        -InternalUserManager
        -InternalUserReview
    Urls:
        -/signup & /login
        -/user/<str:username>:
            -/signup
            -/login
            -/get
            -/validate
            -/change:
                -/email
                -/pwd
            -/delete
            -/review:
                -/add:
                    -/
                    -/multiple
                -/get/<str:movie_id>:
                    -/
                    -/info
                -/getpage/:
                    -/
                    -/info
                    -/<int:page>:
                        -/
                        -/info
                -/count
                -/delete/<str:movie_id>

## Movies
For Movie model and handling

    Models:
        -Movie
        -Review
    Urls (/movie):
        -/<str:id>:
            -/basic
            -full
        -/search:
            -/
            -/all
        -/random:
            -/
            -/<int:num>
        -/recs:
            -/
            -/<str:username>

### Lib
    -fixLenIntHash:
        Class that makes & holds a fixed length integer hashing function
        For creating User IDs from index/row number
    -views_funcs:
        Functions used accross views
        -create_response:
            Takes positional 'result' argument and kwargs and returns JSON HTTP response
        -verify_token:
            Takes positional arguments 'request' and 'username' and returns user if token is valid else 0
