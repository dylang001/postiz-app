# Postiz Deployment on Render

This guide covers deploying Postiz to [Render](https://render.com).

## Architecture Overview

Postiz requires four services:

| Service       | Render Option                           |
|---------------|------------------------------------------|
| Postiz App    | Render Web Service (Docker)             |
| PostgreSQL    | Render Managed PostgreSQL               |
| Redis         | Render Managed Redis (Upstash)          |
| Temporal      | Temporal Cloud (recommended) or Private Services |

## Prerequisites

- A [Render](https://render.com) account
- A [Temporal Cloud](https://temporal.io/cloud) account (free tier available)
- Your forked repo pushed to GitHub (`dylang001/postiz-app`)

## Step 1: Set Up Temporal Cloud (Free Tier)

1. Sign up at [https://temporal.io/cloud](https://temporal.io/cloud)
2. Create a new Namespace
3. Generate an API Key
4. Note your Temporal gRPC endpoint (looks like `your-namespace.tmprl.cloud:7233`)

> **Why Temporal Cloud?** Self-hosting Temporal on Render requires running PostgreSQL, Elasticsearch, and the Temporal server as separate Private Services. This consumes significant resources and is complex to maintain. Temporal Cloud's free tier covers most single-user/small-team use cases.

## Step 2: Deploy to Render (Blueprint)

### Option A: Blueprint Deploy (Recommended)

1. In the Render Dashboard, go to **Blueprints** and click **New Blueprint**
2. Connect your GitHub repo `dylang001/postiz-app`
3. Render will read `render.yaml` and provision:
   - Web Service (`postiz-app`) using the official Docker image
   - PostgreSQL database (`postiz-db`)
   - Redis instance (`postiz-redis`)
4. After provisioning, set the required environment variables in the Render dashboard:
   - `MAIN_URL` - Your Render service URL (e.g., `https://postiz-app.onrender.com`)
   - `FRONTEND_URL` - Same as `MAIN_URL`
   - `NEXT_PUBLIC_BACKEND_URL` - e.g., `https://postiz-app.onrender.com/api`
   - `TEMPORAL_ADDRESS` - Your Temporal Cloud endpoint (e.g., `your-namespace.tmprl.cloud:7233`)

### Option B: Manual Deploy

1. **Create PostgreSQL**: Dashboard > New > PostgreSQL. Name it `postiz-db`. Choose `Starter` plan.
2. **Create Redis**: Dashboard > New > Key Value (Redis). Name it `postiz-redis`. Choose `Free` plan.
3. **Create Web Service**:
   - New > Web Service
   - Connect `dylang001/postiz-app`
   - Runtime: `Docker`
   - Render will auto-detect the image from `render.yaml`
   - Set environment variables (see below)
   - Add Disk: Name `uploads`, Mount Path `/uploads`, Size 5GB

## Step 3: Required Environment Variables

| Variable                | Source / Value                                    |
|-------------------------|-----------------------------------------------------|
| `DATABASE_URL`          | From Render PostgreSQL (auto-populated in blueprint)|
| `REDIS_URL`             | From Render Redis (auto-populated in blueprint)   |
| `JWT_SECRET`            | Auto-generated in blueprint                         |
| `MAIN_URL`              | `https://postiz-app-xxxx.onrender.com`              |
| `FRONTEND_URL`          | Same as `MAIN_URL`                                  |
| `NEXT_PUBLIC_BACKEND_URL`| `https://postiz-app-xxxx.onrender.com/api`         |
| `BACKEND_INTERNAL_URL`  | `http://localhost:3000`                             |
| `TEMPORAL_ADDRESS`      | Your Temporal Cloud gRPC endpoint                  |
| `IS_GENERAL`            | `true`                                              |
| `STORAGE_PROVIDER`      | `local`                                             |
| `UPLOAD_DIRECTORY`      | `/uploads`                                          |
| `DISABLE_REGISTRATION`  | `false`                                             |

## Step 4: Post-Deploy Setup

1. Wait for the service to finish deploying (check the Deploy Log)
2. Visit your Render URL
3. Create your admin account
4. Go to **Settings** > **Providers** to connect social media accounts
5. You'll need API credentials from each platform's developer portal:
   - **X (Twitter)**: [developer.x.com](https://developer.x.com)
   - **LinkedIn**: [linkedin.com/developers](https://linkedin.com/developers)
   - **Instagram**: Via Facebook Developers
   - **Bluesky / Mastodon**: No API key needed

## Optional: Custom Domain & HTTPS

1. In Render Dashboard, go to your Web Service > Settings > Custom Domain
2. Add your domain and follow Render's DNS instructions
3. Update `MAIN_URL`, `FRONTEND_URL`, and `NEXT_PUBLIC_BACKEND_URL` to use your custom domain
4. Re-deploy the service

## Storage Considerations

The default `STORAGE_PROVIDER=local` stores uploads on the Render Disk (`/uploads`). Note:
- Render disks are ephemeral on free/starter plans (data persists across restarts but not if you delete the service)
- For production with many users, switch to Cloudflare R2 by setting:
  - `STORAGE_PROVIDER=cloudflare`
  - `CLOUDFLARE_ACCOUNT_ID`, `CLOUDFLARE_ACCESS_KEY`, `CLOUDFLARE_SECRET_ACCESS_KEY`, `CLOUDFLARE_BUCKETNAME`, `CLOUDFLARE_BUCKET_URL`

## Troubleshooting

### Service won't start
Check the Deploy Log for missing environment variables. The most common issue is a missing `TEMPORAL_ADDRESS`.

### Database connection errors
Ensure `DATABASE_URL` uses the internal Render PostgreSQL connection string (it should start with `postgresql://postiz:...` not `localhost`).

### Redis connection errors
Ensure `REDIS_URL` starts with `redis://` and points to the Render Redis internal URL.

### Scheduled posts not working
Check that `TEMPORAL_ADDRESS` is correct and the Temporal Namespace is accessible. Check Temporal Cloud dashboard for workflow activity.

## Costs Estimate (Render)

| Service          | Plan     | Monthly Cost |
|------------------|----------|--------------|
| Web Service      | Starter  | $7           |
| PostgreSQL       | Starter  | $7           |
| Redis            | Free     | $0           |
| Temporal Cloud   | Free     | $0           |
| **Total**        |          | **~$14**     |

Upgrade to Standard ($25/mo) for more RAM/CPU if you have multiple active users.
