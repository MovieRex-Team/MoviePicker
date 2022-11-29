from rest_framework import serializers

from .models import *
from movies.models import Movie
from movies.serializers import BasicMovieSerializer



class UserInfoSerializer(serializers.ModelSerializer):
    class Meta:
        model = InternalUser
        fields = ['email', 'username']



class UserReviewSerializer(serializers.ModelSerializer):
    tomato_url = serializers.CharField(source='movie_id')
    
    class Meta:
        model = InternalUserReview
        fields = ['tomato_url', 'rating']



class UserReviewInfoSerializer(serializers.ModelSerializer):
    movie_info = serializers.SerializerMethodField()

    def get_movie_info(self, instance):
        return BasicMovieSerializer(Movie.objects.filter(tomato_url=instance.movie_id)[0]).data

    class Meta:
        model = InternalUserReview
        fields = ['rating', 'movie_info']