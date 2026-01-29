import type { VercelRequest, VercelResponse } from '@vercel/node';
import { createConversion, updateConversionStatus, isFormatSupported } from '../lib/db';
import { convertToPdf, getFileExtension, validateFileSize } from '../lib/converter';
import { uploadPdf, generateConversionId } from '../lib/storage';

// Maximum file size: 50MB
const MAX_FILE_SIZE = 50 * 1024 * 1024;

export const config = {
  api: {
    bodyParser: {
      sizeLimit: '50mb',
    },
  },
};

export default async function handler(req: VercelRequest, res: VercelResponse) {
  // Enable CORS
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, X-Device-ID');

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    const deviceId = req.headers['x-device-id'] as string;
    if (!deviceId) {
      return res.status(400).json({ error: 'Device ID is required' });
    }

    // Parse multipart form data
    const contentType = req.headers['content-type'] || '';

    if (!contentType.includes('application/json')) {
      return res.status(400).json({ error: 'Content-Type must be application/json with base64 file data' });
    }

    const { filename, fileData, mimeType } = req.body as {
      filename: string;
      fileData: string; // base64 encoded
      mimeType: string;
    };

    if (!filename || !fileData) {
      return res.status(400).json({ error: 'Filename and fileData are required' });
    }

    // Decode base64 file data
    const fileBuffer = Buffer.from(fileData, 'base64');
    const fileSize = fileBuffer.length;

    // Validate file size
    if (!validateFileSize(fileSize, 50)) {
      return res.status(400).json({
        error: 'File too large',
        maxSize: '50MB',
        actualSize: `${(fileSize / 1024 / 1024).toFixed(2)}MB`
      });
    }

    // Get and validate file extension
    const extension = getFileExtension(filename);
    if (!extension) {
      return res.status(400).json({ error: 'Could not determine file type' });
    }

    const isSupported = await isFormatSupported(extension);
    if (!isSupported) {
      return res.status(400).json({
        error: 'Unsupported file format',
        format: extension,
        supportedFormats: [
          'txt', 'rtf', 'doc', 'docx',
          'jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'tiff', 'heic',
          'csv', 'xls', 'xlsx',
          'html', 'htm',
          'json', 'xml', 'md'
        ]
      });
    }

    // Create conversion record in database
    const conversionId = generateConversionId();
    const conversion = await createConversion({
      deviceId,
      originalFilename: filename,
      originalFormat: extension,
      originalSizeBytes: fileSize
    });

    // Update status to processing
    await updateConversionStatus(conversion.id, 'processing');

    // Perform conversion
    const conversionResult = await convertToPdf(fileBuffer, filename, mimeType);

    if (!conversionResult.success) {
      await updateConversionStatus(conversion.id, 'failed', {
        errorMessage: conversionResult.error
      });
      return res.status(500).json({
        error: 'Conversion failed',
        message: conversionResult.error,
        conversionId: conversion.id
      });
    }

    // Upload PDF to storage
    const uploadResult = await uploadPdf(
      conversionResult.pdfBuffer,
      filename,
      conversion.id
    );

    if (!uploadResult.success) {
      await updateConversionStatus(conversion.id, 'failed', {
        errorMessage: uploadResult.error
      });
      return res.status(500).json({
        error: 'Upload failed',
        message: uploadResult.error,
        conversionId: conversion.id
      });
    }

    // Update conversion with success
    const completedConversion = await updateConversionStatus(conversion.id, 'completed', {
      pdfUrl: uploadResult.url,
      pdfSizeBytes: uploadResult.size
    });

    return res.status(200).json({
      success: true,
      conversion: {
        id: completedConversion.id,
        originalFilename: completedConversion.original_filename,
        originalFormat: completedConversion.original_format,
        originalSizeBytes: completedConversion.original_size_bytes,
        pdfUrl: completedConversion.pdf_url,
        pdfSizeBytes: completedConversion.pdf_size_bytes,
        pageCount: conversionResult.pageCount,
        status: completedConversion.status,
        createdAt: completedConversion.created_at,
        completedAt: completedConversion.completed_at,
        expiresAt: completedConversion.expires_at
      }
    });
  } catch (error) {
    console.error('Conversion error:', error);
    return res.status(500).json({
      error: 'Internal server error',
      message: error instanceof Error ? error.message : 'Unknown error'
    });
  }
}
