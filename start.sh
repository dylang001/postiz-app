#!/bin/sh
# Don't exit on errors - we need to see logs
set +e

echo "=== Postiz Startup Script ==="
echo "PORT=${PORT}"
echo "MAIN_URL=${MAIN_URL}"
echo "DATABASE_URL is set: $(test -n "$DATABASE_URL" && echo 'yes' || echo 'no')"

# Replace nginx port with Render's dynamic PORT env var
sed -i "s/listen 5000/listen ${PORT:-5000}/g" /etc/nginx/nginx.conf
echo "=== Nginx config updated ==="

# Start nginx
nginx
echo "=== Nginx started ==="

# Wait a moment for nginx to bind
sleep 2

# Run Prisma db push with retry (database might not be ready immediately)
echo "=== Running Prisma DB Push ==="
MAX_RETRIES=5
RETRY_COUNT=0
while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    pnpm dlx prisma@6.5.0 db push --accept-data-loss --schema ./libraries/nestjs-libraries/src/database/prisma/schema.prisma
    if [ $? -eq 0 ]; then
        echo "=== Prisma DB Push succeeded ==="
        break
    fi
    RETRY_COUNT=$((RETRY_COUNT + 1))
    echo "=== Prisma DB Push failed, retry ${RETRY_COUNT}/${MAX_RETRIES} in 10s ==="
    sleep 10
done

# Start backend directly (skip pm2 to simplify debugging)
echo "=== Starting Backend ==="
cd /app
node --experimental-require-module ./dist/apps/backend/src/main.js &
BACKEND_PID=$!

# Start frontend
echo "=== Starting Frontend ==="
cd /app/apps/frontend
next start -p 4200 &
FRONTEND_PID=$!

echo "=== Backend PID: $BACKEND_PID, Frontend PID: $FRONTEND_PID ==="

# Wait for processes
wait $BACKEND_PID $FRONTEND_PID
