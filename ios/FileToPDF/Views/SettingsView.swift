//
//  SettingsView.swift
//  FileToPDF
//
//  Settings and about view
//

import SwiftUI

struct SettingsView: View {
    @State private var showSupportedFormats = false

    var body: some View {
        NavigationStack {
            List {
                // About Section
                Section {
                    HStack(spacing: 16) {
                        Image(systemName: "doc.text.fill.viewfinder")
                            .font(.system(size: 40))
                            .foregroundStyle(.blue.gradient)
                            .frame(width: 60, height: 60)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("FileToPDF")
                                .font(.headline)
                            Text("Version 1.0.0")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("About")
                }

                // Features Section
                Section {
                    FeatureRow(
                        icon: "doc.badge.arrow.up",
                        title: "Convert Any File",
                        description: "Documents, images, spreadsheets & more"
                    )

                    FeatureRow(
                        icon: "icloud.and.arrow.up",
                        title: "Cloud Processing",
                        description: "Fast conversion on powerful servers"
                    )

                    FeatureRow(
                        icon: "clock.arrow.circlepath",
                        title: "7-Day History",
                        description: "Access your converted PDFs for 7 days"
                    )
                } header: {
                    Text("Features")
                }

                // Supported Formats Section
                Section {
                    Button {
                        showSupportedFormats = true
                    } label: {
                        HStack {
                            Image(systemName: "doc.on.doc")
                                .foregroundStyle(.blue)
                            Text("Supported Formats")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .foregroundStyle(.primary)
                } header: {
                    Text("Information")
                }

                // Limits Section
                Section {
                    LimitRow(title: "Max File Size", value: "50 MB")
                    LimitRow(title: "PDF Retention", value: "7 days")
                } header: {
                    Text("Limits")
                } footer: {
                    Text("Converted PDFs are automatically deleted after 7 days to save storage space.")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showSupportedFormats) {
                SupportedFormatsSheet()
            }
        }
    }
}

// MARK: - Feature Row

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Limit Row

struct LimitRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Supported Formats Sheet

struct SupportedFormatsSheet: View {
    @Environment(\.dismiss) private var dismiss

    private let formatCategories: [(String, String, [String])] = [
        ("Documents", "doc.text.fill", ["TXT", "RTF", "DOC", "DOCX", "ODT", "MD"]),
        ("Images", "photo.fill", ["JPG", "JPEG", "PNG", "GIF", "HEIC", "WEBP", "BMP", "TIFF"]),
        ("Spreadsheets", "tablecells.fill", ["CSV", "XLS", "XLSX"]),
        ("Presentations", "rectangle.on.rectangle.fill", ["PPT", "PPTX"]),
        ("Web", "globe", ["HTML", "HTM"]),
        ("Data", "curlybraces", ["JSON", "XML"])
    ]

    var body: some View {
        NavigationStack {
            List {
                ForEach(formatCategories, id: \.0) { category, icon, formats in
                    Section {
                        ForEach(formats, id: \.self) { format in
                            HStack {
                                Text(format)
                                    .font(.system(.body, design: .monospaced))
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            }
                        }
                    } header: {
                        Label(category, systemImage: icon)
                    }
                }
            }
            .navigationTitle("Supported Formats")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}
