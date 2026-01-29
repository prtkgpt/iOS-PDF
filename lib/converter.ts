import { PDFDocument, rgb, StandardFonts } from 'pdf-lib';
import sharp from 'sharp';
import mammoth from 'mammoth';
import * as XLSX from 'xlsx';

export type ConversionResult = {
  success: true;
  pdfBuffer: Buffer;
  pageCount: number;
} | {
  success: false;
  error: string;
};

// Main conversion function that routes to specific converters
export async function convertToPdf(
  fileBuffer: Buffer,
  filename: string,
  mimeType: string
): Promise<ConversionResult> {
  const extension = filename.split('.').pop()?.toLowerCase() || '';

  try {
    switch (extension) {
      // Images
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'webp':
      case 'gif':
      case 'bmp':
      case 'tiff':
      case 'heic':
        return await convertImageToPdf(fileBuffer, mimeType);

      // Documents
      case 'txt':
      case 'md':
        return await convertTextToPdf(fileBuffer, filename);

      case 'docx':
        return await convertDocxToPdf(fileBuffer);

      case 'rtf':
        return await convertRtfToPdf(fileBuffer);

      // Spreadsheets
      case 'csv':
      case 'xlsx':
      case 'xls':
        return await convertSpreadsheetToPdf(fileBuffer, extension);

      // HTML
      case 'html':
      case 'htm':
        return await convertHtmlToPdf(fileBuffer);

      // JSON/XML
      case 'json':
      case 'xml':
        return await convertDataFileToPdf(fileBuffer, extension);

      default:
        return {
          success: false,
          error: `Unsupported file format: ${extension}`
        };
    }
  } catch (error) {
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Unknown conversion error'
    };
  }
}

// Convert images to PDF
async function convertImageToPdf(buffer: Buffer, mimeType: string): Promise<ConversionResult> {
  try {
    // Use sharp to normalize the image and convert to PNG
    const normalizedImage = await sharp(buffer)
      .rotate() // Auto-rotate based on EXIF
      .png()
      .toBuffer();

    const metadata = await sharp(buffer).metadata();

    const pdfDoc = await PDFDocument.create();
    const pngImage = await pdfDoc.embedPng(normalizedImage);

    // Calculate page size to fit image with margins
    const imgWidth = metadata.width || 800;
    const imgHeight = metadata.height || 600;

    // A4 dimensions in points (72 points per inch)
    const maxWidth = 595 - 72; // A4 width minus margins
    const maxHeight = 842 - 72; // A4 height minus margins

    let finalWidth = imgWidth;
    let finalHeight = imgHeight;

    // Scale down if image is too large
    if (imgWidth > maxWidth || imgHeight > maxHeight) {
      const widthRatio = maxWidth / imgWidth;
      const heightRatio = maxHeight / imgHeight;
      const ratio = Math.min(widthRatio, heightRatio);
      finalWidth = imgWidth * ratio;
      finalHeight = imgHeight * ratio;
    }

    const page = pdfDoc.addPage([finalWidth + 72, finalHeight + 72]);
    page.drawImage(pngImage, {
      x: 36,
      y: 36,
      width: finalWidth,
      height: finalHeight,
    });

    const pdfBytes = await pdfDoc.save();

    return {
      success: true,
      pdfBuffer: Buffer.from(pdfBytes),
      pageCount: 1
    };
  } catch (error) {
    return {
      success: false,
      error: `Image conversion failed: ${error instanceof Error ? error.message : 'Unknown error'}`
    };
  }
}

