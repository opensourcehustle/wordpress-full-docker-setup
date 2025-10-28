# WordPress Docker Setup with SSL

A complete Docker Compose configuration for running WordPress with MySQL, Nginx reverse proxy, and automatic SSL certificates via Let's Encrypt.

## Features

- **WordPress**: Latest version with PHP-FPM
- **MySQL 8.0**: Database backend
- **Nginx**: Reverse proxy with HTTP/2 and SSL
- **Let's Encrypt**: Free SSL certificates via Certbot
- **Security Headers**: HSTS, X-Frame-Options, etc.
- **Automatic Redirects**: HTTP to HTTPS
- **Optimized Caching**: Static file caching rules
- **Easy Renewal**: Automated SSL certificate renewal
- **Custom Themes & Plugins**: Local volume mappings for easy development and management

## Prerequisites

- Docker and Docker Compose installed
- Domain name pointing to your server
- Ports 80 and 443 open in firewall
- Root or sudo access

## Quick Start

### 1. Clone or Download Files

Ensure you have all these files in your directory:
```
.
├── docker-compose.yml
├── .env.example
├── setup.sh
├── renewal.sh
├── themes/              # Custom WordPress themes
├── plugins/             # Custom WordPress plugins
└── nginx/
    └── conf.d/
        ├── wordpress-http.conf
        └── wordpress-https.conf.template
```

### 2. Configure Environment Variables

```bash
cp .env.example .env
nano .env
```

Edit the following values:
- `MYSQL_ROOT_PASSWORD`: Strong root password for MySQL
- `MYSQL_DATABASE`: Database name (default: wordpress_db)
- `MYSQL_USER`: Database user (default: wordpress_user)
- `MYSQL_PASSWORD`: Strong password for database user
- `DOMAIN`: Your domain name (e.g., example.com)
- `SSL_EMAIL`: Your email for Let's Encrypt notifications

### 3. Point Your Domain

Make sure your domain's DNS A record points to your server's IP address:
- `example.com` → Your Server IP
- `www.example.com` → Your Server IP

### 4. Run Setup Script

```bash
chmod +x setup.sh
./setup.sh
```

The script will:
1. Create necessary Docker volumes
2. Start MySQL, WordPress, and Nginx
3. Request SSL certificates from Let's Encrypt
4. Configure HTTPS

### 5. Complete WordPress Installation

Visit `https://yourdomain.com` and follow the WordPress installation wizard.

## Manual Setup (Alternative)

If you prefer manual setup:

### Start Services (HTTP only)

```bash
# Start database and WordPress first
docker-compose up -d db wordpress nginx

# Wait for services to start
sleep 10
```

### Obtain SSL Certificate

```bash
# Request certificate
docker-compose run --rm certbot

# If successful, enable HTTPS configuration
cp nginx/conf.d/wordpress-https.conf.template nginx/conf.d/wordpress-https.conf

# Update domain in the config
sed -i 's/yourdomain.com/your-actual-domain.com/g' nginx/conf.d/wordpress-https.conf

# Restart Nginx
docker-compose restart nginx
```

## SSL Certificate Renewal

Let's Encrypt certificates expire after 90 days. Set up automatic renewal:

### Option 1: Cron Job (Recommended)

```bash
chmod +x renewal.sh

# Add to crontab (runs twice daily at midnight and noon)
crontab -e

# Add this line:
0 0,12 * * * /path/to/your/wordpress/renewal.sh >> /var/log/certbot-renewal.log 2>&1
```

### Option 2: Manual Renewal

```bash
docker-compose run --rm certbot renew
docker-compose restart nginx
```

## Useful Commands

### View Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f wordpress
docker-compose logs -f nginx
docker-compose logs -f db
```

### Restart Services

```bash
# All services
docker-compose restart

# Specific service
docker-compose restart nginx
```

### Stop Services

```bash
docker-compose down
```

### Backup Database

```bash
# Export database
docker-compose exec db mysqldump -u wordpress_user -p wordpress_db > backup.sql

# Or use root user
docker-compose exec db mysqldump -u root -p wordpress_db > backup.sql
```

### Restore Database

```bash
docker-compose exec -T db mysql -u wordpress_user -p wordpress_db < backup.sql
```

### Update WordPress

```bash
docker-compose pull wordpress
docker-compose up -d wordpress
```

## Custom Themes and Plugins

This setup includes volume mappings for custom themes and plugins, allowing you to develop and manage them directly on your host machine.

### Adding Custom Themes

1. Place your theme folder in the `themes/` directory
2. Your theme will automatically appear in WordPress admin under **Appearance → Themes**
3. Changes made to theme files are immediately reflected (may need to clear cache)

Example:
```bash
# Add a custom theme
cp -r my-custom-theme/ themes/

