#!/bin/bash

# SSL Certificate Renewal Script
# Add this to crontab to run twice daily: 0 0,12 * * * /path/to/renewal.sh

cd "$(dirname "$0")"

echo "Attempting to renew SSL certificates..."
docker compose run --rm certbot renew

if [ $? -eq 0 ]; then
    echo "Certificate renewed successfully. Reloading Nginx..."
    docker compose exec nginx nginx -s reload
else
    echo "Certificate renewal failed or not due for renewal."
fi
