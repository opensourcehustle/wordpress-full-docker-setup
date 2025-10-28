#!/bin/bash

# WordPress Docker Setup Script with SSL
# This script helps you set up WordPress with Docker, Nginx, and Let's Encrypt SSL

set -e

echo "======================================"
echo "WordPress Docker Setup with SSL"
echo "======================================"
echo ""

# Check if .env file exists
if [ ! -f .env ]; then
    echo "Creating .env file from .env.example..."
    cp .env.example .env
    echo ""
    echo "⚠️  Please edit the .env file with your configuration:"
    echo "   - Set strong passwords for MySQL"
    echo "   - Set your domain name"
    echo "   - Set your email for SSL certificates"
    echo ""
    echo "After editing .env, run this script again."
    exit 0
fi

# Load environment variables
source .env

# Replace domain in nginx config
echo "Configuring Nginx for domain: $DOMAIN"
sed "s/yourdomain.com/$DOMAIN/g" nginx/conf.d/wordpress-http.conf > nginx/conf.d/wordpress-http.conf.tmp
mv nginx/conf.d/wordpress-http.conf.tmp nginx/conf.d/wordpress-http.conf

echo ""
echo "Starting services..."
docker-compose up -d db wordpress nginx

echo ""
echo "Waiting for services to be ready..."
sleep 10

echo ""
echo "======================================"
echo "Obtaining SSL Certificate"
echo "======================================"
echo ""
echo "⚠️  Before proceeding, make sure:"
echo "   1. Your domain ($DOMAIN) points to this server's IP"
echo "   2. Ports 80 and 443 are open in your firewall"
echo ""
read -p "Press Enter to continue with certificate generation..."

# Get SSL certificate
echo "Requesting SSL certificate..."
docker-compose run --rm certbot

if [ $? -eq 0 ]; then
    echo ""
    echo "✓ SSL certificate obtained successfully!"
    echo ""
    echo "Configuring HTTPS..."
    
    # Enable HTTPS configuration
    sed "s/yourdomain.com/$DOMAIN/g" nginx/conf.d/wordpress-https.conf.template > nginx/conf.d/wordpress-https.conf
    
    # Reload Nginx
    docker-compose restart nginx
    
    echo ""
    echo "======================================"
    echo "✓ Setup Complete!"
    echo "======================================"
    echo ""
    echo "Your WordPress site is now available at:"
    echo "  https://$DOMAIN"
    echo "  https://www.$DOMAIN"
    echo ""
    echo "Next steps:"
    echo "  1. Visit your site to complete WordPress installation"
    echo "  2. Set up automatic SSL renewal (see renewal.sh)"
    echo ""
else
    echo ""
    echo "❌ Failed to obtain SSL certificate."
    echo ""
    echo "Common issues:"
    echo "  - Domain not pointing to this server"
    echo "  - Ports 80/443 not accessible"
    echo "  - Rate limit reached (Let's Encrypt allows 5 failures per hour)"
    echo ""
    echo "Your site is running on HTTP only for now."
    echo "Fix the issues and run: docker-compose run --rm certbot"
fi
