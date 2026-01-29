# FileToPDF - iOS File to PDF Converter

A native iOS app that converts any file format to PDF, powered by a Vercel serverless backend and Neon PostgreSQL database.

## Architecture

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   iOS App       │────▶│  Vercel API     │────▶│  Neon PostgreSQL│
│   (SwiftUI)     │◀────│  (Node.js)      │◀────│  Database       │
└─────────────────┘     └─────────────────┘     └─────────────────┘
```

## Features

- 📄 Convert documents (DOC, DOCX, TXT, RTF) to PDF
- 🖼️ Convert images (PNG, JPG, HEIC, GIF) to PDF
- 📊 Convert spreadsheets (XLS, XLSX, CSV) to PDF
- 📝 Convert presentations (PPT, PPTX) to PDF
- 🌐 Convert web pages (HTML) to PDF
- 📜 View conversion history
- ☁️ Cloud-based processing

## Project Structure

```
iOS-PDF/
├── api/                    # Vercel serverless functions
│   ├── convert.ts          # Main conversion endpoint
│   ├── history.ts          # Conversion history endpoint
│   └── health.ts           # Health check endpoint
├── lib/                    # Shared backend utilities
│   ├── db.ts               # Database connection
│   ├── converter.ts        # PDF conversion logic
│   └── storage.ts          # File storage utilities
├── ios/                    # iOS app source
│   └── FileToPDF/          # Xcode project
├── database/               # Database migrations
│   └── schema.sql          # PostgreSQL schema
├── package.json            # Node.js dependencies
├── vercel.json             # Vercel configuration
└── .env.example            # Environment variables template
```

## Setup

### Prerequisites

- Node.js 18+
- Xcode 15+
- Vercel CLI
- Neon PostgreSQL account

### Backend Setup

1. Clone the repository
2. Install dependencies: `npm install`
3. Copy `.env.example` to `.env` and fill in your credentials
4. Deploy to Vercel: `vercel deploy`

### iOS Setup

1. Open `ios/FileToPDF.xcodeproj` in Xcode
2. Update the API base URL in `Config.swift`
3. Build and run on simulator or device

### Database Setup

1. Create a Neon PostgreSQL database
2. Run the schema: `psql $DATABASE_URL < database/schema.sql`

## Environment Variables

| Variable | Description |
|----------|-------------|
| `DATABASE_URL` | Neon PostgreSQL connection string |
| `BLOB_READ_WRITE_TOKEN` | Vercel Blob storage token |

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/convert` | Upload and convert file to PDF |
| GET | `/api/history` | Get conversion history |
| GET | `/api/health` | Health check |

## License

MIT
