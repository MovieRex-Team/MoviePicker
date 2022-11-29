from rest_framework import serializers

from .models import *


class BasicMovieSerializer(serializers.ModelSerializer):
    class Meta:
        model = Movie
        fields = ['tomato_url', 'imdb_id', 'title', 'year', 'poster_url']



class FullMovieSerializer(serializers.ModelSerializer):
    class Meta:
        model = Movie
        fields = '__all__'