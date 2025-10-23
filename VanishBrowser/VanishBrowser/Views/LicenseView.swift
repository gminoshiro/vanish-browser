//
//  LicenseView.swift
//  VanishBrowser
//
//  Created by 簑城玄太 on 2025/10/22.
//

import SwiftUI

struct LicenseView: View {
    var body: some View {
        List {
            Section {
                NavigationLink(destination: FFmpegLicenseDetailView()) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("FFmpeg")
                            .font(.headline)

                        Text("このアプリはFFmpegを使用しています。")
                            .font(.body)

                        Text("FFmpegはLGPL v2.1ライセンスの下で配布されています。")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("オープンソースライセンス")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct FFmpegLicenseDetailView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Group {
                    Text("FFmpeg")
                        .font(.title2)
                        .bold()

                    Text("このアプリはFFmpegを使用しています。")
                        .font(.body)
                }

                Divider()

                Group {
                    Text("ライセンス")
                        .font(.headline)

                    Text("LGPL v2.1 (GNU Lesser General Public License version 2.1)")
                        .font(.body)

                    Link("ライセンス全文を見る", destination: URL(string: "https://www.gnu.org/licenses/lgpl-2.1.html")!)
                        .font(.body)
                }

                Divider()

                Group {
                    Text("ソースコード")
                        .font(.headline)

                    Link("FFmpeg公式サイト", destination: URL(string: "https://ffmpeg.org/")!)
                        .font(.body)

                    Link("FFmpegソースコード (GitHub)", destination: URL(string: "https://github.com/FFmpeg/FFmpeg")!)
                        .font(.body)
                }

                Divider()

                Group {
                    Text("著作権")
                        .font(.headline)

                    Text("Copyright (c) 2000-2024 FFmpeg developers")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
        .navigationTitle("FFmpegライセンス")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationView {
        LicenseView()
    }
}
