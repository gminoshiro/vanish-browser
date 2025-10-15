//
//  ErrorPageView.swift
//  VanishBrowser
//
//  Created by Claude on 2025/10/12.
//

import SwiftUI

struct ErrorPageView: View {
    let error: Error
    let url: String
    let onRetry: () -> Void
    let onGoBack: () -> Void

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            // エラーアイコン
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 80))
                .foregroundColor(.orange)

            // エラータイトル
            Text(errorTitle)
                .font(.title2)
                .fontWeight(.bold)

            // エラーメッセージ
            Text(errorMessage)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            // 失敗したURL（省略表示）
            if !url.isEmpty {
                Text(url)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .padding(.horizontal, 40)
            }

            // アクションボタン
            VStack(spacing: 15) {
                Button(action: onRetry) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("再読み込み")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding(.horizontal, 40)

                Button(action: onGoBack) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("戻る")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray5))
                    .foregroundColor(.primary)
                    .cornerRadius(10)
                }
                .padding(.horizontal, 40)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }

    private var errorTitle: String {
        let nsError = error as NSError

        // よくあるエラーコードに対応
        switch nsError.code {
        case NSURLErrorNotConnectedToInternet:
            return "インターネット接続なし"
        case NSURLErrorTimedOut:
            return "接続がタイムアウトしました"
        case NSURLErrorCannotFindHost:
            return "サーバーが見つかりません"
        case NSURLErrorCannotConnectToHost:
            return "サーバーに接続できません"
        case NSURLErrorNetworkConnectionLost:
            return "接続が切断されました"
        case NSURLErrorDNSLookupFailed:
            return "DNS解決に失敗しました"
        case NSURLErrorBadServerResponse:
            return "サーバーエラー"
        case NSURLErrorUserCancelledAuthentication:
            return "認証がキャンセルされました"
        case NSURLErrorSecureConnectionFailed:
            return "安全な接続に失敗しました"
        default:
            return "ページを読み込めません"
        }
    }

    private var errorMessage: String {
        let nsError = error as NSError

        switch nsError.code {
        case NSURLErrorNotConnectedToInternet:
            return "Wi-Fiまたはモバイルデータ接続を確認してください"
        case NSURLErrorTimedOut:
            return "サーバーの応答に時間がかかりすぎています"
        case NSURLErrorCannotFindHost, NSURLErrorCannotConnectToHost:
            return "URLが正しいか確認してください"
        case NSURLErrorNetworkConnectionLost:
            return "ネットワーク接続が不安定です"
        case NSURLErrorDNSLookupFailed:
            return "ドメイン名を解決できませんでした"
        case NSURLErrorBadServerResponse:
            return "サーバーから無効な応答が返されました"
        case NSURLErrorSecureConnectionFailed:
            return "このサイトへの安全な接続を確立できません"
        default:
            return nsError.localizedDescription
        }
    }
}
