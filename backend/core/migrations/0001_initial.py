# Generated by Django 4.1.2 on 2022-11-10 08:50

import django.core.validators
from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    initial = True

    dependencies = [
        ('movies', '__first__'),
    ]

    operations = [
        migrations.CreateModel(
            name='InternalUser',
            fields=[
                ('id', models.PositiveIntegerField(db_index=True, primary_key=True, serialize=False, unique=True, validators=[django.core.validators.MinValueValidator(10000000), django.core.validators.MaxValueValidator(99999999)])),
                ('email', models.EmailField(max_length=254, unique=True)),
                ('username', models.CharField(max_length=36, unique=True)),
                ('password_hash', models.CharField(max_length=198)),
                ('perms', models.CharField(choices=[('BU', 'Base User'), ('AD', 'Admin')], default='BU', max_length=2)),
            ],
        ),
        migrations.CreateModel(
            name='InternalUserReview',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('rating', models.IntegerField(validators=[django.core.validators.MinValueValidator(1), django.core.validators.MaxValueValidator(10)])),
                ('movie', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to='movies.movie')),
                ('user', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to='core.internaluser')),
            ],
        ),
    ]
