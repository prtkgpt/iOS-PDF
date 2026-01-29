//
//  FileService.swift
//  FileToPDF
//
//  Service for handling file operations
//

import Foundation
import UniformTypeIdentifiers

class FileService {
    static let shared = FileService()

    private init() {}

    // MARK: - Load File from URL

    func loadFile(from url: URL) throws -> SelectedFile {
        // Start accessing security-scoped resource
        guard url.startAccessingSecurityScopedResource() else {
            throw FileError.accessDenied
        }

        defer {
            url.stopAccessingSecurityScopedResource()
        }

        // Read file data
        let data = try Data(contentsOf: url)

        // Get file attributes
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        let fileSize = attributes[.size] as? Int64 ?? Int64(data.count)

        // Get filename and extension
        let filename = url.lastPathComponent
        let fileExtension = url.pathExtension.lowercased()

        // Determine MIME type
        let mimeType = getMimeType(for: fileExtension)

        return SelectedFile(
            url: url,
            filename: filename,
            fileExtension: fileExtension,
            mimeType: mimeType,
            data: data,
            sizeBytes: fileSize
        )
    }

    // MARK: - Save PDF to Documents

    func savePDF(data: Data, filename: String) throws -> URL {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let pdfURL = documentsURL.appendingPathComponent("\(filename).pdf")

        try data.write(to: pdfURL)
        return pdfURL
    }

    // MARK: - Get Temporary URL for Sharing

    func getTemporaryURL(for data: Data, filename: String) throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let pdfURL = tempDir.appendingPathComponent("\(filename).pdf")

        try data.write(to: pdfURL)
        return pdfURL
    }

    // MARK: - MIME Type Mapping

    func getMimeType(for extension_: String) -> String {
        let mimeTypes: [String: String] = [
            // Documents
            "txt": "text/plain",
            "rtf": "application/rtf",
            "doc": "application/msword",
            "docx": "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
            "odt": "application/vnd.oasis.opendocument.text",
            "md": "text/markdown",

            // Images
            "jpg": "image/jpeg",
            "jpeg": "image/jpeg",
            "png": "image/png",
            "gif": "image/gif",
            "heic": "image/heic",
            "webp": "image/webp",
            "bmp": "image/bmp",
            "tiff": "image/tiff",

            // Spreadsheets
            "csv": "text/csv",
            "xls": "application/vnd.ms-excel",
            "xlsx": "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",

            // Presentations
            "ppt": "application/vnd.ms-powerpoint",
            "pptx": "application/vnd.openxmlformats-officedocument.presentationml.presentation",

            // Web
            "html": "text/html",
            "htm": "text/html",

            // Data
            "json": "application/json",
            "xml": "application/xml"
        ]

        return mimeTypes[extension_.lowercased()] ?? "application/octet-stream"
    }

    // MARK: - Supported UTTypes

    func getSupportedUTTypes() -> [UTType] {
        var types: [UTType] = []

        // Common types
        if let type = UTType("public.content") { types.append(type) }
        if let type = UTType.plainText as UTType? { types.append(type) }
        if let type = UTType.rtf as UTType? { types.append(type) }
        if let type = UTType.image as UTType? { types.append(type) }
        if let type = UTType.jpeg as UTType? { types.append(type) }
        if let type = UTType.png as UTType? { types.append(type) }
        if let type = UTType.heic as UTType? { types.append(type) }
        if let type = UTType.gif as UTType? { types.append(type) }
        if let type = UTType.html as UTType? { types.append(type) }
        if let type = UTType.json as UTType? { types.append(type) }
        if let type = UTType.xml as UTType? { types.append(type) }

        // Microsoft Office types
        if let type = UTType("com.microsoft.word.doc") { types.append(type) }
        if let type = UTType("org.openxmlformats.wordprocessingml.document") { types.append(type) }
        if let type = UTType("com.microsoft.excel.xls") { types.append(type) }
        if let type = UTType("org.openxmlformats.spreadsheetml.sheet") { types.append(type) }
        if let type = UTType("com.microsoft.powerpoint.ppt") { types.append(type) }
        if let type = UTType("org.openxmlformats.presentationml.presentation") { types.append(type) }

        // CSV
        if let type = UTType.commaSeparatedText as UTType? { types.append(type) }

        return types
    }

    // MARK: - Validate File

    func validateFile(_ file: SelectedFile) -> FileValidationResult {
        if file.isTooLarge {
            return .invalid("File is too large. Maximum size is \(Config.maxFileSizeMB)MB")
        }

        if !file.isSupported {
            return .invalid("File format '\(file.fileExtension)' is not supported")
        }

        return .valid
    }
}

// MARK: - Error Types

enum FileError: LocalizedError {
    case accessDenied
    case readFailed
    case writeFailed
    case unsupportedFormat(String)

    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "Unable to access the file. Please try again."
        case .readFailed:
            return "Failed to read the file."
        case .writeFailed:
            return "Failed to save the file."
        case .unsupportedFormat(let format):
            return "The file format '\(format)' is not supported."
        }
    }
}

enum FileValidationResult {
    case valid
    case invalid(String)

    var isValid: Bool {
        if case .valid = self { return true }
        return false
    }

    var errorMessage: String? {
        if case .invalid(let message) = self { return message }
        return nil
    }
}
