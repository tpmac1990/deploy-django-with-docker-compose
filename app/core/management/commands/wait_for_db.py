"""
Django command to wait for the database to be available.
"""
import time

from psycopg2 import OperationalError as Psycopg2OpError

from django.db.utils import OperationalError
from django.core.management.base import BaseCommand

# docs: https://docs.djangoproject.com/en/4.0/howto/custom-management-commands/ 

class Command(BaseCommand):
    """Django command to wait for database."""

    def handle(self, *args, **options):
        """Entrypoint for command."""
        self.stdout.write('Waiting for database...')
        db_up = False # assume the db is not available
        while db_up is False:
            try:
                # self.check is a method available in the BaseCommand class that checks to see if the django app
                # is ready. we can use this to see if the db is ready.
                # if this is called before the db is fully ready, then it will throw one of the two errors below
                # depending at which stage the db startup is at.
                self.check(databases=['default'])
                db_up = True
            except (Psycopg2OpError, OperationalError):
                self.stdout.write('Database unavailable, waiting 1 second...')
                time.sleep(1)

        self.stdout.write(self.style.SUCCESS('Database available!'))
