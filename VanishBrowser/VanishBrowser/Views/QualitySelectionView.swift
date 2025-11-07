//
//  QualitySelectionView.swift
//  VanishBrowser
//
//  HLS動画の品質選択ダイアログ
//

import SwiftUI

enum DownloadFormat {
    case mp4   // MP4形式（FFmpeg変換）
}

struct QualitySelectionView: View {
    let qualities: [HLSQuality]
    let fileName: String
    let onSelect: (HLSQuality, DownloadFormat) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selectedFormat: DownloadFormat = .mp4

    var body: some View {
        NavigationView {
            List {
                // 品質選択
                Section(header: Text("品質を選択")) {
                    ForEach(qualities) { quality in
                        Button(action: {
                            onSelect(quality, selectedFormat)
                            dismiss()
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(quality.displayName)
                                        .font(.headline)
                                        .foregroundColor(.primary)

                                    if let width = quality.width, let height = quality.height {
                                        Text("\(width) x \(height)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }

                                    Text("\(formatBitrate(quality.bandwidth))")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                Image(systemName: "arrow.down.circle")
                                    .foregroundColor(.blue)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle(NSLocalizedString("browser.download", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func formatBitrate(_ bandwidth: Int) -> String {
        let mbps = Double(bandwidth) / 1_000_000
        return String(format: "%.1f Mbps", mbps)
    }
}
