import { neon, neonConfig } from '@neondatabase/serverless';

// Configure Neon for serverless environment
neonConfig.fetchConnectionCache = true;

// Create database connection
export const sql = neon(process.env.DATABASE_URL!);

// Types for database records
export interface Conversion {
  id: string;
  device_id: string;
  original_filename: string;
  original_format: string;
  original_size_bytes: number;
  pdf_url: string | null;
  pdf_size_bytes: number | null;
  status: 'pending' | 'processing' | 'completed' | 'failed';
  error_message: string | null;
  created_at: Date;
  completed_at: Date | null;
  expires_at: Date;
}

export interface SupportedFormat {
  id: number;
  extension: string;
  mime_type: string;
  category: string;
  max_size_mb: number;
  is_active: boolean;
}

// Database operations
export async function createConversion(data: {
  deviceId: string;
  originalFilename: string;
  originalFormat: string;
  originalSizeBytes: number;
}): Promise<Conversion> {
  const result = await sql`
    INSERT INTO conversions (device_id, original_filename, original_format, original_size_bytes, status)
    VALUES (${data.deviceId}, ${data.originalFilename}, ${data.originalFormat}, ${data.originalSizeBytes}, 'pending')
    RETURNING *
  `;
  return result[0] as Conversion;
}

export async function updateConversionStatus(
  id: string,
  status: Conversion['status'],
  updates?: {
    pdfUrl?: string;
    pdfSizeBytes?: number;
    errorMessage?: string;
  }
): Promise<Conversion> {
  if (status === 'completed' && updates?.pdfUrl) {
    const result = await sql`
      UPDATE conversions
      SET status = ${status},
          pdf_url = ${updates.pdfUrl},
          pdf_size_bytes = ${updates.pdfSizeBytes || null},
          completed_at = CURRENT_TIMESTAMP
      WHERE id = ${id}
      RETURNING *
    `;
    return result[0] as Conversion;
  } else if (status === 'failed') {
    const result = await sql`
      UPDATE conversions
      SET status = ${status},
          error_message = ${updates?.errorMessage || 'Unknown error'},
          completed_at = CURRENT_TIMESTAMP
      WHERE id = ${id}
      RETURNING *
    `;
    return result[0] as Conversion;
  } else {
    const result = await sql`
      UPDATE conversions
      SET status = ${status}
      WHERE id = ${id}
      RETURNING *
    `;
    return result[0] as Conversion;
  }
}

export async function getConversionById(id: string): Promise<Conversion | null> {
  const result = await sql`
    SELECT * FROM conversions WHERE id = ${id}
  `;
  return result[0] as Conversion || null;
}

export async function getConversionsByDeviceId(
  deviceId: string,
  limit: number = 50
): Promise<Conversion[]> {
  const result = await sql`
    SELECT * FROM conversions
    WHERE device_id = ${deviceId}
    ORDER BY created_at DESC
    LIMIT ${limit}
  `;
  return result as Conversion[];
}

export async function getSupportedFormats(): Promise<SupportedFormat[]> {
  const result = await sql`
    SELECT * FROM supported_formats WHERE is_active = true ORDER BY category, extension
  `;
  return result as SupportedFormat[];
}

export async function isFormatSupported(extension: string): Promise<boolean> {
  const result = await sql`
    SELECT COUNT(*) as count FROM supported_formats
    WHERE extension = ${extension.toLowerCase()} AND is_active = true
  `;
  return parseInt(result[0].count) > 0;
}

export async function deleteExpiredConversions(): Promise<number> {
  const result = await sql`
    DELETE FROM conversions
    WHERE expires_at < CURRENT_TIMESTAMP
    RETURNING id
  `;
  return result.length;
}
