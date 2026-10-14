import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a priority window.
    final class PriorityWindowView {
        var code: String
        var name: String
        var reviewerText: String
        var amount: String
        var localeText: String
        var pinned: String
        var title: String
        var statusLabel: String

        init(code: String, name: String, reviewerText: String, amount: String, localeText: String, pinned: String, title: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.reviewerText = reviewerText
            self.amount = amount
            self.localeText = localeText
            self.pinned = pinned
            self.title = title
            self.statusLabel = statusLabel
        }
    }

    static func toPriorityWindowView(_ item: PriorityWindow) -> PriorityWindowView {
        return PriorityWindowView(
            code: Kit.Text.truncate(item.code, limit: 80),
            name: item.name,
            reviewerText: item.reviewer,
            amount: String(format: "%.2f", item.amount),
            localeText: item.locale,
            pinned: "\(item.pinned)",
            title: item.title,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPriorityWindowViews(_ items: [PriorityWindow]) -> [PriorityWindowView] {
        var views: [PriorityWindowView] = []
        for item in items {
            views.append(toPriorityWindowView(item))
        }
        return views
    }

    static func sumPriorityWindowView(_ view: PriorityWindowView) throws -> Double {
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return parsedAmount
    }
}
