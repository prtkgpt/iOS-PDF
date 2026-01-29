import { put, del, list } from '@vercel/blob';
import { v4 as uuidv4 } from 'uuid';

export interface UploadResult {
  success: true;
  url: string;
  size: number;
} | {
  success: false;
  error: string;
}

// Upload PDF to Vercel Blob storage
export async function uploadPdf(
  pdfBuffer: Buffer,
  originalFilename: string,
  conversionId: string
): Promise<UploadResult> {
  try {
    const pdfFilename = `${conversionId}/${sanitizeFilename(originalFilename)}.pdf`;

    const blob = await put(pdfFilename, pdfBuffer, {
      access: 'public',
      contentType: 'application/pdf',
      addRandomSuffix: false,
    });

    return {
      success: true,
      url: blob.url,
      size: pdfBuffer.length
    };
  } catch (error) {
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Upload failed'
    };
  }
}

// Delete PDF from Vercel Blob storage
export async function deletePdf(url: string): Promise<boolean> {
  try {
    await del(url);
    return true;
  } catch (error) {
    console.error('Failed to delete blob:', error);
    return false;
  }
}

// List all PDFs for cleanup
export async function listExpiredPdfs(prefix?: string): Promise<string[]> {
  try {
    const { blobs } = await list({ prefix });
    return blobs.map(blob => blob.url);
  } catch (error) {
    console.error('Failed to list blobs:', error);
    return [];
  }
}

// Sanitize filename for storage
function sanitizeFilename(filename: string): string {
  // Remove file extension
  const nameWithoutExt = filename.replace(/\.[^/.]+$/, '');

  // Replace invalid characters
  return nameWithoutExt
    .replace(/[^a-zA-Z0-9_-]/g, '_')
    .substring(0, 100);
}

// Generate unique conversion ID
export function generateConversionId(): string {
  return uuidv4();
}

// Get content type from file extension
export function getContentType(extension: string): string {
  const contentTypes: Record<string, string> = {
    // Documents
    'txt': 'text/plain',
    'rtf': 'application/rtf',
    'doc': 'application/msword',
    'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'odt': 'application/vnd.oasis.opendocument.text',

    // Images
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'gif': 'image/gif',
    'heic': 'image/heic',
    'webp': 'image/webp',
    'bmp': 'image/bmp',
    'tiff': 'image/tiff',

    // Spreadsheets
    'csv': 'text/csv',
    'xls': 'application/vnd.ms-excel',
    'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',

    // Presentations
    'ppt': 'application/vnd.ms-powerpoint',
    'pptx': 'application/vnd.openxmlformats-officedocument.presentationml.presentation',

    // Web
    'html': 'text/html',
    'htm': 'text/html',

    // Data
    'json': 'application/json',
    'xml': 'application/xml',
    'md': 'text/markdown',
  };

  return contentTypes[extension.toLowerCase()] || 'application/octet-stream';
}
