//
//  Conversion.swift
//  FileToPDF
//
//  Data models for file conversions
//

import Foundation

// MARK: - Conversion Model
struct Conversion: Identifiable, Codable {
    let id: String
    let originalFilename: String
    let originalFormat: String
    let originalSizeBytes: Int64
    let pdfUrl: String?
    let pdfSizeBytes: Int64?
    let pageCount: Int?
    let status: ConversionStatus
    let errorMessage: String?
    let createdAt: Date
    let completedAt: Date?
    let expiresAt: Date?

    var formattedOriginalSize: String {
        ByteCountFormatter.string(fromByteCount: originalSizeBytes, countStyle: .file)
    }

    var formattedPdfSize: String? {
        guard let size = pdfSizeBytes else { return nil }
        return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }

    var isExpired: Bool {
        guard let expiresAt = expiresAt else { return false }
        return expiresAt < Date()
    }

    var daysUntilExpiration: Int? {
        guard let expiresAt = expiresAt else { return nil }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: expiresAt)
        return components.day
    }
}

// MARK: - Conversion Status
enum ConversionStatus: String, Codable {
    case pending
    case processing
    case completed
    case failed

    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .processing: return "Processing"
        case .completed: return "Completed"
        case .failed: return "Failed"
        }
    }

    var iconName: String {
        switch self {
        case .pending: return "clock"
        case .processing: return "arrow.triangle.2.circlepath"
        case .completed: return "checkmark.circle.fill"
        case .failed: return "xmark.circle.fill"
        }
    }
}

// MARK: - API Response Models
struct ConvertResponse: Codable {
    let success: Bool
    let conversion: Conversion?
    let error: String?
    let message: String?
}

struct HistoryResponse: Codable {
    let success: Bool
    let conversions: [Conversion]
    let total: Int
}

struct FormatsResponse: Codable {
    let success: Bool
    let formats: [String: [FormatInfo]]
    let allExtensions: [String]
}

struct FormatInfo: Codable {
    let extension_: String
    let mimeType: String
    let maxSizeMb: Int

    enum CodingKeys: String, CodingKey {
        case extension_ = "extension"
        case mimeType
        case maxSizeMb
    }
}

struct HealthResponse: Codable {
    let status: String
    let timestamp: String
    let version: String
}

// MARK: - File Selection Model
struct SelectedFile {
    let url: URL
    let filename: String
    let fileExtension: String
    let mimeType: String
    let data: Data
    let sizeBytes: Int64

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: sizeBytes, countStyle: .file)
    }

    var isSupported: Bool {
        Config.supportedExtensions.contains(fileExtension.lowercased())
    }

    var isTooLarge: Bool {
        sizeBytes > Config.maxFileSizeBytes
    }
}
