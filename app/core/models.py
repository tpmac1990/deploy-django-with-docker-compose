from django.db import models


class Sample(models.Model):
    attachment = models.FileField() # files uploaded by users as the app is running



       
