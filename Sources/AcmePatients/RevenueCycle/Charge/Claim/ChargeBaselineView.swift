import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a charge baseline.
    final class ChargeBaselineView {
        var code: String
        var name: String
        var versionText: String
        var cost: String
        var allergyText: String
        var attempts: String
        var title: String
        var label: String
        var statusLabel: String

        init(code: String, name: String, versionText: String, cost: String, allergyText: String, attempts: String, title: String, label: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.versionText = versionText
            self.cost = cost
            self.allergyText = allergyText
            self.attempts = attempts
            self.title = title
            self.label = label
            self.statusLabel = statusLabel
        }
    }

    static func toChargeBaselineView(_ item: ChargeBaseline) -> ChargeBaselineView {
        return ChargeBaselineView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 80),
            versionText: String(item.version),
            cost: String(format: "%.2f", item.cost),
            allergyText: item.allergy,
            attempts: String(item.attempts),
            title: item.title,
            label: item.label,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toChargeBaselineViews(_ items: [ChargeBaseline]) -> [ChargeBaselineView] {
        var views: [ChargeBaselineView] = []
        for item in items {
            views.append(toChargeBaselineView(item))
        }
        return views
    }

    static func sumChargeBaselineView(_ view: ChargeBaselineView) throws -> Double {
        guard let parsedVersion = Int(view.versionText) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        return Double(parsedVersion) + parsedCost + Double(parsedAttempts)
    }
}
