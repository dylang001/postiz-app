# Extend the official Postiz Docker image for Render deployment
FROM ghcr.io/gitroomhq/postiz-app:latest

# Create a startup script that configures nginx for Render's dynamic PORT
RUN echo '#!/bin/sh\n\
# Replace nginx port with Render PORT env var\n\
sed -i "s/listen 5000/listen ${PORT:-5000}/g" /etc/nginx/nginx.conf\n\
# Start nginx in background\n\
nginx\n\
# Start the app via pm2\n\
pnpm run pm2\n\
' > /start.sh && chmod +x /start.sh

CMD ["/start.sh"]
