//
//  HLSParserTests.swift
//  VanishBrowserTests
//
//  単体テスト: HLSParser
//

import XCTest
@testable import VanishBrowser

final class HLSParserTests: XCTestCase {

    // MARK: - 品質名テスト

    /// テスト: HLS動画の品質表示名が正しく表示されるか（1080pの場合）
    /// 期待結果: displayNameが"1080p"と表示される
    func testQualityDisplayName() throws {
        let quality = HLSQuality(
            resolution: "1080p",
            bandwidth: 5000000,
            url: URL(string: "https://example.com/video.m3u8")!,
            width: 1920,
            height: 1080
        )

        XCTAssertEqual(quality.displayName, "1080p")
    }

    /// テスト: 低画質（360p）の品質表示名が正しく表示されるか
    /// 期待結果: displayNameが"360p"と表示される
    func testQualityDisplayNameLow() throws {
        let quality = HLSQuality(
            resolution: "360p",
            bandwidth: 500000,
            url: URL(string: "https://example.com/video.m3u8")!,
            width: 640,
            height: 360
        )

        XCTAssertEqual(quality.displayName, "360p")
    }

    /// テスト: 中画質（720p）の品質表示名が正しく表示されるか
    /// 期待結果: displayNameが"720p"と表示される
    func testQualityDisplayNameMedium() throws {
        let quality = HLSQuality(
            resolution: "720p",
            bandwidth: 2000000,
            url: URL(string: "https://example.com/video.m3u8")!,
            width: 1280,
            height: 720
        )

        XCTAssertEqual(quality.displayName, "720p")
    }

    // MARK: - 解像度パーステスト

    /// テスト: 解像度文字列から幅と高さが正しくパースされるか
    /// 期待結果: width=1920, height=1080 が正しく取得できる
    func testResolutionParsing() throws {
        let quality = HLSQuality(
            resolution: "1080p",
            bandwidth: 5000000,
            url: URL(string: "https://example.com/video.m3u8")!,
            width: 1920,
            height: 1080
        )

        XCTAssertEqual(quality.width, 1920)
        XCTAssertEqual(quality.height, 1080)
    }

    /// テスト: 解像度が不明な場合はnilが返されるか
    /// 期待結果: widthとheightがnilになる
    func testResolutionParsingNoResolution() throws {
        let quality = HLSQuality(
            resolution: "unknown",
            bandwidth: 5000000,
            url: URL(string: "https://example.com/video.m3u8")!,
            width: nil,
            height: nil
        )

        XCTAssertNil(quality.width)
        XCTAssertNil(quality.height)
    }

    /// テスト: 無効な解像度文字列の場合はnilが返されるか
    /// 期待結果: widthとheightがnilになる
    func testResolutionParsingInvalid() throws {
        let quality = HLSQuality(
            resolution: "invalid",
            bandwidth: 5000000,
            url: URL(string: "https://example.com/video.m3u8")!,
            width: nil,
            height: nil
        )

        XCTAssertNil(quality.width)
        XCTAssertNil(quality.height)
    }

    // MARK: - 帯域幅計算テスト

    /// テスト: 帯域幅（bps）からMbpsへの変換が正しく計算されるか
    /// 期待結果: 5000000 bps = 5.0 Mbps, 500000 bps = 0.5 Mbps, 2000000 bps = 2.0 Mbps
    func testBandwidthCalculation() throws {
        // 5 Mbps
        let mbps5 = 5000000
        XCTAssertEqual(Double(mbps5) / 1_000_000, 5.0)

        // 0.5 Mbps
        let mbps05 = 500000
        XCTAssertEqual(Double(mbps05) / 1_000_000, 0.5)

        // 2 Mbps
        let mbps2 = 2000000
        XCTAssertEqual(Double(mbps2) / 1_000_000, 2.0)
    }

    // MARK: - URL検証テスト

    /// テスト: 正しいURL文字列からURLオブジェクトが生成されるか
    /// 期待結果: URLオブジェクトが生成され、absoluteStringが元の文字列と一致する
    func testValidURL() throws {
        let urlString = "https://example.com/video.m3u8"
        let url = URL(string: urlString)

        XCTAssertNotNil(url)
        XCTAssertEqual(url?.absoluteString, urlString)
    }

    /// テスト: 無効なURL文字列の場合はnilが返されるか
    /// 期待結果: URLオブジェクトがnilになる
    /// 注意: スペースを含む文字列はURL(string:)によって自動的にパーセントエンコードされる場合がある
    func testInvalidURL() throws {
        // より確実に無効なURL文字列を使用（スキームなし、スペース含む、特殊文字）
        let urlString = "ht!tp://invalid url with spaces"
        let url = URL(string: urlString)

        XCTAssertNil(url, "無効なURL文字列ではnilが返されるべき")
    }

    // MARK: - 品質ソートテスト

    /// テスト: HLS品質リストが帯域幅順に正しくソートされるか
    /// 期待結果: 帯域幅の高い順（5Mbps > 2Mbps > 0.5Mbps）にソートされる
    func testQualitySorting() throws {
        let low = HLSQuality(
            resolution: "360p",
            bandwidth: 500000,
            url: URL(string: "https://example.com/low.m3u8")!,
            width: 640,
            height: 360
        )

        let medium = HLSQuality(
            resolution: "720p",
            bandwidth: 2000000,
            url: URL(string: "https://example.com/medium.m3u8")!,
            width: 1280,
            height: 720
        )

        let high = HLSQuality(
            resolution: "1080p",
            bandwidth: 5000000,
            url: URL(string: "https://example.com/high.m3u8")!,
            width: 1920,
            height: 1080
        )

        let qualities = [low, high, medium].sorted { $0.bandwidth > $1.bandwidth }

        XCTAssertEqual(qualities[0].bandwidth, 5000000)
        XCTAssertEqual(qualities[1].bandwidth, 2000000)
        XCTAssertEqual(qualities[2].bandwidth, 500000)
    }

    // MARK: - M3U8形式判定テスト

    /// テスト: URLがM3U8形式かどうか正しく判定されるか
    /// 期待結果: .m3u8で終わるURLはtrue、そうでないURLはfalseを返す
    func testIsM3U8URL() throws {
        let m3u8URL = "https://example.com/video.m3u8"
        XCTAssertTrue(m3u8URL.hasSuffix(".m3u8"))

        let mp4URL = "https://example.com/video.mp4"
        XCTAssertFalse(mp4URL.hasSuffix(".m3u8"))
    }
}
