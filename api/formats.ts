import type { VercelRequest, VercelResponse } from '@vercel/node';
import { getSupportedFormats } from '../lib/db';

export default async function handler(req: VercelRequest, res: VercelResponse) {
  // Enable CORS
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  if (req.method !== 'GET') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    const formats = await getSupportedFormats();

    // Group by category
    const grouped = formats.reduce((acc, format) => {
      if (!acc[format.category]) {
        acc[format.category] = [];
      }
      acc[format.category].push({
        extension: format.extension,
        mimeType: format.mime_type,
        maxSizeMb: format.max_size_mb
      });
      return acc;
    }, {} as Record<string, Array<{ extension: string; mimeType: string; maxSizeMb: number }>>);

    return res.status(200).json({
      success: true,
      formats: grouped,
      allExtensions: formats.map(f => f.extension)
    });
  } catch (error) {
    console.error('Formats error:', error);
    return res.status(500).json({
      error: 'Internal server error',
      message: error instanceof Error ? error.message : 'Unknown error'
    });
  }
}