// Convert plain text to PDF
async function convertTextToPdf(buffer: Buffer, filename: string): Promise<ConversionResult> {
  try {
    const text = buffer.toString('utf-8');
    const pdfDoc = await PDFDocument.create();
    const font = await pdfDoc.embedFont(StandardFonts.Courier);

    const fontSize = 10;
    const margin = 50;
    const pageWidth = 595; // A4
    const pageHeight = 842;
    const lineHeight = fontSize * 1.4;
    const maxCharsPerLine = Math.floor((pageWidth - 2 * margin) / (fontSize * 0.6));
    const maxLinesPerPage = Math.floor((pageHeight - 2 * margin) / lineHeight);

    // Split text into lines and wrap long lines
    const lines = text.split('\n');
    const wrappedLines: string[] = [];

    for (const line of lines) {
      if (line.length <= maxCharsPerLine) {
        wrappedLines.push(line);
      } else {
        // Word wrap
        let remaining = line;
        while (remaining.length > 0) {
          if (remaining.length <= maxCharsPerLine) {
            wrappedLines.push(remaining);
            break;
          }
          let breakPoint = remaining.lastIndexOf(' ', maxCharsPerLine);
          if (breakPoint === -1) breakPoint = maxCharsPerLine;
          wrappedLines.push(remaining.substring(0, breakPoint));
          remaining = remaining.substring(breakPoint + 1);
        }
      }
    }

    // Create pages
    let currentLine = 0;
    let pageCount = 0;

    while (currentLine < wrappedLines.length) {
      const page = pdfDoc.addPage([pageWidth, pageHeight]);
      pageCount++;

      let y = pageHeight - margin;

      for (let i = 0; i < maxLinesPerPage && currentLine < wrappedLines.length; i++) {
        page.drawText(wrappedLines[currentLine], {
          x: margin,
          y: y,
          size: fontSize,
          font: font,
          color: rgb(0, 0, 0),
        });
        y -= lineHeight;
        currentLine++;
      }
    }

    const pdfBytes = await pdfDoc.save();

    return {
      success: true,
      pdfBuffer: Buffer.from(pdfBytes),
      pageCount
    };
  } catch (error) {
    return {
      success: false,
      error: `Text conversion failed: ${error instanceof Error ? error.message : 'Unknown error'}`
    };
  }
}

// Convert DOCX to PDF
async function convertDocxToPdf(buffer: Buffer): Promise<ConversionResult> {
  try {
    // Extract text from DOCX using mammoth
    const result = await mammoth.extractRawText({ buffer });
    const text = result.value;

    // Convert the extracted text to PDF
    return await convertTextToPdf(Buffer.from(text, 'utf-8'), 'document.txt');
  } catch (error) {
    return {
      success: false,
      error: `DOCX conversion failed: ${error instanceof Error ? error.message : 'Unknown error'}`
    };
  }
}

// Convert RTF to PDF (basic implementation)
async function convertRtfToPdf(buffer: Buffer): Promise<ConversionResult> {
  try {
    // Basic RTF to plain text conversion
    let text = buffer.toString('utf-8');

    // Remove RTF control codes (basic)
    text = text.replace(/\\[a-z]+\d* ?/g, '');
    text = text.replace(/[{}]/g, '');
    text = text.replace(/\\\\/g, '\\');

    return await convertTextToPdf(Buffer.from(text, 'utf-8'), 'document.txt');
  } catch (error) {
    return {
      success: false,
      error: `RTF conversion failed: ${error instanceof Error ? error.message : 'Unknown error'}`
    };
  }
}

