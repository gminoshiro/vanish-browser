//
//  QualitySelectionView.swift
//  VanishBrowser
//
//  HLS動画の品質選択ダイアログ
//

import SwiftUI

enum DownloadFormat {
    case m3u8  // ローカルm3u8プレイリスト形式
    case mp4   // MP4形式（AVAssetExportSession）
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
                // ダウンロード形式選択
                Section(header: Text("ダウンロード形式")) {
                    Picker("形式", selection: $selectedFormat) {
                        Text("MP4形式").tag(DownloadFormat.mp4)
                        Text("m3u8形式").tag(DownloadFormat.m3u8)
                    }
                    .pickerStyle(.segmented)

                    if selectedFormat == .mp4 {
                        Text("動画を1つのMP4ファイルに変換してダウンロードします。多くのアプリで再生可能です。")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("セグメントファイルとm3u8プレイリストをダウンロードします。HLS対応プレーヤーで再生できます。")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

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
            .navigationTitle("ダウンロード設定")
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
