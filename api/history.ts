import type { VercelRequest, VercelResponse } from '@vercel/node';
import { getConversionsByDeviceId, getConversionById } from '../lib/db';

export default async function handler(req: VercelRequest, res: VercelResponse) {
  // Enable CORS
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, X-Device-ID');

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  if (req.method !== 'GET') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    const deviceId = req.headers['x-device-id'] as string;

    // If conversionId is provided, get single conversion
    const { id, limit = '50' } = req.query;

    if (id && typeof id === 'string') {
      const conversion = await getConversionById(id);

      if (!conversion) {
        return res.status(404).json({ error: 'Conversion not found' });
      }

      return res.status(200).json({
        success: true,
        conversion: {
          id: conversion.id,
          deviceId: conversion.device_id,
          originalFilename: conversion.original_filename,
          originalFormat: conversion.original_format,
          originalSizeBytes: conversion.original_size_bytes,
          pdfUrl: conversion.pdf_url,
          pdfSizeBytes: conversion.pdf_size_bytes,
          status: conversion.status,
          errorMessage: conversion.error_message,
          createdAt: conversion.created_at,
          completedAt: conversion.completed_at,
          expiresAt: conversion.expires_at
        }
      });
    }

    // Get conversion history for device
    if (!deviceId) {
      return res.status(400).json({ error: 'Device ID is required' });
    }

    const parsedLimit = Math.min(parseInt(limit as string) || 50, 100);
    const conversions = await getConversionsByDeviceId(deviceId, parsedLimit);

    return res.status(200).json({
      success: true,
      conversions: conversions.map(c => ({
        id: c.id,
        originalFilename: c.original_filename,
        originalFormat: c.original_format,
        originalSizeBytes: c.original_size_bytes,
        pdfUrl: c.pdf_url,
        pdfSizeBytes: c.pdf_size_bytes,
        status: c.status,
        errorMessage: c.error_message,
        createdAt: c.created_at,
        completedAt: c.completed_at,
        expiresAt: c.expires_at
      })),
      total: conversions.length
    });
  } catch (error) {
    console.error('History error:', error);
    return res.status(500).json({
      error: 'Internal server error',
      message: error instanceof Error ? error.message : 'Unknown error'
    });
  }
}
