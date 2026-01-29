# FileToPDF Setup Guide

This guide walks you through deploying the FileToPDF backend to Vercel with a Neon PostgreSQL database, all through your browser.

## Step 1: Create a Neon PostgreSQL Database

1. Go to [neon.tech](https://neon.tech) and sign up/log in
2. Click **Create Project**
3. Choose a project name (e.g., `filetopdf`)
4. Select your preferred region
5. Click **Create Project**
6. Copy the **Connection String** (it looks like `postgresql://user:password@ep-xxx.us-east-1.aws.neon.tech/neondb?sslmode=require`)

### Run the Database Schema

1. In Neon Console, click **SQL Editor** in the sidebar
2. Copy the contents of `database/schema.sql` from this repo
3. Paste it into the SQL Editor
4. Click **Run** to create the tables

## Step 2: Deploy to Vercel

### Option A: Deploy via GitHub (Recommended)

1. Push this repository to your GitHub account
2. Go to [vercel.com](https://vercel.com) and sign up/log in with GitHub
3. Click **Add New Project**
4. Import your `iOS-PDF` repository
5. Configure the project:
   - **Framework Preset**: Other
   - **Root Directory**: `.` (leave as default)
6. Add Environment Variables:
   - `DATABASE_URL`: Your Neon connection string
7. Click **Deploy**

### Option B: Deploy via Vercel CLI

```bash
npm install -g vercel
vercel login
vercel --prod
```

## Step 3: Set Up Vercel Blob Storage

1. In Vercel Dashboard, go to your project
2. Click **Storage** tab
3. Click **Create Database** → **Blob**
4. Name it (e.g., `filetopdf-storage`)
5. Click **Create**
6. The `BLOB_READ_WRITE_TOKEN` will be automatically added to your environment

## Step 4: Configure the iOS App

1. Open `ios/FileToPDF/Config.swift`
2. Update the `apiBaseURL` with your Vercel deployment URL:

```swift
static let apiBaseURL = "https://your-app-name.vercel.app"
```

3. Open the project in Xcode
4. Build and run on your device or simulator

## Step 5: Test the API

Test the health endpoint:
```
https://your-app-name.vercel.app/api/health
```

Test the formats endpoint:
```
https://your-app-name.vercel.app/api/formats
```

## Environment Variables Summary

| Variable | Description | Where to get it |
|----------|-------------|-----------------|
| `DATABASE_URL` | Neon PostgreSQL connection string | Neon Dashboard → Connection Details |
| `BLOB_READ_WRITE_TOKEN` | Vercel Blob storage token | Auto-created when adding Blob storage |

## Troubleshooting

### Database Connection Errors
- Make sure your `DATABASE_URL` includes `?sslmode=require` at the end
- Check that the Neon project is not paused (free tier pauses after inactivity)

### Conversion Timeouts
- Large files may take longer to process
- The API has a 60-second timeout by default
- Consider upgrading Vercel plan for longer timeouts

### iOS App Not Connecting
- Verify the API URL is correct in `Config.swift`
- Check that the Vercel deployment is successful
- Test the `/api/health` endpoint in your browser

## Cost Estimates

### Neon (Free Tier)
- 0.5 GB storage
- 3 GB data transfer/month
- 1 project

### Vercel (Hobby Plan - Free)
- 100 GB bandwidth/month
- 6000 minutes build time/month
- Serverless functions

For production usage, consider upgrading to paid tiers.
