//
//  DownloadDialogView.swift
//  VanishBrowser
//
//  Created by 簑城玄太 on 2025/10/10.
//

import SwiftUI

struct DownloadDialogView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var fileName: String
    @State private var selectedFolder: String = ""
    @State private var showFolderPicker = false
    @State private var isLoadingQualities = false
    @State private var hlsQualities: [HLSQuality] = []
    @State private var showQualitySelection = false

    let videoURL: URL
    let onDownload: (String, String) -> Void  // fileName, folder
    let onHLSDownload: (HLSQuality, DownloadFormat, String, String) -> Void  // quality, format, fileName, folder

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // ファイル名入力
                VStack(alignment: .leading, spacing: 8) {
                    TextField("", text: $fileName)
                        .font(.system(size: 17))
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                }
                .padding()

                // ロケーション選択
                VStack(alignment: .leading, spacing: 8) {
                    Text("ロケーション")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .padding(.horizontal)

                    Button(action: {
                        showFolderPicker = true
                    }) {
                        HStack {
                            Image(systemName: selectedFolder.isEmpty ? "house.fill" : "folder.fill")
                                .foregroundColor(.blue)
                                .font(.system(size: 24))

                            Text(selectedFolder.isEmpty ? "ホーム" : selectedFolder)
                                .foregroundColor(.primary)

                            Spacer()

                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                                .font(.system(size: 14))
                        }
                        .padding()
                        .background(Color(.systemBackground))
                    }
                    .buttonStyle(.plain)
                }
                .padding()

                Spacer()

                // ダウンロードボタン
                Button(action: {
                    handleDownload()
                }) {
                    HStack {
                        if isLoadingQualities {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        }
                        Text(isLoadingQualities ? "品質を確認中..." : "ファイルをダウンロード")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isLoadingQualities ? Color.gray : Color.blue)
                    .cornerRadius(12)
                }
                .disabled(isLoadingQualities)
                .padding()
            }
            .navigationTitle("ファイルをダウンロード")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.gray)
                    }
                }
            }
            .sheet(isPresented: $showFolderPicker) {
                FolderPickerView(selectedFolder: $selectedFolder)
            }
            .sheet(isPresented: $showQualitySelection) {
                QualitySelectionView(
                    qualities: hlsQualities,
                    fileName: fileName,
                    onSelect: { quality, format in
                        onHLSDownload(quality, format, fileName, selectedFolder)
                        dismiss()
                    }
                )
            }
        }
    }

    private func handleDownload() {
        // HLS (.m3u8) の場合は品質選択を表示
        if fileName.contains(".m3u8") || videoURL.absoluteString.contains(".m3u8") {
            Task {
                isLoadingQualities = true
                do {
                    hlsQualities = try await HLSParser.parseQualities(from: videoURL)
                    isLoadingQualities = false
                    showQualitySelection = true
                } catch {
                    print("❌ HLS品質取得エラー: \(error)")
                    isLoadingQualities = false
                    // エラーの場合は通常ダウンロード
                    onDownload(fileName, selectedFolder)
                    dismiss()
                }
            }
        } else {
            // 通常のファイルダウンロード
            onDownload(fileName, selectedFolder)
            dismiss()
        }
    }
}

struct FolderPickerView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedFolder: String
    @State private var folders: [String] = []
    @State private var showCreateFolder = false
    @State private var newFolderName = ""

    var body: some View {
        NavigationView {
            List {
                // ホーム選択肢
                Button(action: {
                    selectedFolder = ""
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: "house.fill")
                            .foregroundColor(.blue)
                        Text("ホーム")
                        Spacer()
                        if selectedFolder.isEmpty {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }

                // フォルダ一覧
                ForEach(folders, id: \.self) { folder in
                    Button(action: {
                        selectedFolder = folder
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "folder.fill")
                                .foregroundColor(.blue)
                            Text(folder)
                            Spacer()
                            if selectedFolder == folder {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("フォルダを選択")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showCreateFolder = true
                    }) {
                        Image(systemName: "folder.badge.plus")
                    }
                }
            }
            .onAppear {
                loadFolders()
            }
            .alert("新規フォルダ", isPresented: $showCreateFolder) {
                TextField("フォルダ名", text: $newFolderName)
                Button("キャンセル", role: .cancel) {
                    newFolderName = ""
                }
                Button("作成") {
                    createFolder()
                }
            } message: {
                Text("フォルダ名を入力してください")
            }
        }
    }

    private func loadFolders() {
        folders = DownloadService.shared.getAllFolders()
    }

    private func createFolder() {
        guard !newFolderName.isEmpty else { return }

        if DownloadService.shared.createFolder(name: newFolderName) {
            loadFolders()
            selectedFolder = newFolderName
            newFolderName = ""
        }
    }
}
