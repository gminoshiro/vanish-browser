//
//  Tab.swift
//  VanishBrowser
//
//  Created by 簑城玄太 on 2025/10/10.
//

import Foundation
import UIKit

struct Tab: Identifiable, Equatable {
    let id: UUID
    var title: String
    var url: String
    var snapshot: UIImage?

    init(id: UUID = UUID(), title: String = "新規タブ", url: String = "", snapshot: UIImage? = nil) {
        self.id = id
        self.title = title
        self.url = url
        self.snapshot = snapshot
    }

    static func == (lhs: Tab, rhs: Tab) -> Bool {
        return lhs.id == rhs.id &&
               lhs.title == rhs.title &&
               lhs.url == rhs.url
        // snapshotは比較から除外（UIImageはEquatableではない）
    }
}
