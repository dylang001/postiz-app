#!/bin/sh
set -e

# Replace nginx port with Render's dynamic PORT env var
sed -i "s/listen 5000/listen ${PORT:-5000}/g" /etc/nginx/nginx.conf

# Start nginx
nginx

# Start the app via pm2
pnpm run pm2