# Your theme is now available at:
# /var/www/html/wp-content/themes/my-custom-theme
```

### Adding Custom Plugins

1. Place your plugin folder in the `plugins/` directory
2. Your plugin will automatically appear in WordPress admin under **Plugins**
3. Activate the plugin from the WordPress admin panel

Example:
```bash
# Add a custom plugin
cp -r my-custom-plugin/ plugins/

# Your plugin is now available at:
# /var/www/html/wp-content/plugins/my-custom-plugin
```

### Development Workflow

The volume mappings are bi-directional:
- **Local → Container**: Files added to `themes/` or `plugins/` appear in WordPress
- **Container → Local**: Themes/plugins installed via WordPress admin appear in local directories
- **Live Updates**: Edit files locally and see changes immediately (no container restart needed)

### Notes

- Restart WordPress container if themes/plugins don't appear: `docker-compose restart wordpress`
- File permissions are managed by Docker automatically
- Any themes/plugins installed through WordPress admin will persist in these directories

## File Structure

```
/var/lib/docker/volumes/
├── wordpress_db_data/          # MySQL data
├── wordpress_wordpress_data/   # WordPress files
├── wordpress_certbot_data/     # Certbot challenge files
└── wordpress_letsencrypt_data/ # SSL certificates

Local directories (mounted as volumes):
├── themes/                     # Custom WordPress themes (./themes → /var/www/html/wp-content/themes)
└── plugins/                    # Custom WordPress plugins (./plugins → /var/www/html/wp-content/plugins)
```

## Nginx Configuration Details

### HTTP Configuration (wordpress-http.conf)
- Listens on port 80
- Handles Let's Encrypt verification
- Redirects all traffic to HTTPS

### HTTPS Configuration (wordpress-https.conf)
- Listens on port 443 with HTTP/2
- SSL/TLS with modern security settings
- Security headers (HSTS, X-Frame-Options, etc.)
- Static file caching
- PHP-FPM connection to WordPress
- Upload size limit: 64MB

## Security Best Practices

1. **Strong Passwords**: Use strong, unique passwords in `.env`
2. **Keep Updated**: Regularly update Docker images
3. **Firewall**: Only allow ports 80, 443, and SSH
4. **Backups**: Regular database and file backups
5. **WordPress Security**: Install security plugins (Wordfence, etc.)
6. **File Permissions**: WordPress files are read-only in Nginx

## Troubleshooting

### SSL Certificate Issues

**Problem**: Certificate request fails

**Solutions**:
- Verify domain DNS points to your server: `dig +short yourdomain.com`
- Check ports 80 and 443 are open: `netstat -tuln | grep -E '80|443'`
- Check Nginx logs: `docker-compose logs nginx`
- Wait if rate-limited (5 failures per hour limit)

### WordPress Connection Issues

**Problem**: Error establishing database connection

**Solutions**:
- Check database is running: `docker-compose ps`
- Verify credentials in `.env`
- Check logs: `docker-compose logs db`
- Restart services: `docker-compose restart`

### Upload Issues

**Problem**: File upload fails

**Solutions**:
- Check `client_max_body_size` in nginx config
- Verify WordPress upload limits in PHP settings
- Check disk space: `df -h`

### Performance Issues

**Problem**: Site is slow

**Solutions**:
- Install WordPress caching plugin (WP Super Cache, W3 Total Cache)
- Optimize database
- Consider adding Redis for object caching
- Monitor resource usage: `docker stats`

## Customization

### Change Upload Limit

Edit `nginx/conf.d/wordpress-https.conf`:
```nginx
client_max_body_size 128M;  # Increase from 64M
```

Edit WordPress environment in `docker-compose.yml`:
```yaml
WORDPRESS_CONFIG_EXTRA: |
  define('WP_MEMORY_LIMIT', '256M');
```

### Add Redis Caching

Add to `docker-compose.yml`:
```yaml
  redis:
    image: redis:alpine
    container_name: wordpress_redis
    restart: always
    networks:
      - wordpress_network
```

Install Redis Object Cache plugin in WordPress.

## Additional Resources

- [WordPress Codex](https://codex.wordpress.org/)
- [Docker Documentation](https://docs.docker.com/)
- [Let's Encrypt Documentation](https://letsencrypt.org/docs/)
- [Nginx Documentation](https://nginx.org/en/docs/)

## License

This configuration is provided as-is for use in your own projects.

## Support

For issues:
1. Check the troubleshooting section
2. Review Docker logs
3. Verify configuration files
4. Check official documentation for each component
