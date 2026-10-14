import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a global risk score tier.
    final class GlobalRiskScoreTierView {
        var code: String
        var title: String
        var country: String
        var label: String
        var timezoneText: String
        var amount: String
        var statusLabel: String

        init(code: String, title: String, country: String, label: String, timezoneText: String, amount: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.country = country
            self.label = label
            self.timezoneText = timezoneText
            self.amount = amount
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalRiskScoreTierView(_ item: GlobalRiskScoreTier) -> GlobalRiskScoreTierView {
        return GlobalRiskScoreTierView(
            code: item.code,
            title: item.title,
            country: item.country,
            label: item.label,
            timezoneText: Kit.Text.truncate(item.timezone, limit: 40),
            amount: String(format: "%.2f", item.amount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalRiskScoreTierViews(_ items: [GlobalRiskScoreTier]) -> [GlobalRiskScoreTierView] {
        var views: [GlobalRiskScoreTierView] = []
        for item in items {
            views.append(toGlobalRiskScoreTierView(item))
        }
        return views
    }

    static func sumGlobalRiskScoreTierView(_ view: GlobalRiskScoreTierView) throws -> Double {
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return parsedAmount
    }
}
