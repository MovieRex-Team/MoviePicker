from django.db import models
from django.contrib.postgres.fields import ArrayField



# Create your models here.
class Movie(models.Model):
    def _create_movie(data):
        movie = Movie(data)
        movie.save()
        
    tomato_url = models.TextField(
        db_index=True,
        primary_key=True,
        unique=True,
    )

    imdb_id = models.CharField(
        max_length=10,
        unique=True,
    )

    title = models.TextField()
    year = models.IntegerField()

    priority = models.FloatField()

    plot = models.TextField()
    runtime = models.IntegerField()
    poster_url = models.TextField()

    mpa_rating = models.CharField(
        max_length=10,
    )

    metascore = models.IntegerField()
    imdb_rating = models.FloatField()
    tomato_rating = models.IntegerField()

    awards = models.CharField(max_length=256)

    genres = ArrayField(
        models.CharField(max_length=40)
    )

    directors = ArrayField(
        models.CharField(max_length=120)
    )

    writers = ArrayField(
        models.CharField(max_length=120)
    )

    actors = ArrayField(
        models.CharField(max_length=120)
    )

    languages = ArrayField(
        models.CharField(max_length=40)
    )



class Review(models.Model):
    uurl = models.TextField(
        db_index=True,
        unique=False,
    )

    rating = models.IntegerField()

    tomato_url = models.TextField()
    