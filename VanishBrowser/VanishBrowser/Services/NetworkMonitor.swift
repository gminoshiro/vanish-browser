//
//  NetworkMonitor.swift
//  VanishBrowser
//
//  Created by Claude on 2025/10/12.
//

import Foundation
import Network
import Combine

class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")

    @Published var isConnected = true
    @Published var connectionType: NWInterface.InterfaceType?

    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                self?.connectionType = path.availableInterfaces.first?.type

                if path.status == .satisfied {
                    print("✅ ネットワーク接続: \(path.availableInterfaces.first?.type.description ?? "不明")")
                } else {
                    print("❌ ネットワーク切断")
                }
            }
        }

        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}

extension NWInterface.InterfaceType {
    var description: String {
        switch self {
        case .wifi:
            return "Wi-Fi"
        case .cellular:
            return "モバイルデータ"
        case .wiredEthernet:
            return "有線"
        case .loopback:
            return "ループバック"
        case .other:
            return "その他"
        @unknown default:
            return "不明"
        }
    }
}