// Convert spreadsheets to PDF
async function convertSpreadsheetToPdf(buffer: Buffer, extension: string): Promise<ConversionResult> {
  try {
    const workbook = XLSX.read(buffer, { type: 'buffer' });
    const pdfDoc = await PDFDocument.create();
    const font = await pdfDoc.embedFont(StandardFonts.Helvetica);
    const boldFont = await pdfDoc.embedFont(StandardFonts.HelveticaBold);

    let totalPages = 0;

    for (const sheetName of workbook.SheetNames) {
      const sheet = workbook.Sheets[sheetName];
      const data = XLSX.utils.sheet_to_json<string[]>(sheet, { header: 1 });

      if (data.length === 0) continue;

      const pageWidth = 842; // A4 landscape
      const pageHeight = 595;
      const margin = 40;
      const rowHeight = 18;
      const maxRowsPerPage = Math.floor((pageHeight - 2 * margin - 30) / rowHeight);

      // Calculate column widths
      const numCols = Math.max(...data.map(row => (row as any[]).length));
      const colWidth = Math.min(120, (pageWidth - 2 * margin) / numCols);

      let rowIndex = 0;

      while (rowIndex < data.length) {
        const page = pdfDoc.addPage([pageWidth, pageHeight]);
        totalPages++;

        let y = pageHeight - margin;

        // Sheet name header
        page.drawText(`Sheet: ${sheetName}`, {
          x: margin,
          y: y,
          size: 12,
          font: boldFont,
          color: rgb(0, 0, 0),
        });
        y -= 25;

        // Draw rows
        for (let i = 0; i < maxRowsPerPage && rowIndex < data.length; i++) {
          const row = data[rowIndex] as any[];

          for (let colIndex = 0; colIndex < (row?.length || 0); colIndex++) {
            const cellValue = String(row[colIndex] ?? '').substring(0, 20);
            const x = margin + colIndex * colWidth;

            if (x < pageWidth - margin) {
              page.drawText(cellValue, {
                x: x,
                y: y,
                size: 9,
                font: rowIndex === 0 ? boldFont : font,
                color: rgb(0, 0, 0),
              });
            }
          }

          y -= rowHeight;
          rowIndex++;
        }
      }
    }

    const pdfBytes = await pdfDoc.save();

    return {
      success: true,
      pdfBuffer: Buffer.from(pdfBytes),
      pageCount: totalPages
    };
  } catch (error) {
    return {
      success: false,
      error: `Spreadsheet conversion failed: ${error instanceof Error ? error.message : 'Unknown error'}`
    };
  }
}

// Convert HTML to PDF (basic implementation)
async function convertHtmlToPdf(buffer: Buffer): Promise<ConversionResult> {
  try {
    let html = buffer.toString('utf-8');

    // Strip HTML tags for basic text extraction
    const text = html
      .replace(/<script[^>]*>[\s\S]*?<\/script>/gi, '')
      .replace(/<style[^>]*>[\s\S]*?<\/style>/gi, '')
      .replace(/<[^>]+>/g, '\n')
      .replace(/&nbsp;/g, ' ')
      .replace(/&lt;/g, '<')
      .replace(/&gt;/g, '>')
      .replace(/&amp;/g, '&')
      .replace(/\n\s*\n/g, '\n')
      .trim();

    return await convertTextToPdf(Buffer.from(text, 'utf-8'), 'page.txt');
  } catch (error) {
    return {
      success: false,
      error: `HTML conversion failed: ${error instanceof Error ? error.message : 'Unknown error'}`
    };
  }
}

// Convert JSON/XML data files to PDF
async function convertDataFileToPdf(buffer: Buffer, extension: string): Promise<ConversionResult> {
  try {
    let text = buffer.toString('utf-8');

    // Pretty print JSON
    if (extension === 'json') {
      try {
        const parsed = JSON.parse(text);
        text = JSON.stringify(parsed, null, 2);
      } catch {
        // Keep original if not valid JSON
      }
    }

    return await convertTextToPdf(Buffer.from(text, 'utf-8'), `data.${extension}`);
  } catch (error) {
    return {
      success: false,
      error: `Data file conversion failed: ${error instanceof Error ? error.message : 'Unknown error'}`
    };
  }
}

// Get file extension from filename
export function getFileExtension(filename: string): string {
  return filename.split('.').pop()?.toLowerCase() || '';
}

// Validate file size
export function validateFileSize(sizeBytes: number, maxSizeMb: number = 50): boolean {
  return sizeBytes <= maxSizeMb * 1024 * 1024;
}
