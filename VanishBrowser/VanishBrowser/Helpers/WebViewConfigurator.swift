//
//  WebViewConfigurator.swift
//  VanishBrowser
//
//  Created by 簑城玄太 on 2025/10/19.
//

import Foundation
import WebKit

class WebViewConfigurator {
    static func createConfiguration(isPrivate: Bool) -> WKWebViewConfiguration {
        let configuration = WKWebViewConfiguration()

        // プライベートモード設定
        configuration.websiteDataStore = isPrivate ? .nonPersistent() : .default()

        // メディア再生設定
        configuration.allowsInlineMediaPlayback = true
        configuration.allowsPictureInPictureMediaPlayback = false
        configuration.mediaTypesRequiringUserActionForPlayback = .all

        // カスタムURLスキームハンドラを登録（動画インターセプト用）
        let videoHandler = VideoURLSchemeHandler()
        configuration.setURLSchemeHandler(videoHandler, forURLScheme: "vanish-video")

        // JavaScriptで動画検出（再生中の動画URLを通知）
        let mediaDetectionScript = WKUserScript(
            source: """
            (function() {
                console.log('📱 Media detection script loaded');

                function notifyVideoDetected(video) {
                    try {
                        let videoUrl = video.src || video.currentSrc;
                        if (!videoUrl) {
                            const sources = video.querySelectorAll('source');
                            if (sources.length > 0) {
                                videoUrl = sources[0].src;
                            }
                        }

                        if (videoUrl && videoUrl.startsWith('http')) {
                            console.log('🎬 Video detected:', videoUrl);
                            if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.videoDetected) {
                                window.webkit.messageHandlers.videoDetected.postMessage({
                                    url: videoUrl,
                                    fileName: videoUrl.split('/').pop().split('?')[0] || 'video.mp4'
                                });
                                console.log('✅ Message sent successfully');
                            } else {
                                console.error('❌ videoDetected handler not found');
                            }
                        } else {
                            console.log('⚠️ No valid video URL found');
                        }
                    } catch (error) {
                        console.error('❌ Error in notifyVideoDetected:', error);
                    }
                }

                function detectVideos() {
                    const videos = document.querySelectorAll('video');
                    console.log('🔍 Checking for videos... Found:', videos.length);
                    let hasPlayableVideo = false;

                    videos.forEach(function(video) {
                        // ビデオが存在し、URLがあればDLボタンを表示
                        const videoUrl = video.src || video.currentSrc;
                        if (videoUrl && videoUrl.startsWith('http')) {
                            hasPlayableVideo = true;
                        } else {
                            // sourceタグもチェック
                            const sources = video.querySelectorAll('source');
                            if (sources.length > 0) {
                                const sourceUrl = sources[0].src;
                                if (sourceUrl && sourceUrl.startsWith('http')) {
                                    hasPlayableVideo = true;
                                }
                            }
                        }

                        if (video.dataset.vanishDetected) return;
                        video.dataset.vanishDetected = 'true';

                        // 動画クリック時にカスタムプレーヤーを起動
                        function handleVideoClick(e) {
                            e.preventDefault();
                            e.stopPropagation();

                            let videoUrl = video.src || video.currentSrc;
                            if (!videoUrl || !videoUrl.startsWith('http')) {
                                const sources = video.querySelectorAll('source');
                                if (sources.length > 0) {
                                    videoUrl = sources[0].src;
                                }
                            }

                            if (videoUrl && videoUrl.startsWith('http')) {
                                console.log('🎬 Video clicked:', videoUrl);
                                if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.videoClicked) {
                                    window.webkit.messageHandlers.videoClicked.postMessage({
                                        url: videoUrl,
                                        fileName: videoUrl.split('/').pop().split('?')[0] || 'video.mp4'
                                    });
                                }
                            }
                        }

                        // クリック・タッチイベントをインターセプト
                        video.addEventListener('click', handleVideoClick, true);
                        video.addEventListener('touchend', handleVideoClick, true);

                        // ビデオが読み込まれたら即座に通知
                        if (video.readyState >= 2) {
                            notifyVideoDetected(video);
                        }

                        // 再生を防止してカスタムプレーヤーを起動
                        video.addEventListener('play', function(e) {
                            e.preventDefault();
                            video.pause();

                            let videoUrl = video.src || video.currentSrc;
                            if (!videoUrl || !videoUrl.startsWith('http')) {
                                const sources = video.querySelectorAll('source');
                                if (sources.length > 0) {
                                    videoUrl = sources[0].src;
                                }
                            }

                            if (videoUrl && videoUrl.startsWith('http')) {
                                console.log('🎬 Video play intercepted:', videoUrl);
                                if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.videoClicked) {
                                    window.webkit.messageHandlers.videoClicked.postMessage({
                                        url: videoUrl,
                                        fileName: videoUrl.split('/').pop().split('?')[0] || 'video.mp4'
                                    });
                                }
                            }

                            notifyVideoDetected(video);
                        }, true);

                        // loadeddataイベントでも通知
                        video.addEventListener('loadeddata', function() {
                            notifyVideoDetected(video);
                        });

                        // canplayイベントでも通知
                        video.addEventListener('canplay', function() {
                            notifyVideoDetected(video);
                        });

                        // 停止時に通知
                        video.addEventListener('pause', function() {
                            console.log('⏸️ Video paused');
                            // ページに動画がまだある場合はDLボタンを維持
                            setTimeout(detectVideos, 100);
                        });

                        // 終了時に通知
                        video.addEventListener('ended', function() {
                            console.log('⏹️ Video ended');
                            setTimeout(detectVideos, 100);
                        });
                    });

                    // 動画が1つでもあればDLボタンを表示
                    if (hasPlayableVideo) {
                        const firstVideo = videos[0];
                        if (firstVideo) {
                            // 毎回通知して最新の動画URLを更新
                            notifyVideoDetected(firstVideo);
                        }
                    } else if (videos.length === 0) {
                        // 動画がなくなったら停止通知
                        window.webkit.messageHandlers.videoStopped.postMessage({});
                    }
                }

                // 定期的に動画を検出（より頻繁に）
                setInterval(detectVideos, 300);
                detectVideos();

                // DOMContentLoaded後にも実行
                if (document.readyState === 'loading') {
                    document.addEventListener('DOMContentLoaded', detectVideos);
                } else {
                    detectVideos();
                }
            })();
            """,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: false
        )

        // コンテキストメニュー完全ブロックと画像長押し検出スクリプト
        let imageTapScript = WKUserScript(
            source: """
            (function() {
                console.log('📱 Image tap script loaded');

                // CSSでコンテキストメニューを無効化
                var style = document.createElement('style');
                style.innerHTML = `
                    img, video {
                        -webkit-touch-callout: none !important;
                        -webkit-user-select: none !important;
                    }
                `;
                if (document.head) {
                    document.head.appendChild(style);
                } else {
                    document.addEventListener('DOMContentLoaded', function() {
                        document.head.appendChild(style);
                    });
                }

                // コンテキストメニューをブロック
                function blockContextMenu(e) {
                    if (e.target.tagName === 'IMG' || e.target.tagName === 'VIDEO') {
                        e.preventDefault();
                        e.stopPropagation();
                        return false;
                    }
                }

                document.addEventListener('contextmenu', blockContextMenu, true);

                // 長押し検出
                var longPressTimer = null;
                var touchStartX = 0;
                var touchStartY = 0;
                var hasMoved = false;

                function handleTouchStart(e) {
                    // 画像または動画かどうかチェック
                    var target = e.target;
                    if (!target || (target.tagName !== 'IMG' && target.tagName !== 'VIDEO')) {
                        return;
                    }

                    console.log('🖼️ Media touchstart detected:', target.src);

                    touchStartX = e.touches[0].clientX;
                    touchStartY = e.touches[0].clientY;
                    hasMoved = false;

                    // 長押しタイマー開始
                    longPressTimer = setTimeout(function() {
                        if (!hasMoved) {
                            console.log('⏰ Long press triggered for:', target.src);
                            var mediaUrl = target.src || target.currentSrc;

                            // 動画の場合はsourceタグもチェック
                            if (target.tagName === 'VIDEO' && !mediaUrl) {
                                var sources = target.querySelectorAll('source');
                                if (sources.length > 0) {
                                    mediaUrl = sources[0].src;
                                }
                            }

                            if (mediaUrl) {
                                try {
                                    var isVideo = target.tagName === 'VIDEO';
                                    var handler = isVideo ? 'videoDownload' : 'imageLongPress';
                                    var defaultName = isVideo ? 'video.mp4' : 'image.jpg';

                                    window.webkit.messageHandlers[handler].postMessage({
                                        url: mediaUrl,
                                        fileName: mediaUrl.split('/').pop().split('?')[0] || defaultName
                                    });
                                    console.log('✅ Message sent successfully to', handler);
                                } catch (err) {
                                    console.error('❌ Error sending message:', err);
                                }
                            }
                        }
                    }, 600);

                    // 画像のデフォルト動作をブロック
                    e.preventDefault();
                }

                function handleTouchMove(e) {
                    if (!longPressTimer) return;

                    var moveX = Math.abs(e.touches[0].clientX - touchStartX);
                    var moveY = Math.abs(e.touches[0].clientY - touchStartY);

                    // 10px以上動いたらキャンセル
                    if (moveX > 10 || moveY > 10) {
                        hasMoved = true;
                        clearTimeout(longPressTimer);
                        longPressTimer = null;
                        console.log('↔️ Touch moved, cancelled');
                    }
                }

                function handleTouchEnd(e) {
                    if (longPressTimer) {
                        clearTimeout(longPressTimer);
                        longPressTimer = null;
                    }
                }

                // イベントリスナー登録
                document.addEventListener('touchstart', handleTouchStart, true);
                document.addEventListener('touchmove', handleTouchMove, true);
                document.addEventListener('touchend', handleTouchEnd, true);
                document.addEventListener('touchcancel', handleTouchEnd, true);

                console.log('✅ Image long press detection ready');
            })();
            """,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: false
        )

        configuration.userContentController.addUserScript(mediaDetectionScript)
        configuration.userContentController.addUserScript(imageTapScript)

        return configuration
    }
}
