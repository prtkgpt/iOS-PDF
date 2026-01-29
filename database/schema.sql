-- FileToPDF Database Schema for Neon PostgreSQL

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Conversions table - stores all file conversion records
CREATE TABLE IF NOT EXISTS conversions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    device_id VARCHAR(255) NOT NULL,
    original_filename VARCHAR(500) NOT NULL,
    original_format VARCHAR(50) NOT NULL,
    original_size_bytes BIGINT NOT NULL,
    pdf_url TEXT,
    pdf_size_bytes BIGINT,
    status VARCHAR(50) NOT NULL DEFAULT 'pending',
    error_message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP WITH TIME ZONE,
    expires_at TIMESTAMP WITH TIME ZONE DEFAULT (CURRENT_TIMESTAMP + INTERVAL '7 days')
);

-- Index for faster device-based queries
CREATE INDEX IF NOT EXISTS idx_conversions_device_id ON conversions(device_id);

-- Index for status queries
CREATE INDEX IF NOT EXISTS idx_conversions_status ON conversions(status);

-- Index for cleanup queries (expired files)
CREATE INDEX IF NOT EXISTS idx_conversions_expires_at ON conversions(expires_at);

-- Supported formats reference table
CREATE TABLE IF NOT EXISTS supported_formats (
    id SERIAL PRIMARY KEY,
    extension VARCHAR(20) NOT NULL UNIQUE,
    mime_type VARCHAR(100) NOT NULL,
    category VARCHAR(50) NOT NULL,
    max_size_mb INTEGER DEFAULT 50,
    is_active BOOLEAN DEFAULT true
);

-- Insert supported formats
INSERT INTO supported_formats (extension, mime_type, category, max_size_mb) VALUES
    -- Documents
    ('txt', 'text/plain', 'document', 10),
    ('rtf', 'application/rtf', 'document', 20),
    ('doc', 'application/msword', 'document', 50),
    ('docx', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document', 'document', 50),
    ('odt', 'application/vnd.oasis.opendocument.text', 'document', 50),

    -- Images
    ('jpg', 'image/jpeg', 'image', 25),
    ('jpeg', 'image/jpeg', 'image', 25),
    ('png', 'image/png', 'image', 25),
    ('gif', 'image/gif', 'image', 10),
    ('heic', 'image/heic', 'image', 25),
    ('webp', 'image/webp', 'image', 25),
    ('bmp', 'image/bmp', 'image', 25),
    ('tiff', 'image/tiff', 'image', 50),

    -- Spreadsheets
    ('csv', 'text/csv', 'spreadsheet', 20),
    ('xls', 'application/vnd.ms-excel', 'spreadsheet', 50),
    ('xlsx', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', 'spreadsheet', 50),

    -- Presentations
    ('ppt', 'application/vnd.ms-powerpoint', 'presentation', 100),
    ('pptx', 'application/vnd.openxmlformats-officedocument.presentationml.presentation', 'presentation', 100),

    -- Web
    ('html', 'text/html', 'web', 10),
    ('htm', 'text/html', 'web', 10),

    -- Other
    ('md', 'text/markdown', 'document', 10),
    ('json', 'application/json', 'data', 10),
    ('xml', 'application/xml', 'data', 10)
ON CONFLICT (extension) DO NOTHING;

-- Usage statistics table
CREATE TABLE IF NOT EXISTS usage_stats (
    id SERIAL PRIMARY KEY,
    date DATE NOT NULL DEFAULT CURRENT_DATE,
    total_conversions INTEGER DEFAULT 0,
    successful_conversions INTEGER DEFAULT 0,
    failed_conversions INTEGER DEFAULT 0,
    total_bytes_processed BIGINT DEFAULT 0,
    UNIQUE(date)
);

-- Function to update usage stats
CREATE OR REPLACE FUNCTION update_usage_stats()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO usage_stats (date, total_conversions, successful_conversions, failed_conversions, total_bytes_processed)
    VALUES (
        CURRENT_DATE,
        1,
        CASE WHEN NEW.status = 'completed' THEN 1 ELSE 0 END,
        CASE WHEN NEW.status = 'failed' THEN 1 ELSE 0 END,
        COALESCE(NEW.original_size_bytes, 0)
    )
    ON CONFLICT (date) DO UPDATE SET
        total_conversions = usage_stats.total_conversions + 1,
        successful_conversions = usage_stats.successful_conversions +
            CASE WHEN NEW.status = 'completed' THEN 1 ELSE 0 END,
        failed_conversions = usage_stats.failed_conversions +
            CASE WHEN NEW.status = 'failed' THEN 1 ELSE 0 END,
        total_bytes_processed = usage_stats.total_bytes_processed + COALESCE(NEW.original_size_bytes, 0);

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for usage stats
DROP TRIGGER IF EXISTS trigger_update_usage_stats ON conversions;
CREATE TRIGGER trigger_update_usage_stats
    AFTER INSERT OR UPDATE ON conversions
    FOR EACH ROW
    EXECUTE FUNCTION update_usage_stats();

-- View for recent conversions with format info
CREATE OR REPLACE VIEW recent_conversions AS
SELECT
    c.id,
    c.device_id,
    c.original_filename,
    c.original_format,
    sf.category as format_category,
    c.original_size_bytes,
    c.pdf_url,
    c.pdf_size_bytes,
    c.status,
    c.error_message,
    c.created_at,
    c.completed_at,
    c.expires_at
FROM conversions c
LEFT JOIN supported_formats sf ON LOWER(c.original_format) = sf.extension
ORDER BY c.created_at DESC;
