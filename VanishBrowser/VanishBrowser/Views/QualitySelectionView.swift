//
//  QualitySelectionView.swift
//  VanishBrowser
//
//  HLS動画の品質選択ダイアログ
//

import SwiftUI

struct QualitySelectionView: View {
    let qualities: [HLSQuality]
    let fileName: String
    let onSelect: (HLSQuality) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List {
                ForEach(qualities) { quality in
                    Button(action: {
                        onSelect(quality)
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
            .navigationTitle("ダウンロードの品質を選択")
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
