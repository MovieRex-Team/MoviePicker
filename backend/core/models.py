from django.db import models
from django.core.validators import MinValueValidator, MaxValueValidator, validate_email
from django.core.exceptions import ValidationError
from django.utils.translation import gettext_lazy as _

from lib.fix_len_intHash import FixedLengthIntHasher
from argon2 import PasswordHasher




# Users
#


class SitePermissionLevels(models.TextChoices):
        BASE_USER = 'BU', _('Base User')
        ADMIN = 'AD', _('Admin')


class InternalUserManager():
    _id_hasher = FixedLengthIntHasher(9, 59271)
    _pwd_hasher = PasswordHasher()

    _MIN_USERNAME_LENGTH = 4
    _MAX_USERNAME_LENGTH = 36

    _MIN_PWD_LENGTH = 8
    _MAX_PWD_LENGTH = 99

    class InvalidArgError(ValueError):
        def __init__(self, attribute, val):
            self.msg = f'Invalid or no {attribute} provided: {val}'
            self.attribute = attribute
            super().__init__(self.msg)

    class DuplicateValError(Exception):
        def __init__(self, arg):
            self.msg = f'Duplicate {arg} Value'
            self.arg = arg
            super().__init__(self, arg)


    #Puts last row number into hasher to get id
    def _create_user_id(self):
        return self._id_hasher.hash(len(InternalUser.objects.all()) + 1)


    def _create_password_hash(self, password):
        return self._pwd_hasher.hash(password)


    def password_allowed(pwd):
        if not pwd or len(pwd) < InternalUserManager._MIN_PWD_LENGTH or len(pwd) > InternalUserManager._MAX_PWD_LENGTH: return False
        return True


    def username_allowed(username):
        if not username or len(username) < InternalUserManager._MIN_USERNAME_LENGTH or len(username) > InternalUserManager._MAX_USERNAME_LENGTH: return False
        return True


    def email_allowed(email):
        try:
            validate_email(email)
        except ValidationError:
            return False
        
        return True


    def change_password(user, pwd):
        if not InternalUserManager.password_allowed(pwd): raise InternalUserManager.InvalidArgError('password', pwd)
        user.password_hash = InternalUserManager()._create_password_hash(pwd)
        user.save()


    def change_email(user, email):
        if not InternalUserManager.email_allowed(email): raise InternalUserManager.InvalidArgError('email', email)
        user.email = email
        user.save()


    def create_user(self, email, username, password):
        #Check for empty values
        bad_attributes = [attr for attr in list(locals()) if not attr[1]]

        if bad_attributes:
            raise self.InvalidArgError(bad_attributes[0][0], bad_attributes[0][1])

        #Check for otherwise invalid values
        if not InternalUserManager.username_allowed(username):
            raise self.InvalidArgError('username', username)

        if not InternalUserManager.password_allowed(password):
            raise self.InvalidArgError('password', password)

        if not InternalUserManager.email_allowed(email):
            raise self.InvalidArgError('email', email)

        #Check for duplicate values
        if InternalUser.objects.filter(email=email).exists():
            raise self.DuplicateValError('email')

        if InternalUser.objects.filter(username=username).exists():
            raise self.DuplicateValError('username')

        #Construct and save
        user = InternalUser(
            id = self._create_user_id(),
            email = email,
            username = username,
            password_hash = self._create_password_hash(password),
            perms = SitePermissionLevels.BASE_USER,
        )
        user.save()
        return user



class InternalUser(models.Model):
    id = models.PositiveIntegerField(
        db_index=True,
        primary_key=True,
        unique=True, 
        validators=[MinValueValidator(10000000), MaxValueValidator(99999999)],
    )

    email = models.EmailField(
        unique=True,
    )

    username = models.CharField(
        max_length= InternalUserManager._MAX_USERNAME_LENGTH, 
        unique=True,
    )

    password_hash = models.CharField(
        max_length=(InternalUserManager._MAX_PWD_LENGTH * 2),
    )

    perms = models.CharField(
        max_length=2, 
        choices=SitePermissionLevels.choices, 
        default=SitePermissionLevels.BASE_USER,
    )

    objects = InternalUserManager()

    REQUIRED_FIELDS = [
        'id',
        'email',
        'username',
        'password_hash',
        'perms',
    ]



class InternalUserReview(models.Model):
    user = models.ForeignKey(
        'InternalUser',
        on_delete=models.CASCADE,
        db_index=True,
    )

    movie = models.ForeignKey(
        'movies.Movie',
        on_delete=models.CASCADE,
        db_index=True,
    )

    rating = models.IntegerField(
        validators=[MinValueValidator(0), MaxValueValidator(10)],
    )