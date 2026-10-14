import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a tiered priority target.
    final class TieredPriorityTargetView {
        var code: String
        var name: String
        var descriptionText: String
        var amountText: String
        var endsAt: String
        var statusLabel: String

        init(code: String, name: String, descriptionText: String, amountText: String, endsAt: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.descriptionText = descriptionText
            self.amountText = amountText
            self.endsAt = endsAt
            self.statusLabel = statusLabel
        }
    }

    static func toTieredPriorityTargetView(_ item: TieredPriorityTarget) -> TieredPriorityTargetView {
        return TieredPriorityTargetView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 40),
            descriptionText: item.description,
            amountText: String(format: "%.2f", item.amount),
            endsAt: String(item.endsAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredPriorityTargetViews(_ items: [TieredPriorityTarget]) -> [TieredPriorityTargetView] {
        var views: [TieredPriorityTargetView] = []
        for item in items {
            views.append(toTieredPriorityTargetView(item))
        }
        return views
    }

    static func sumTieredPriorityTargetView(_ view: TieredPriorityTargetView) throws -> Double {
        guard let parsedAmount = Double(view.amountText) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        return parsedAmount + Double(parsedEndsAt)
    }
}
