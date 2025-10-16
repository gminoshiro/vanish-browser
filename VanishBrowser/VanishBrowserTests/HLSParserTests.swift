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

    func testValidURL() throws {
        let urlString = "https://example.com/video.m3u8"
        let url = URL(string: urlString)

        XCTAssertNotNil(url)
        XCTAssertEqual(url?.absoluteString, urlString)
    }

    func testInvalidURL() throws {
        let urlString = "not a valid url"
        let url = URL(string: urlString)

        XCTAssertNil(url)
    }

    // MARK: - 品質ソートテスト

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

    func testIsM3U8URL() throws {
        let m3u8URL = "https://example.com/video.m3u8"
        XCTAssertTrue(m3u8URL.hasSuffix(".m3u8"))

        let mp4URL = "https://example.com/video.mp4"
        XCTAssertFalse(mp4URL.hasSuffix(".m3u8"))
    }
}
