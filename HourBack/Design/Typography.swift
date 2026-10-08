import SwiftUI
import UIKit

enum Typography {
    static let wordmark = Font.custom("TimesNewRomanPSMT", size: 28)
    static let bigNumber = Font.custom("TimesNewRomanPSMT", size: 44)
    static let body = Font.custom("TimesNewRomanPSMT", size: 17)
    static let small = Font.custom("TimesNewRomanPSMT", size: 13)

    static func apply() {
        let body = UIFont(name: "TimesNewRomanPSMT", size: 17) ?? .systemFont(ofSize: 17)
        let large = UIFont(name: "TimesNewRomanPSMT", size: 28) ?? .systemFont(ofSize: 28)
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .systemBackground
        appearance.shadowColor = UIColor.label.withAlphaComponent(0.2)
        let title: [NSAttributedString.Key: Any] = [
            .font: body,
            .foregroundColor: UIColor.label
        ]
        appearance.titleTextAttributes = title
        appearance.largeTitleTextAttributes = [
            .font: large,
            .foregroundColor: UIColor.label
        ]
        let navigationBar = UINavigationBar.appearance()
        navigationBar.standardAppearance = appearance
        navigationBar.scrollEdgeAppearance = appearance
        navigationBar.compactAppearance = appearance
        navigationBar.tintColor = .label

        let item = UIBarButtonItem.appearance()
        item.setTitleTextAttributes(title, for: .normal)
        item.setTitleTextAttributes(title, for: .highlighted)
    }
}
