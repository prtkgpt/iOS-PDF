//
//  HistoryView.swift
//  FileToPDF
//
//  View for displaying conversion history
//

import SwiftUI

struct HistoryView: View {
    @ObservedObject var viewModel: ConversionViewModel
    @State private var showShareSheet = false
    @State private var pdfDataToShare: Data?
    @State private var selectedConversion: Conversion?

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoadingHistory {
                    loadingView
                } else if viewModel.conversionHistory.isEmpty {
                    emptyStateView
                } else {
                    historyList
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await viewModel.refreshHistory()
            }
            .task {
                if viewModel.conversionHistory.isEmpty {
                    await viewModel.loadHistory()
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let data = pdfDataToShare {
                    ShareSheet(items: [data])
                }
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading history...")
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("No Conversions Yet")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Your converted PDFs will appear here")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - History List

    private var historyList: some View {
        List {
            ForEach(groupedConversions.keys.sorted().reversed(), id: \.self) { date in
                Section {
                    ForEach(groupedConversions[date] ?? []) { conversion in
                        ConversionRow(conversion: conversion) {
                            Task {
                                await downloadAndShare(conversion)
                            }
                        }
                    }
                } header: {
                    Text(formatSectionDate(date))
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Grouped Conversions

    private var groupedConversions: [Date: [Conversion]] {
        let calendar = Calendar.current
        return Dictionary(grouping: viewModel.conversionHistory) { conversion in
            calendar.startOfDay(for: conversion.createdAt)
        }
    }

    // MARK: - Helper Functions

    private func formatSectionDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
    }

    private func downloadAndShare(_ conversion: Conversion) async {
        if let data = await viewModel.downloadPDF(from: conversion) {
            pdfDataToShare = data
            selectedConversion = conversion
            showShareSheet = true
        }
    }
}

// MARK: - Conversion Row

struct ConversionRow: View {
    let conversion: Conversion
    let onShare: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Status icon
            statusIcon
                .frame(width: 44, height: 44)
                .background(statusColor.opacity(0.1))
                .cornerRadius(10)

            // File info
            VStack(alignment: .leading, spacing: 4) {
                Text(conversion.originalFilename)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Text(conversion.originalFormat.uppercased())
                        .font(.caption2)
                        .fontWeight(.medium)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .foregroundStyle(.blue)
                        .cornerRadius(4)

                    Text(conversion.formattedOriginalSize)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let pdfSize = conversion.formattedPdfSize {
                        Text("→ \(pdfSize)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // Expiration warning
                if let days = conversion.daysUntilExpiration, days <= 2 {
                    Text(days == 0 ? "Expires today" : "Expires in \(days) day\(days == 1 ? "" : "s")")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
            }

            Spacer()

            // Action button
            if conversion.status == .completed && conversion.pdfUrl != nil {
                Button(action: onShare) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.title3)
                        .foregroundStyle(.blue)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var statusIcon: some View {
        Image(systemName: conversion.status.iconName)
            .font(.title2)
            .foregroundStyle(statusColor)
    }

    private var statusColor: Color {
        switch conversion.status {
        case .pending:
            return .gray
        case .processing:
            return .blue
        case .completed:
            return .green
        case .failed:
            return .red
        }
    }
}

#Preview {
    HistoryView(viewModel: ConversionViewModel())
}
