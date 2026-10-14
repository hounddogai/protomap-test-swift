import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a remittance profile.
    final class RemittanceProfileView {
        var code: String
        var nameText: String
        var updatedAt: String
        var amount: String
        var summary: String
        var timezone: String
        var statusLabel: String

        init(code: String, nameText: String, updatedAt: String, amount: String, summary: String, timezone: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.updatedAt = updatedAt
            self.amount = amount
            self.summary = summary
            self.timezone = timezone
            self.statusLabel = statusLabel
        }
    }

    static func toRemittanceProfileView(_ item: RemittanceProfile) -> RemittanceProfileView {
        return RemittanceProfileView(
            code: item.code,
            nameText: item.name,
            updatedAt: String(item.updatedAt),
            amount: String(format: "%.2f", item.amount),
            summary: Kit.Text.truncate(item.summary, limit: 40),
            timezone: item.timezone,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRemittanceProfileViews(_ items: [RemittanceProfile]) -> [RemittanceProfileView] {
        var views: [RemittanceProfileView] = []
        for item in items {
            views.append(toRemittanceProfileView(item))
        }
        return views
    }

    static func sumRemittanceProfileView(_ view: RemittanceProfileView) throws -> Double {
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return Double(parsedUpdatedAt) + parsedAmount
    }
}
