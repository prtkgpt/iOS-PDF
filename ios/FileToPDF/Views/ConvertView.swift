//
//  ConvertView.swift
//  FileToPDF
//
//  Main view for file selection and conversion
//

import SwiftUI
import UniformTypeIdentifiers

struct ConvertView: View {
    @ObservedObject var viewModel: ConversionViewModel
    @State private var showFilePicker = false
    @State private var showShareSheet = false
    @State private var pdfDataToShare: Data?

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Header
                headerSection

                Spacer()

                // Main Content
                if let file = viewModel.selectedFile {
                    selectedFileCard(file: file)
                } else if case .completed(let conversion) = viewModel.progress {
                    completedCard(conversion: conversion)
                } else {
                    uploadPrompt
                }

                Spacer()

                // Action Buttons
                actionButtons
            }
            .padding()
            .navigationTitle("Convert to PDF")
            .navigationBarTitleDisplayMode(.large)
            .fileImporter(
                isPresented: $showFilePicker,
                allowedContentTypes: getAllowedContentTypes(),
                allowsMultipleSelection: false
            ) { result in
                handleFileSelection(result)
            }
            .sheet(isPresented: $showShareSheet) {
                if let data = pdfDataToShare {
                    ShareSheet(items: [data])
                }
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "doc.text.fill.viewfinder")
                .font(.system(size: 50))
                .foregroundStyle(.blue.gradient)

            Text("Any File to PDF")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 20)
    }

    // MARK: - Upload Prompt

    private var uploadPrompt: some View {
        VStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [10]))
                    .foregroundStyle(.blue.opacity(0.5))
                    .frame(height: 200)

                VStack(spacing: 12) {
                    Image(systemName: "arrow.up.doc.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.blue)

                    Text("Select a File")
                        .font(.title3)
                        .fontWeight(.semibold)

                    Text("Supports documents, images,\nspreadsheets, and more")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .onTapGesture {
                showFilePicker = true
            }

            // Supported formats preview
            supportedFormatsPreview
        }
    }

    // MARK: - Supported Formats Preview

    private var supportedFormatsPreview: some View {
        VStack(spacing: 8) {
            Text("Supported Formats")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                FormatBadge(icon: "doc.text", label: "DOC")
                FormatBadge(icon: "photo", label: "IMG")
                FormatBadge(icon: "tablecells", label: "XLS")
                FormatBadge(icon: "globe", label: "HTML")
            }
        }
    }

    // MARK: - Selected File Card

    private func selectedFileCard(file: SelectedFile) -> some View {
        VStack(spacing: 16) {
            // File info card
            HStack(spacing: 16) {
                fileIcon(for: file.fileExtension)
                    .font(.system(size: 40))
                    .foregroundStyle(.blue)
                    .frame(width: 60, height: 60)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)

                VStack(alignment: .leading, spacing: 4) {
                    Text(file.filename)
                        .font(.headline)
                        .lineLimit(2)

                    Text(file.formattedSize)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text(file.fileExtension.uppercased())
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(4)
                }

                Spacer()

                Button {
                    viewModel.clearSelection()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(16)

            // Progress indicator
            if viewModel.progress.isProcessing {
                ProgressView {
                    Text(viewModel.progress.displayMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
        }
    }

    // MARK: - Completed Card

    private func completedCard(conversion: Conversion) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.green)

            Text("Conversion Complete!")
                .font(.title2)
                .fontWeight(.semibold)

            Text(conversion.originalFilename)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if let pageCount = conversion.pageCount {
                Text("\(pageCount) page\(pageCount == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 16) {
                Button {
                    Task {
                        if let data = await viewModel.downloadPDF(from: conversion) {
                            pdfDataToShare = data
                            showShareSheet = true
                        }
                    }
                } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }

                Button {
                    viewModel.clearSelection()
                    viewModel.progress = .idle
                } label: {
                    Label("New", systemImage: "plus")
                        .font(.headline)
                        .foregroundStyle(.blue)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            if viewModel.selectedFile != nil {
                Button {
                    Task {
                        await viewModel.convertSelectedFile()
                    }
                } label: {
                    HStack {
                        if viewModel.isConverting {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "arrow.right.doc.on.clipboard")
                        }
                        Text(viewModel.isConverting ? "Converting..." : "Convert to PDF")
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.isConverting ? Color.gray : Color.blue)
                    .cornerRadius(12)
                }
                .disabled(viewModel.isConverting)
            } else if case .completed = viewModel.progress {
                // Show nothing, handled in completedCard
            } else {
                Button {
                    showFilePicker = true
                } label: {
                    HStack {
                        Image(systemName: "folder.badge.plus")
                        Text("Select File")
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }
            }
        }
    }

    // MARK: - Helper Functions

    private func getAllowedContentTypes() -> [UTType] {
        [
            .plainText,
            .rtf,
            .image,
            .jpeg,
            .png,
            .heic,
            .gif,
            .html,
            .json,
            .xml,
            .commaSeparatedText,
            UTType("com.microsoft.word.doc") ?? .data,
            UTType("org.openxmlformats.wordprocessingml.document") ?? .data,
            UTType("com.microsoft.excel.xls") ?? .data,
            UTType("org.openxmlformats.spreadsheetml.sheet") ?? .data,
            .data
        ]
    }

    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            if let url = urls.first {
                viewModel.selectFile(from: url)
            }
        case .failure(let error):
            viewModel.showError(error.localizedDescription)
        }
    }

    private func fileIcon(for extension_: String) -> Image {
        switch extension_.lowercased() {
        case "jpg", "jpeg", "png", "gif", "heic", "webp", "bmp", "tiff":
            return Image(systemName: "photo.fill")
        case "doc", "docx", "rtf", "txt", "md":
            return Image(systemName: "doc.text.fill")
        case "xls", "xlsx", "csv":
            return Image(systemName: "tablecells.fill")
        case "ppt", "pptx":
            return Image(systemName: "rectangle.on.rectangle.fill")
        case "html", "htm":
            return Image(systemName: "globe")
        case "json", "xml":
            return Image(systemName: "curlybraces")
        default:
            return Image(systemName: "doc.fill")
        }
    }
}

// MARK: - Format Badge

struct FormatBadge: View {
    let icon: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
            Text(label)
                .font(.caption2)
        }
        .foregroundStyle(.blue)
        .frame(width: 60, height: 50)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    ConvertView(viewModel: ConversionViewModel())
}
