import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a read override.
    final class ReadOverrideView {
        var code: String
        var label: String
        var facility: String
        var title: String
        var amount: String
        var statusLabel: String

        init(code: String, label: String, facility: String, title: String, amount: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.facility = facility
            self.title = title
            self.amount = amount
            self.statusLabel = statusLabel
        }
    }

    static func toReadOverrideView(_ item: ReadOverride) -> ReadOverrideView {
        return ReadOverrideView(
            code: item.code,
            label: item.label,
            facility: item.facility,
            title: Kit.Text.truncate(item.title, limit: 64),
            amount: String(format: "%.2f", item.amount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toReadOverrideViews(_ items: [ReadOverride]) -> [ReadOverrideView] {
        var views: [ReadOverrideView] = []
        for item in items {
            views.append(toReadOverrideView(item))
        }
        return views
    }

    static func sumReadOverrideView(_ view: ReadOverrideView) throws -> Double {
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return parsedAmount
    }
}
