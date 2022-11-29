"""
Django settings for user_api project.

"""

from pathlib import Path

from corsheaders.defaults import default_headers

import os
from dotenv import load_dotenv
load_dotenv()



# SECURITY WARNING: don't run with debug turned on in production!
DEBUG = True
# SECURITY WARNING: don't run with debug turned on in production!


SECRET_KEY = os.environ['SECRET_KEY']


# Paths

BASE_DIR = Path(__file__).resolve().parent.parent

STATIC_ROOT = BASE_DIR
STATIC_URL = 'static/'


# Internationalization

LANGUAGE_CODE = 'en-us'
USE_I18N = False

TIME_ZONE = 'UTC'
USE_TZ = True


# Application

INSTALLED_APPS = [
    'django.contrib.contenttypes',
    'django.contrib.staticfiles',
    'corsheaders',
    'rest_framework',
    'user_api',
    'core',
    'movies',
]

MIDDLEWARE = [
    "corsheaders.middleware.CorsMiddleware",
    'django.middleware.security.SecurityMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = 'user_api.urls'

WSGI_APPLICATION = 'user_api.wsgi.application'


# Database

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql_psycopg2',
        'NAME': os.environ['DB_NAME'],
        'USER': os.environ['DB_USER'],
        'PASSWORD': os.environ['DB_PWD'],
        'HOST': os.environ['DB_HOST'],
        'PORT': '5432',
    }
}

DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'


# Framework

REST_FRAMEWORK = { 
    'DEFAULT_AUTHENTICATION_CLASSES': [],
    'DEFAULT_PERMISSION_CLASSES': [],
    'DEFAULT_PARSER_CLASSES': (
        'rest_framework.parsers.FormParser',
        'rest_framework.parsers.MultiPartParser'
    ),
    'UNAUTHENTICATED_USER': None,
}


# CORS / Hosts

CORS_ALLOW_ALL_ORIGINS: False

CORS_ALLOWED_ORIGINS = [
    'http://localhost:3000',
    'https://www.movierex.org',
    'https://movierex.org',
]

CORS_ALLOW_HEADERS = list(default_headers) + [
    'token',
    'authentication',
]

ALLOWED_HOSTS = [
    'api.movierex.info'
]