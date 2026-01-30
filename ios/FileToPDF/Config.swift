//
//  Config.swift
//  FileToPDF
//
//  Configuration settings for the app
//

import Foundation

enum Config {
    // MARK: - API Configuration

    /// Base URL for the Vercel API
    /// Update this after deploying to Vercel
    static let apiBaseURL = "https://i-os-b9idtctem-prateek-gupta.vercel.app"

    // MARK: - API Endpoints

    static var convertURL: URL {
        URL(string: "\(apiBaseURL)/api/convert")!
    }

    static var historyURL: URL {
        URL(string: "\(apiBaseURL)/api/history")!
    }

    static var formatsURL: URL {
        URL(string: "\(apiBaseURL)/api/formats")!
    }

    static var healthURL: URL {
        URL(string: "\(apiBaseURL)/api/health")!
    }

    // MARK: - File Limits

    /// Maximum file size in bytes (50MB)
    static let maxFileSizeBytes: Int64 = 50 * 1024 * 1024

    /// Maximum file size in MB for display
    static let maxFileSizeMB: Int = 50

    // MARK: - Supported Formats

    static let supportedExtensions: Set<String> = [
        // Documents
        "txt", "rtf", "doc", "docx", "odt", "md",
        // Images
        "jpg", "jpeg", "png", "gif", "heic", "webp", "bmp", "tiff",
        // Spreadsheets
        "csv", "xls", "xlsx",
        // Presentations
        "ppt", "pptx",
        // Web
        "html", "htm",
        // Data
        "json", "xml"
    ]

    static let supportedUTTypes: [String] = [
        "public.plain-text",
        "public.rtf",
        "com.microsoft.word.doc",
        "org.openxmlformats.wordprocessingml.document",
        "public.image",
        "public.jpeg",
        "public.png",
        "public.heic",
        "com.compuserve.gif",
        "public.comma-separated-values-text",
        "com.microsoft.excel.xls",
        "org.openxmlformats.spreadsheetml.sheet",
        "public.html",
        "public.json",
        "public.xml"
    ]

    // MARK: - UI Settings

    /// Time to show success message before dismissing
    static let successMessageDuration: TimeInterval = 2.0

    /// PDF expiration notice (7 days)
    static let pdfExpirationDays: Int = 7
}
