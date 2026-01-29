//
//  ConversionViewModel.swift
//  FileToPDF
//
//  ViewModel for handling file conversion logic
//

import Foundation
import SwiftUI

@MainActor
class ConversionViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var selectedFile: SelectedFile?
    @Published var currentConversion: Conversion?
    @Published var conversionHistory: [Conversion] = []
    @Published var isConverting = false
    @Published var isLoadingHistory = false
    @Published var progress: ConversionProgress = .idle
    @Published var errorMessage: String?
    @Published var showError = false

    // MARK: - Services

    private let apiService = APIService.shared
    private let fileService = FileService.shared

    // MARK: - Conversion Progress

    enum ConversionProgress: Equatable {
        case idle
        case selecting
        case uploading
        case converting
        case completed(Conversion)
        case failed(String)

        var displayMessage: String {
            switch self {
            case .idle:
                return "Select a file to convert"
            case .selecting:
                return "Loading file..."
            case .uploading:
                return "Uploading file..."
            case .converting:
                return "Converting to PDF..."
            case .completed:
                return "Conversion complete!"
            case .failed(let error):
                return "Failed: \(error)"
            }
        }

        var isProcessing: Bool {
            switch self {
            case .selecting, .uploading, .converting:
                return true
            default:
                return false
            }
        }
    }

    // MARK: - File Selection

    func selectFile(from url: URL) {
        progress = .selecting

        do {
            let file = try fileService.loadFile(from: url)

            // Validate file
            let validation = fileService.validateFile(file)
            if !validation.isValid {
                showError(validation.errorMessage ?? "Invalid file")
                progress = .idle
                return
            }

            selectedFile = file
            progress = .idle
        } catch {
            showError(error.localizedDescription)
            progress = .idle
        }
    }

    func clearSelection() {
        selectedFile = nil
        currentConversion = nil
        progress = .idle
    }

    // MARK: - Convert File

    func convertSelectedFile() async {
        guard let file = selectedFile else {
            showError("No file selected")
            return
        }

        isConverting = true
        progress = .uploading

        do {
            progress = .converting
            let conversion = try await apiService.convertFile(file)

            currentConversion = conversion
            progress = .completed(conversion)

            // Add to history
            conversionHistory.insert(conversion, at: 0)

            // Clear selection after short delay
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            selectedFile = nil
        } catch {
            let errorMsg = error.localizedDescription
            progress = .failed(errorMsg)
            showError(errorMsg)
        }

        isConverting = false
    }

    // MARK: - History

    func loadHistory() async {
        isLoadingHistory = true

        do {
            conversionHistory = try await apiService.getHistory()
        } catch {
            showError("Failed to load history: \(error.localizedDescription)")
        }

        isLoadingHistory = false
    }

    func refreshHistory() async {
        await loadHistory()
    }

    // MARK: - Download PDF

    func downloadPDF(from conversion: Conversion) async -> Data? {
        guard let urlString = conversion.pdfUrl else {
            showError("No PDF URL available")
            return nil
        }

        do {
            return try await apiService.downloadPDF(from: urlString)
        } catch {
            showError("Failed to download PDF: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Error Handling

    func showError(_ message: String) {
        errorMessage = message
        showError = true
    }

    func clearError() {
        errorMessage = nil
        showError = false
    }
}
