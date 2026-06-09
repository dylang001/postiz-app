#!/bin/sh
set -e

# Replace nginx port with Render's dynamic PORT env var
sed -i "s/listen 5000/listen ${PORT:-5000}/g" /etc/nginx/nginx.conf

# Start nginx in background, then run the original Postiz startup command
nginx
pnpm run pm2
