# Extend the official Postiz Docker image for Render deployment
FROM ghcr.io/gitroomhq/postiz-app:latest

COPY start.sh /start.sh
RUN chmod +x /start.sh

CMD ["/start.sh"]
