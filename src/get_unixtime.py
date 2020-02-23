import os
import sys
import pytz
from datetime import datetime, timedelta

def lambda_handler(event: dict, context):
    UTC = pytz.timezone('UTC')
    now = datetime.now(UTC)
    timestamp = now.timestamp()
    return timestamp