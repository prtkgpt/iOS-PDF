//
//  APIService.swift
//  FileToPDF
//
//  Network service for communicating with the Vercel API
//

import Foundation

class APIService {
    static let shared = APIService()

    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 120 // 2 minutes for large files
        config.timeoutIntervalForResource = 300 // 5 minutes total
        self.session = URLSession(configuration: config)

        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601

        self.encoder = JSONEncoder()
    }

    // MARK: - Device ID

    private var deviceId: String {
        if let id = UserDefaults.standard.string(forKey: "deviceId") {
            return id
        }
        let newId = UUID().uuidString
        UserDefaults.standard.set(newId, forKey: "deviceId")
        return newId
    }

    // MARK: - Convert File to PDF

    func convertFile(_ file: SelectedFile) async throws -> Conversion {
        var request = URLRequest(url: Config.convertURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(deviceId, forHTTPHeaderField: "X-Device-ID")

        let body: [String: Any] = [
            "filename": file.filename,
            "fileData": file.data.base64EncodedString(),
            "mimeType": file.mimeType
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        if httpResponse.statusCode != 200 {
            if let errorResponse = try? decoder.decode(ErrorResponse.self, from: data) {
                throw APIError.serverError(errorResponse.error, errorResponse.message)
            }
            throw APIError.httpError(httpResponse.statusCode)
        }

        let convertResponse = try decoder.decode(ConvertResponse.self, from: data)

        guard convertResponse.success, let conversion = convertResponse.conversion else {
            throw APIError.serverError(convertResponse.error ?? "Unknown error", convertResponse.message)
        }

        return conversion
    }

    // MARK: - Get Conversion History

    func getHistory(limit: Int = 50) async throws -> [Conversion] {
        var components = URLComponents(url: Config.historyURL, resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "limit", value: String(limit))]

        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        request.setValue(deviceId, forHTTPHeaderField: "X-Device-ID")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        if httpResponse.statusCode != 200 {
            throw APIError.httpError(httpResponse.statusCode)
        }

        let historyResponse = try decoder.decode(HistoryResponse.self, from: data)
        return historyResponse.conversions
    }

    // MARK: - Get Single Conversion

    func getConversion(id: String) async throws -> Conversion {
        var components = URLComponents(url: Config.historyURL, resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "id", value: id)]

        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        request.setValue(deviceId, forHTTPHeaderField: "X-Device-ID")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        if httpResponse.statusCode != 200 {
            throw APIError.httpError(httpResponse.statusCode)
        }

        struct SingleConversionResponse: Codable {
            let success: Bool
            let conversion: Conversion
        }

        let conversionResponse = try decoder.decode(SingleConversionResponse.self, from: data)
        return conversionResponse.conversion
    }

    // MARK: - Get Supported Formats

    func getSupportedFormats() async throws -> FormatsResponse {
        var request = URLRequest(url: Config.formatsURL)
        request.httpMethod = "GET"

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        if httpResponse.statusCode != 200 {
            throw APIError.httpError(httpResponse.statusCode)
        }

        return try decoder.decode(FormatsResponse.self, from: data)
    }

    // MARK: - Health Check

    func healthCheck() async throws -> Bool {
        var request = URLRequest(url: Config.healthURL)
        request.httpMethod = "GET"

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            return false
        }

        if httpResponse.statusCode != 200 {
            return false
        }

        let healthResponse = try decoder.decode(HealthResponse.self, from: data)
        return healthResponse.status == "healthy"
    }

    // MARK: - Download PDF

    func downloadPDF(from urlString: String) async throws -> Data {
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.downloadFailed
        }

        return data
    }
}

// MARK: - Error Types

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case serverError(String, String?)
    case downloadFailed

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .serverError(let error, let message):
            return message ?? error
        case .downloadFailed:
            return "Failed to download PDF"
        }
    }
}

struct ErrorResponse: Codable {
    let error: String
    let message: String?
}
