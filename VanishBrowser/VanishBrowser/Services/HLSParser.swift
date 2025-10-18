//
//  HLSParser.swift
//  VanishBrowser
//
//  HLS (m3u8) プレイリストのパース＆品質選択機能
//

import Foundation

struct HLSQuality: Identifiable {
    let id = UUID()
    let resolution: String      // "1080p", "720p", etc.
    let bandwidth: Int          // ビットレート
    let url: URL                // 実際の.m3u8 URL
    let width: Int?
    let height: Int?

    var displayName: String {
        if let height = height {
            return "\(height)p"
        }
        return resolution
    }
}

class HLSParser {

    /// マスタープレイリストから品質リストを取得
    static func parseQualities(from url: URL) async throws -> [HLSQuality] {
        print("📡 HLS品質を取得中: \(url.absoluteString)")

        let (data, _) = try await URLSession.shared.data(from: url)
        guard let content = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "HLSParser", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid m3u8 encoding"])
        }

        print("📄 HLSコンテンツ取得成功")
        return try parseM3U8Content(content, baseURL: url)
    }

    /// m3u8コンテンツをパースして品質リストを取得
    private static func parseM3U8Content(_ content: String, baseURL: URL) throws -> [HLSQuality] {
        var qualities: [HLSQuality] = []
        let lines = content.components(separatedBy: .newlines)

        var currentBandwidth: Int?
        var currentResolution: String?
        var currentWidth: Int?
        var currentHeight: Int?

        for i in 0..<lines.count {
            let line = lines[i].trimmingCharacters(in: .whitespaces)

            // #EXT-X-STREAM-INF: で始まる行を解析
            if line.hasPrefix("#EXT-X-STREAM-INF:") {
                // BANDWIDTH を取得
                if let bandwidthRange = line.range(of: "BANDWIDTH=(\\d+)", options: .regularExpression) {
                    let bandwidthStr = String(line[bandwidthRange]).replacingOccurrences(of: "BANDWIDTH=", with: "")
                    currentBandwidth = Int(bandwidthStr)
                }

                // RESOLUTION を取得
                if let resolutionRange = line.range(of: "RESOLUTION=(\\d+)x(\\d+)", options: .regularExpression) {
                    let resolutionStr = String(line[resolutionRange])
                    let components = resolutionStr.replacingOccurrences(of: "RESOLUTION=", with: "").components(separatedBy: "x")
                    if components.count == 2 {
                        currentWidth = Int(components[0])
                        currentHeight = Int(components[1])
                        currentResolution = "\(currentHeight ?? 0)p"
                    }
                }

                // 次の行がURL
                if i + 1 < lines.count {
                    let urlLine = lines[i + 1].trimmingCharacters(in: .whitespaces)
                    if !urlLine.isEmpty && !urlLine.hasPrefix("#") {
                        if let variantURL = resolveURL(urlLine, relativeTo: baseURL),
                           let bandwidth = currentBandwidth {

                            let quality = HLSQuality(
                                resolution: currentResolution ?? "Unknown",
                                bandwidth: bandwidth,
                                url: variantURL,
                                width: currentWidth,
                                height: currentHeight
                            )
                            qualities.append(quality)
                            print("✅ 品質検出: \(quality.displayName) - \(bandwidth) bps")
                        }

                        // リセット
                        currentBandwidth = nil
                        currentResolution = nil
                        currentWidth = nil
                        currentHeight = nil
                    }
                }
            }
        }

        // 品質が見つからない場合、単一品質として扱う
        if qualities.isEmpty {
            print("⚠️ マスタープレイリストではなく、単一品質として扱います")
            let quality = HLSQuality(
                resolution: "Original",
                bandwidth: 0,
                url: baseURL,
                width: nil,
                height: nil
            )
            qualities.append(quality)
        }

        // 解像度でソート（高画質から低画質へ）
        qualities.sort { ($0.height ?? 0) > ($1.height ?? 0) }

        print("📊 合計 \(qualities.count) 品質を検出")
        return qualities
    }

    /// 相対URLを絶対URLに変換
    private static func resolveURL(_ urlString: String, relativeTo baseURL: URL) -> URL? {
        if urlString.hasPrefix("http://") || urlString.hasPrefix("https://") {
            return URL(string: urlString)
        }

        // 相対パスを解決
        var base = baseURL.deletingLastPathComponent()

        // "../" を処理
        var path = urlString
        while path.hasPrefix("../") {
            path = String(path.dropFirst(3))
            base = base.deletingLastPathComponent()
        }

        return base.appendingPathComponent(path)
    }

    /// セグメントプレイリストをパースしてセグメントURLリストを取得
    static func parseSegments(from url: URL) async throws -> [URL] {
        print("📡 セグメントリストを取得中: \(url.absoluteString)")

        let (data, _) = try await URLSession.shared.data(from: url)
        guard let content = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "HLSParser", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid m3u8 encoding"])
        }

        print("📄 m3u8コンテンツ (最初の500文字):")
        print(String(content.prefix(500)))

        var segments: [URL] = []
        let lines = content.components(separatedBy: .newlines)

        print("📊 合計 \(lines.count) 行を解析中...")

        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)

            // コメント行やメタデータをスキップ
            if trimmedLine.isEmpty || trimmedLine.hasPrefix("#") {
                continue
            }

            // .ts, .m4s, .jpeg, .jpg または任意のセグメントファイルを取得
            // セグメントURLは通常、拡張子を持つか、httpで始まらない相対パス
            let isSegmentFile = trimmedLine.hasSuffix(".ts") ||
                               trimmedLine.hasSuffix(".m4s") ||
                               trimmedLine.hasSuffix(".jpeg") ||
                               trimmedLine.hasSuffix(".jpg") ||
                               trimmedLine.contains(".ts?") ||
                               trimmedLine.contains(".m4s?") ||
                               (!trimmedLine.hasPrefix("http") && !trimmedLine.contains(".m3u8"))

            if isSegmentFile {
                if let segmentURL = resolveURL(trimmedLine, relativeTo: url) {
                    if segments.count < 3 {
                        print("✅ セグメント[\(segments.count)]: \(segmentURL.lastPathComponent)")
                    }
                    segments.append(segmentURL)
                } else {
                    print("⚠️ セグメントURL解決失敗: \(trimmedLine)")
                }
            }
        }

        print("📊 \(segments.count) セグメントを検出")
        return segments
    }

    /// 元のm3u8コンテンツを取得（ローカル保存用）
    static func fetchM3U8Content(from url: URL) async throws -> String {
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let content = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "HLSParser", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid m3u8 encoding"])
        }
        return content
    }
}
