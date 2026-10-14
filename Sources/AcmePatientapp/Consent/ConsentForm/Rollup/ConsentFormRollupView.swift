import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a consent form rollup.
    final class ConsentFormRollupView {
        var code: String
        var label: String
        var maximum: String
        var graceDays: String
        var cost: String
        var statusLabel: String

        init(code: String, label: String, maximum: String, graceDays: String, cost: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.maximum = maximum
            self.graceDays = graceDays
            self.cost = cost
            self.statusLabel = statusLabel
        }
    }

    static func toConsentFormRollupView(_ item: ConsentFormRollup) -> ConsentFormRollupView {
        return ConsentFormRollupView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 120),
            maximum: String(format: "%.2f", item.maximum),
            graceDays: String(item.graceDays),
            cost: String(format: "%.2f", item.cost),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toConsentFormRollupViews(_ items: [ConsentFormRollup]) -> [ConsentFormRollupView] {
        var views: [ConsentFormRollupView] = []
        for item in items {
            views.append(toConsentFormRollupView(item))
        }
        return views
    }

    static func sumConsentFormRollupView(_ view: ConsentFormRollupView) throws -> Double {
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        return parsedMaximum + Double(parsedGraceDays) + parsedCost
    }
}
